#!/usr/bin/env bash
# Hyprland, Omarchy-style, as an extra login session next to GNOME on Ubuntu 26.04.
# Backs up, installs packages, and writes the configs in files/config/. See README.md.
#
#   ./install.sh             back up, simulate, ask, install, write configs
#   ./install.sh -y          don't ask before apt install
#   ./install.sh --skip-apt  no sudo and no apt install (configs only; for testing)
#
# It never installs a display manager and never changes GNOME settings, dconf or GDM.
# It is safe to re-run: every run makes a new backup first.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FILES="$HERE/files/config"
OMARCHY_REPO=https://github.com/basecamp/omarchy
OMARCHY_TAG=v3.8.4          # last tag with Waybar/Mako configs and .conf (not Lua) Hyprland files
OMARCHY_SRC=${OMARCHY_SRC:-$HOME/src/omarchy}
THEME=${THEME:-tokyo-night}   # any folder in omarchy/themes, e.g. THEME=nord ./install.sh
NERD_FONT_URL=https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.tar.xz

PKGS=(hyprland hyprland-qtutils hyprlock hypridle hyprpolkitagent hyprpicker xdg-desktop-portal-hyprland
      waybar mako-notifier swayosd swaybg fuzzel
      wl-clipboard cliphist grim slurp brightnessctl playerctl pamixer
      network-manager-gnome blueman fonts-jetbrains-mono jq ghostty alacritty tmux)

ASSUME_YES=0
SKIP_APT=0
for arg in "$@"; do
    case $arg in
        -y|--yes)   ASSUME_YES=1 ;;
        --skip-apt) SKIP_APT=1 ;;
        -h|--help)  sed -n '2,11p' "$0"; exit 0 ;;
        *)          echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; WARNINGS+=("$*"); }
die()  { printf '\n\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
WARNINGS=()

# --- 0. Pre-flight -----------------------------------------------------------
step "Pre-flight checks"
[[ $EUID -ne 0 ]] || die "Run as your normal user, not root (it uses sudo only for apt)."
[[ -d $FILES/hypr ]] || die "Missing $FILES. Keep install.sh next to the files/ folder."
. /etc/os-release
[[ ${ID:-} == ubuntu ]] || die "This is for Ubuntu (found ${ID:-unknown})."
[[ ${VERSION_ID:-} == 26.04 ]] || warn "Tested on Ubuntu 26.04, this is ${VERSION_ID:-unknown}."
DM=$(cat /etc/X11/default-display-manager 2>/dev/null || echo none)
[[ $DM == /usr/sbin/gdm3 ]] || die "Display manager is $DM, expected /usr/sbin/gdm3."
ok "Ubuntu ${VERSION_ID}, GDM, user $USER"

# --- 1. Back up --------------------------------------------------------------
B=$HOME/myomabuntu-backup/$(date +%F_%H%M%S)
step "Backing up current state to $B"
mkdir -p "$B"
dconf dump / > "$B/dconf.ini"
apt-mark showmanual | sort > "$B/apt-manual.txt"
ls /usr/share/wayland-sessions/ > "$B/sessions.txt"
echo "$DM" > "$B/display-manager.txt"
if [[ $SKIP_APT == 0 ]]; then
    sudo cat "/var/lib/AccountsService/users/$USER" > "$B/accountsservice.txt" || warn "Could not back up AccountsService file"
fi
for d in hypr waybar mako swayosd fuzzel alacritty tmux ghostty; do
    if [[ -e $HOME/.config/$d ]]; then cp -a "$HOME/.config/$d" "$B/$d"; ok "Backed up existing ~/.config/$d"; fi
done
[[ -e $HOME/.config/autostart/blueman.desktop ]] && cp -a "$HOME/.config/autostart/blueman.desktop" "$B/"
ok "Backup done"

# --- 2. Simulate -------------------------------------------------------------
step "Simulating package install"
SIM=$(apt-get -s install --no-install-recommends "${PKGS[@]}" 2>&1) || die "apt simulation failed:
$SIM"
if grep -q '^Remv' <<<"$SIM"; then
    grep '^Remv' <<<"$SIM"; die "The install would remove packages. Stopping."
fi
if grep -E '^Inst' <<<"$SIM" | grep -qiE '\b(sddm|lightdm|greetd|gdm3)\b'; then
    grep -E '^Inst' <<<"$SIM" | grep -iE 'sddm|lightdm|greetd|gdm3'; die "The install would pull in a display manager. Stopping."
fi
NEW=$(grep -c '^Inst' <<<"$SIM" || true)
ok "No removals, no display manager; $NEW packages to install"

# --- 3. Install --------------------------------------------------------------
step "Installing packages"
if [[ $SKIP_APT == 1 ]]; then
    warn "--skip-apt: not installing packages"
elif [[ $NEW == 0 ]]; then
    ok "All packages already installed"
else
    grep '^Inst' <<<"$SIM" | awk '{print "      " $2}'
    if [[ $ASSUME_YES == 0 ]]; then
        read -rp "    Install these $NEW packages? [y/N] " reply
        [[ $reply =~ ^[Yy]$ ]] || die "Stopped before installing. Backup is in $B."
    fi
    sudo apt-get install -y --no-install-recommends "${PKGS[@]}"
fi
if [[ $SKIP_APT == 0 ]]; then
    ls /usr/share/wayland-sessions/hyprland.desktop >/dev/null || die "hyprland.desktop session missing after install"
    [[ $(cat /etc/X11/default-display-manager) == /usr/sbin/gdm3 ]] || die "Display manager changed!"
    ok "Hyprland session present, GDM still the display manager"
fi

# --- Fonts -------------------------------------------------------------------
step "JetBrainsMono Nerd Font (user only)"
if fc-list | grep -q 'JetBrainsMono Nerd Font'; then
    ok "Already installed"
else
    tmp=$(mktemp -d)
    curl -fsSLo "$tmp/font.tar.xz" "$NERD_FONT_URL"
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerd"
    tar -xJf "$tmp/font.tar.xz" -C "$HOME/.local/share/fonts/JetBrainsMonoNerd" --wildcards 'JetBrainsMonoNerdFont-*.ttf'
    rm -rf "$tmp"
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null
    ok "Installed to ~/.local/share/fonts/JetBrainsMonoNerd"
fi

# --- Omarchy source (wallpapers for the background menu) ---------------------
step "Omarchy $OMARCHY_TAG (theme backgrounds only; its installer is never run)"
if [[ ! -d $OMARCHY_SRC/.git ]]; then
    mkdir -p "$(dirname "$OMARCHY_SRC")"
    git clone -q "$OMARCHY_REPO" "$OMARCHY_SRC"
fi
git -C "$OMARCHY_SRC" fetch -q --tags
git -C "$OMARCHY_SRC" -c advice.detachedHead=false checkout -q "$OMARCHY_TAG"
ok "$OMARCHY_SRC at $OMARCHY_TAG"

# --- 4/5. Configs ------------------------------------------------------------
step "Writing configs"
mkdir -p "$HOME/.config"
for d in hypr waybar mako swayosd fuzzel alacritty tmux; do
    rm -rf "$HOME/.config/$d"
    cp -a "$FILES/$d" "$HOME/.config/$d"
    ok "~/.config/$d"
done
mkdir -p "$HOME/.config/ghostty/themes"
cp "$FILES/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
ok "~/.config/ghostty (GNOME's Ghostty uses this too; old one is in the backup)"
mkdir -p "$HOME/.config/autostart"
cp "$FILES/autostart/blueman.desktop" "$HOME/.config/autostart/blueman.desktop"
ok "~/.config/autostart/blueman.desktop (keeps blueman's applet out of GNOME)"
# Ubuntu enables waybar, mako, hypridle and hyprpolkitagent for every graphical session,
# GNOME included. These drop-ins let systemd start them only inside Hyprland.
mkdir -p "$HOME/.config/systemd/user"
cp -a "$FILES/systemd/user/." "$HOME/.config/systemd/user/"
systemctl --user daemon-reload 2>/dev/null || true
ok "~/.config/systemd/user/*.service.d (keeps Waybar, Mako, hypridle, polkit agent out of GNOME)"
chmod +x "$HOME"/.config/hypr/scripts/*.sh
OMARCHY_SRC="$OMARCHY_SRC" NO_RELOAD=1 "$HOME/.config/hypr/scripts/hypr-tools.sh" theme-set "$THEME"
ok "Theme: $THEME (colours and wallpaper; Super+Shift+Ctrl+Space switches)"

# Keyboard layouts: same as GNOME's input sources (read-only)
layouts=() variants=()
while read -r src; do
    layouts+=("${src%%+*}")
    [[ $src == *+* ]] && variants+=("${src#*+}") || variants+=("")
done < <(gsettings get org.gnome.desktop.input-sources sources | grep -oE "\('xkb', '[^']+'\)" | sed -E "s/.*'xkb', '([^']+)'.*/\1/")
(( ${#layouts[@]} == 0 )) && { layouts=(us); variants=(""); }
kb_layout=$(IFS=,; echo "${layouts[*]}")
kb_variant=$(IFS=,; echo "${variants[*]}")
kb_options=""
(( ${#layouts[@]} > 1 )) && kb_options="grp:alt_shift_toggle"
conf=$HOME/.config/hypr/hyprland.conf
sed -i -E "s|^(\s*)kb_layout = .*|\1kb_layout = $kb_layout|; s|^(\s*)kb_variant = .*|\1kb_variant = $kb_variant|; s|^(\s*)kb_options = .*|\1kb_options = $kb_options|" "$conf"
ok "Keyboard: layout '$kb_layout', variant '$kb_variant'${kb_options:+, Alt+Shift switches}"

# Browser used by Super+Shift+B and the web apps
if ! command -v google-chrome >/dev/null; then
    warn "google-chrome not found: edit the 'google-chrome' lines in ~/.config/hypr/hyprland.conf and the webapp line in scripts/hypr-tools.sh (default browser: $(xdg-settings get default-web-browser 2>/dev/null || echo unknown))"
fi
for app in code 1password signal-desktop nautilus gnome-characters; do
    command -v "$app" >/dev/null || warn "$app not installed: its key binding won't do anything"
done

# --- Verify ------------------------------------------------------------------
step "Verifying"
if command -v Hyprland >/dev/null; then
    out=$(Hyprland --verify-config -c "$conf" 2>&1 | tail -1)
    [[ $out == "config ok" ]] && ok "Hyprland config ok" || die "Hyprland config check failed: $out"
fi
if command -v alacritty >/dev/null; then
    alacritty migrate --dry-run -c "$HOME/.config/alacritty/alacritty.toml" >/dev/null 2>&1 \
        && ok "Alacritty config ok" || warn "Alacritty config check failed"
fi
if command -v ghostty >/dev/null; then
    ghostty +validate-config >/dev/null && ok "Ghostty config ok" || warn "Ghostty config check failed"
fi
dconf dump / | diff -q - "$B/dconf.ini" >/dev/null && ok "GNOME settings (dconf) unchanged" || warn "dconf differs from the backup (something else changed it during the run?)"
[[ $(cat /etc/X11/default-display-manager) == /usr/sbin/gdm3 ]] && ok "GDM still the display manager"

step "Done"
echo "    Backup:  $B"
echo "    Next:    log out, pick 'Hyprland' (not 'Hyprland (uwsm)') from the gear icon at the GDM"
echo "             login screen, log in. Super+K lists all key bindings."
echo "    Undo:    pick 'Ubuntu' at login. To remove: see 'Uninstall' in README.md."
if (( ${#WARNINGS[@]} )); then
    echo; echo "    Warnings:"; printf '      - %s\n' "${WARNINGS[@]}"
fi
