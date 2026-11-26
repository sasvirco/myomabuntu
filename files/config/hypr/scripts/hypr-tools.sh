#!/bin/bash
# Plain replacements for the omarchy-* scripts used by Omarchy v3.8.4's key bindings.
# Usage: hypr-tools.sh <action> [args]
set -u

notify() { notify-send -u low "$@"; }
osd() { swayosd-client --custom-message "$1" ${2:+--custom-icon "$2"}; }

internal_monitor() { hyprctl monitors all -j | jq -r '.[] | select(.name | startswith("eDP")) | .name' | head -n1; }
external_connected() {
    for s in /sys/class/drm/card*-*/status; do
        [[ $s == *-eDP-* ]] && continue
        [[ $(<"$s") == connected ]] && return 0
    done
    return 1
}
touchpad_name() { hyprctl devices -j | jq -r '.mice[].name' | grep -i touchpad | head -n1; }
# Set a backlight or LED through systemd-logind: works for the logged-in user without root
# or the video group. Usage: set_brightness backlight|leds <device> <raw value>
set_brightness() { busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
    org.freedesktop.login1.Session SetBrightness ssu "$1" "$2" "$3"; }
kbd_led() { basename "$(ls -d /sys/class/leds/*kbd_backlight* 2>/dev/null | head -n1)" 2>/dev/null; }
OMARCHY_SRC=${OMARCHY_SRC:-$HOME/src/omarchy}
OMARCHY_THEMES=$OMARCHY_SRC/themes
STATE="${XDG_RUNTIME_DIR:-/tmp}/hypr-tools"
mkdir -p "$STATE"

case "${1:-}" in

# --- Windows ---------------------------------------------------------------
pop) # float, resize, centre and pin the active window; again to undo
    a=$(hyprctl activewindow -j); addr=$(jq -r .address <<<"$a")
    [[ -z $addr || $addr == null ]] && exit 0
    if [[ $(jq .pinned <<<"$a") == true ]]; then
        hyprctl -q --batch "dispatch pin address:$addr; dispatch togglefloating address:$addr"
    else
        hyprctl -q --batch "dispatch togglefloating address:$addr; dispatch resizeactive exact 1300 900; dispatch centerwindow; dispatch pin address:$addr; dispatch alterzorder top address:$addr"
    fi ;;
transparency)
    hyprctl dispatch setprop "address:$(hyprctl activewindow -j | jq -r .address)" opaque toggle ;;
gaps-toggle)
    if [[ -f $STATE/no-gaps ]]; then
        rm -f "$STATE/no-gaps"; hyprctl reload >/dev/null
    else
        touch "$STATE/no-gaps"
        hyprctl -q --batch "keyword general:gaps_out 0; keyword general:gaps_in 0; keyword general:border_size 0; keyword decoration:rounding 0"
    fi ;;
aspect-toggle)
    if [[ $(hyprctl getoption dwindle:single_window_aspect_ratio -j | jq -r '.vec2[0]') == 0* ]]; then
        hyprctl keyword dwindle:single_window_aspect_ratio 1 1 >/dev/null; notify "Single-window square aspect on"
    else
        hyprctl keyword dwindle:single_window_aspect_ratio 0 0 >/dev/null; notify "Single-window square aspect off"
    fi ;;
layout-toggle)
    if [[ $(hyprctl getoption general:layout -j | jq -r .str) == dwindle ]]; then new=master; else new=dwindle; fi
    hyprctl keyword general:layout "$new" >/dev/null; notify "Layout set to $new" ;;
close-all)
    hyprctl clients -j | jq -r '.[].address' | xargs -r -I{} hyprctl dispatch closewindow address:{} >/dev/null
    hyprctl dispatch workspace 1 >/dev/null ;;

# --- Displays --------------------------------------------------------------
internal-display) # on | off | toggle
    mon=$(internal_monitor)
    disabled=$(hyprctl monitors all -j | jq -r --arg m "$mon" '.[] | select(.name==$m) | .disabled')
    want=${2:-toggle}
    [[ $want == toggle ]] && { [[ $disabled == true ]] && want=on || want=off; }
    if [[ $want == off ]]; then
        external_connected || { notify "Can't disable the only active display"; exit 1; }
        hyprctl keyword monitor "$mon,disable" >/dev/null; notify "Laptop display disabled"
    elif [[ $disabled == true ]]; then
        hyprctl reload >/dev/null; notify "Laptop display enabled"
    fi ;;
mirror-toggle)
    mon=$(internal_monitor)
    ext=$(hyprctl monitors all -j | jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -n1)
    [[ -z $ext ]] && { notify "No external monitor to mirror to"; exit 1; }
    if [[ -f $STATE/mirror ]]; then
        rm -f "$STATE/mirror"; hyprctl reload >/dev/null; notify "Extended mode restored"
    else
        touch "$STATE/mirror"; hyprctl keyword monitor "$ext,preferred,auto,1,mirror,$mon" >/dev/null; notify "Mirroring to $ext"
    fi ;;
lid) # close | open
    if [[ ${2:-} == close ]]; then external_connected && "$0" internal-display off
    else "$0" internal-display on; fi ;;
scale-cycle) # [--reverse]
    m=$(hyprctl monitors -j | jq -r '.[] | select(.focused)')
    name=$(jq -r .name <<<"$m"); cur=$(jq -r .scale <<<"$m")
    w=$(jq -r .width <<<"$m"); h=$(jq -r .height <<<"$m"); r=$(jq -r .refreshRate <<<"$m")
    scales=(1 1.25 1.5 2)
    idx=$(awk -v s="$cur" -v l="${scales[*]}" 'BEGIN{n=split(l,a," ");b=0;d=1e9;for(i=1;i<=n;i++){x=s-a[i];if(x<0)x=-x;if(x<d){d=x;b=i-1}}print b}')
    if [[ ${2:-} == --reverse ]]; then idx=$(( (idx - 1 + ${#scales[@]}) % ${#scales[@]} )); else idx=$(( (idx + 1) % ${#scales[@]} )); fi
    hyprctl keyword monitor "$name,${w}x${h}@${r},auto,${scales[$idx]}" >/dev/null
    notify "Display scaling ${scales[$idx]}x (until next reload)" ;;

# --- Audio, keyboard, touchpad --------------------------------------------
audio-output-switch)
    mapfile -t sinks < <(wpctl status | sed -n '/^Audio/,/^Video/p' | sed -n '/Sinks:/,/Sources:/p' \
        | sed -nE 's/^[^0-9*]*(\*)?[[:space:]]*([0-9]+)\.[[:space:]]+(.*[^[:space:]])[[:space:]]+\[vol:.*/\1|\2|\3/p')
    (( ${#sinks[@]} == 0 )) && { osd "No audio devices found"; exit 1; }
    cur=0; for i in "${!sinks[@]}"; do [[ ${sinks[$i]} == \** ]] && cur=$i; done
    next=${sinks[$(( (cur + 1) % ${#sinks[@]} ))]}
    IFS='|' read -r _ id desc <<<"$next"
    wpctl set-default "$id"; osd "$desc" audio-speakers-symbolic ;;
brightness) # raise | lower | +N | -N | N  (percent of the laptop screen)
    dev=$(ls /sys/class/backlight 2>/dev/null | head -n1); [[ -z $dev ]] && exit 1
    max=$(< "/sys/class/backlight/$dev/max_brightness"); cur=$(< "/sys/class/backlight/$dev/brightness")
    pct=$(( (cur * 100 + max / 2) / max ))
    case ${2:-raise} in
        raise) pct=$(( pct + 5 )) ;;
        lower) pct=$(( pct - 5 )) ;;
        +*)    pct=$(( pct + ${2#+} )) ;;
        -*)    pct=$(( pct - ${2#-} )) ;;
        *)     pct=$2 ;;
    esac
    (( pct < 1 )) && pct=1; (( pct > 100 )) && pct=100
    set_brightness backlight "$dev" $(( max * pct / 100 ))
    swayosd-client --custom-icon display-brightness-symbolic \
        --custom-progress "$(awk -v p="$pct" 'BEGIN { print p / 100 }')" >/dev/null 2>&1 ;;
kbd-brightness) # up | down | cycle
    dev=$(kbd_led); [[ -z $dev ]] && exit 1
    max=$(brightnessctl -d "$dev" max); cur=$(brightnessctl -d "$dev" get)
    step=$(( max / 10 )); (( step < 1 )) && step=1
    case ${2:-up} in
        up)    new=$(( cur + step > max ? max : cur + step )) ;;
        down)  new=$(( cur - step < 0 ? 0 : cur - step )) ;;
        cycle) new=$(( cur + step > max ? 0 : cur + step )) ;;
    esac
    set_brightness leds "$dev" "$new"
    osd "Keyboard backlight $(( new * 100 / max ))%" keyboard-brightness-symbolic ;;
touchpad) # toggle | on | off
    dev=$(touchpad_name); [[ -z $dev ]] && exit 1
    want=${2:-toggle}
    [[ $want == toggle ]] && { [[ -f $STATE/touchpad-off ]] && want=on || want=off; }
    if [[ $want == on ]]; then
        hyprctl keyword "device[$dev]:enabled" true >/dev/null; rm -f "$STATE/touchpad-off"; osd "Touchpad enabled" input-touchpad-symbolic
    else
        hyprctl keyword "device[$dev]:enabled" false >/dev/null; touch "$STATE/touchpad-off"; osd "Touchpad disabled" touchpad-disabled-symbolic
    fi ;;

# --- Desktop ---------------------------------------------------------------
toggle-bar) pkill -SIGUSR1 -x waybar ;;
idle-toggle)
    if pgrep -x hypridle >/dev/null; then pkill -x hypridle; notify "Idle locking off"
    else hyprctl dispatch exec hypridle >/dev/null; notify "Idle locking on"; fi ;;
zoom-in)
    z=$(hyprctl getoption cursor:zoom_factor -j | jq '.float + 1'); hyprctl keyword cursor:zoom_factor "$z" >/dev/null ;;
zoom-reset) hyprctl keyword cursor:zoom_factor 1 >/dev/null ;;
show-time) notify "$(date +'%A %H:%M  ·  %d %B %Y  ·  Week %V')" ;;
show-battery)
    bat=$(upower -e | grep -m1 BAT)
    notify "$(upower -i "$bat" | awk -F': *' '/percentage|state|time to/ {printf "%s: %s\n", $1, $2}' | sed 's/^ *//')" ;;
theme-menu)
    cur=$(cat ~/.config/hypr/theme.name 2>/dev/null || echo "")
    pick=$(ls "$OMARCHY_THEMES" | fuzzel --dmenu --prompt "Theme ($cur): " --lines 20) || exit 0
    exec "$0" theme-set "$pick" ;;
theme-set) # <name> : write per-app theme files from Omarchy's templates, then reload
    name=${2:?theme name}; t="$OMARCHY_THEMES/$name"; tpl="$OMARCHY_SRC/default/themed"
    [[ -f $t/colors.toml ]] || { notify "No theme '$name'"; exit 1; }
    sedf=$(mktemp)
    while IFS='=' read -r k v; do
        k="${k//[\"\' ]/}"; [[ $k && $k != \#* ]] || continue
        v="${v#*[\"\']}"; v="${v%%[\"\']*}"
        printf 's|{{ %s }}|%s|g\ns|{{ %s_strip }}|%s|g\n' "$k" "$v" "$k" "${v#\#}"
        [[ $v =~ ^#([0-9a-fA-F]{6}) ]] && printf 's|{{ %s_rgb }}|%d,%d,%d|g\n' "$k" "0x${v:1:2}" "0x${v:3:2}" "0x${v:5:2}"
    done <"$t/colors.toml" >"$sedf"
    render() { if [[ -f $t/$1 ]]; then cat "$t/$1"; else sed -f "$sedf" "$tpl/$1.tpl"; fi; }
    render hyprland.conf      > ~/.config/hypr/theme.conf
    render hyprlock.conf      > ~/.config/hypr/theme-hyprlock.conf
    render waybar.css         > ~/.config/waybar/theme.css
    render swayosd.css        > ~/.config/swayosd/theme.css
    render ghostty.conf       > ~/.config/ghostty/themes/omarchy
    render alacritty.toml     > ~/.config/alacritty/theme.toml
    render mako.ini | sed 's|^include=.*|include=~/.config/mako/core.ini|' > ~/.config/mako/config
    eval "$(sed -nE 's/^(background|foreground|accent) *= *"#([0-9a-fA-F]{6}).*/\1=\2/p' "$t/colors.toml")"
    printf '[colors]\nbackground=%sf2\ntext=%sff\nprompt=%sff\ninput=%sff\nmatch=%sff\nselection=%sff\nselection-text=%sff\nselection-match=%sff\nborder=%sff\n' \
        "$background" "$foreground" "$accent" "$foreground" "$accent" "$accent" "$background" "$background" "$accent" > ~/.config/fuzzel/theme.ini
    rm -f "$sedf"
    bg=$(ls "$t/backgrounds" 2>/dev/null | sort | head -n1)
    [[ -n $bg ]] && cp "$t/backgrounds/$bg" ~/.config/hypr/wallpaper.jpg
    echo "$name" > ~/.config/hypr/theme.name
    [[ ${NO_RELOAD:-0} == 1 ]] && exit 0
    hyprctl reload >/dev/null
    pkill -SIGUSR2 -x waybar
    makoctl reload
    pkill -x swayosd-server; hyprctl dispatch exec swayosd-server >/dev/null
    pkill -x swaybg; hyprctl dispatch exec "swaybg -i $HOME/.config/hypr/wallpaper.jpg -m fill" >/dev/null
    for addr in $(hyprctl clients -j | jq -r '.[] | select(.class == "com.mitchellh.ghostty") | .address'); do
        hyprctl dispatch sendshortcut "CTRL SHIFT, comma, address:$addr" >/dev/null
    done
    notify "Theme: $name" ;;
background-menu)
    dir="$OMARCHY_THEMES/$(cat ~/.config/hypr/theme.name 2>/dev/null || echo tokyo-night)/backgrounds"
    pick=$( { ls "$dir"; ls ~/Pictures | grep -iE '\.(jpe?g|png)$'; } | fuzzel --dmenu --prompt "Background: ") || exit 0
    src="$dir/$pick"; [[ -f $src ]] || src=~/Pictures/$pick
    cp "$src" ~/.config/hypr/wallpaper.jpg
    pkill -x swaybg; hyprctl dispatch exec "swaybg -i ~/.config/hypr/wallpaper.jpg -m fill" >/dev/null ;;
capture-menu)
    dir=~/Pictures/Screenshots; mkdir -p "$dir"; f="$dir/$(date +%F_%H-%M-%S).png"
    choice=$(printf '%s\n' "Region" "Window" "Screen" | fuzzel --dmenu --prompt "Capture: " --lines 3) || exit 0
    case $choice in
        Region) grim -g "$(slurp)" "$f" ;;
        Window) grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$f" ;;
        Screen) grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" "$f" ;;
    esac && wl-copy <"$f" && notify "Screenshot saved and copied" "$f" ;;
keybindings) # cheat sheet from the bindd descriptions
    hyprctl binds -j | jq -r '
      def mods: [ (if (.modmask/64|floor)%2==1 then "SUPER" else empty end),
                  (if (.modmask/4|floor)%2==1  then "CTRL"  else empty end),
                  (if (.modmask/8|floor)%2==1  then "ALT"   else empty end),
                  (if .modmask%2==1            then "SHIFT" else empty end) ] | join(" + ");
      def keyname: if .key != "" then .key
                   else ({"10":"1","11":"2","12":"3","13":"4","14":"5","15":"6","16":"7","17":"8","18":"9","19":"0",
                          "20":"-","21":"=","61":"/"}[(.keycode|tostring)] // "code:\(.keycode)") end;
      .[] | select(.has_description) | "\([mods, keyname] | map(select(. != "")) | join(" + "))  →  \(.description)"' \
    | fuzzel --dmenu --prompt "Keys: " --width 70 --lines 25 >/dev/null ;;
webapp) exec google-chrome --app="$2" ;;
*)
    echo "Usage: $(basename "$0") <action>" >&2; exit 1 ;;
esac
