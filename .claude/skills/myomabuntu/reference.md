# myomabuntu reference

## Files

| Path (installed) | Repo copy | Purpose |
|---|---|---|
| `~/.config/hypr/hyprland.conf` | `files/config/hypr/` | input, autostart (`exec-once`), all key bindings |
| `~/.config/hypr/looknfeel.conf` | same | Omarchy v3.8.4 gaps, borders, blur, animations, groupbar |
| `~/.config/hypr/theme.conf` | generated | theme border/group colours (sourced after looknfeel) |
| `~/.config/hypr/hypridle.conf` | same | lock 300 s, screen off 330 s, suspend 900 s |
| `~/.config/hypr/hyprlock.conf` | same | lock screen layout; sources `theme-hyprlock.conf` |
| `~/.config/hypr/wallpaper.jpg` | not in repo | current wallpaper (used by swaybg and hyprlock) |
| `~/.config/hypr/theme.name` | not in repo | current theme name |
| `~/.config/hypr/scripts/hypr-tools.sh` | same | replacements for `omarchy-*` scripts |
| `~/.config/hypr/scripts/new-tab.sh` | same | `Super+Shift+Return`: terminal as a new group tab |
| `~/.config/hypr/scripts/system-menu.sh` | same | `Super+Escape`: lock / log out / suspend / reboot / shut down |
| `~/.config/waybar/config.jsonc`, `style.css` | same | top bar; `style.css` imports `theme.css` |
| `~/.config/mako/core.ini` | same | notification rules; `config` = theme colours + `include=` core |
| `~/.config/swayosd/config.toml`, `style.css` | same | volume/brightness OSD |
| `~/.config/fuzzel/fuzzel.ini` | same | launcher and every menu; includes `theme.ini` |
| `~/.config/ghostty/config.ghostty` | same | font, `theme=omarchy`, clipboard keybinds (shared with GNOME) |
| `~/.config/autostart/blueman.desktop` | `files/config/autostart/` | `NotShowIn=GNOME;` keeps blueman's applet out of GNOME |
| `~/src/omarchy` (tag v3.8.4) | cloned by installer | themes, wallpapers, templates (`default/themed/*.tpl`) |
| `~/myomabuntu-backup/<date_time>/` | made by installer | dconf dump, package list, old configs |

## hypr-tools.sh actions

`~/.config/hypr/scripts/hypr-tools.sh <action> [args]`. Needs `jq`.

| Action | Does | Bound to |
|---|---|---|
| `theme-set <name>` | fill templates from `themes/<name>/colors.toml`, set wallpaper, reload everything | – |
| `theme-menu` | fuzzel list of themes → `theme-set` | `Super+Shift+Ctrl+Space` |
| `background-menu` | pick a wallpaper from the theme or `~/Pictures` | `Super+Ctrl+Space` |
| `keybindings` | cheat sheet from `bindd` descriptions | `Super+K` |
| `capture-menu` | region / window / screen to `~/Pictures/Screenshots` + clipboard | `Super+Ctrl+C` |
| `pop` | float, resize, centre and pin the window (again to undo) | `Super+O` |
| `layout-toggle` | dwindle ↔ master | `Super+L` |
| `transparency`, `gaps-toggle`, `aspect-toggle` | window/look toggles | `Super+(Shift/Ctrl+)Backspace` |
| `close-all` | close every window, go to workspace 1 | `Ctrl+Alt+Delete` |
| `internal-display on\|off\|toggle` | laptop screen off when an external monitor is connected | `Super+Ctrl+Delete` |
| `mirror-toggle` | mirror laptop screen to the external monitor | `Super+Ctrl+Alt+Delete` |
| `lid close\|open` | lid switch: laptop screen off/on with an external monitor | lid |
| `scale-cycle [--reverse]` | 1, 1.25, 1.5, 2 (until next reload) | `Super+/`, `Super+Alt+/` |
| `audio-output-switch` | next audio output (wpctl) | `Super+Mute` |
| `brightness raise\|lower\|±N\|N` | laptop screen brightness (percent), through systemd-logind | brightness keys |
| `kbd-brightness up\|down\|cycle` | keyboard backlight, through systemd-logind | backlight keys |
| `touchpad toggle\|on\|off` | touchpad on/off | touchpad keys |
| `toggle-bar`, `idle-toggle` | hide Waybar, stop/start hypridle | `Super+Shift+Space`, `Super+Ctrl+I` |
| `zoom-in`, `zoom-reset` | cursor zoom | `Super+Ctrl+Z`, `Super+Ctrl+Alt+Z` |
| `show-time`, `show-battery` | notification | `Super+Ctrl+Alt+T` / `B` |
| `webapp <url>` | `google-chrome --app=<url>` | `Super+Shift+letter` web apps |

Toggles that use `hyprctl keyword` reset on `hyprctl reload` (that's how gaps-toggle and the
display actions turn things back on). State flags live in `$XDG_RUNTIME_DIR/hypr-tools/`.

## How theming works

`theme-set` builds a sed script from `colors.toml` (`{{ key }}`, `{{ key_strip }}` without `#`,
`{{ key_rgb }}` as `r,g,b`), the same way Omarchy's `omarchy-theme-set-templates` does, then
renders `~/src/omarchy/default/themed/<file>.tpl`. A theme's own file (e.g.
`themes/kanagawa/hyprland.conf`) wins over the template. Fuzzel colours are built from
`background`, `foreground` and `accent`. Afterwards it reloads Hyprland, Waybar (SIGUSR2) and
Mako, restarts swayosd-server and swaybg, and sends `Ctrl+Shift+,` to every Ghostty window. Alacritty reloads `theme.toml` on its own.
`NO_RELOAD=1` skips the reloads (used by the installer).

Light themes (`catppuccin-latte`, `flexoki-light`, `rose-pine`, `white`) don't switch GTK to light
mode, because that's a GNOME setting.

## Packages

```
hyprland hyprland-qtutils hyprlock hypridle hyprpolkitagent hyprpicker xdg-desktop-portal-hyprland
waybar mako-notifier swayosd swaybg fuzzel wl-clipboard cliphist grim slurp
brightnessctl playerctl pamixer network-manager-gnome blueman fonts-jetbrains-mono jq ghostty
alacritty tmux
```

All from Ubuntu 26.04's main/universe, installed with `--no-install-recommends`. The Nerd Font comes from
the Nerd Fonts v3.4.0 release into `~/.local/share/fonts/JetBrainsMonoNerd` (user only).

## Known Hyprland 0.53 gotchas

- One-line blocks (`name { a = b }`) are rejected; write them across several lines.
- No `scrolling` layout; Omarchy v3.8.4's `scrolling { }` block was removed from `looknfeel.conf`.
- `layout:single_window_aspect_ratio` is `dwindle:single_window_aspect_ratio` here.
- Omarchy v4.x moved to Lua configs that need a newer Hyprland; stay on v3.8.4 files.
