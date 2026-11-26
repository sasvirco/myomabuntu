# myomabuntu

The [Omarchy](https://github.com/basecamp/omarchy) look and key bindings on **Ubuntu 26.04**, as
an extra **Hyprland** login session next to GNOME.

GNOME, GDM and your GNOME settings are not touched. If you don't like it, pick **Ubuntu** at the
login screen and you're back where you were.

Omarchy itself is an Arch Linux setup and its installer only works there. This repo takes Omarchy
v3.8.4's look (themes, Waybar, Mako, SwayOSD, Hyprlock, window styling) and key bindings, and
replaces the `omarchy-*` scripts with plain Ubuntu tools.

## What you get

- Hyprland 0.53 (from Ubuntu's own repos) with Omarchy's gaps, borders, blur and animations
- Waybar top bar, Mako notifications, SwayOSD volume/brightness pop-ups, Hyprlock lock screen,
  hypridle (locks after 5 min, screen off after 5.5, suspend after 15)
- fuzzel as the app launcher (Omarchy uses Walker, which Ubuntu doesn't package)
- Alacritty terminal with JetBrainsMono Nerd Font (Ghostty gets the same font and theme for GNOME)
- tmux with Omarchy's config: `Super+Alt+Return` opens a "Work" session, prefix `Ctrl+Space`
- All 19 Omarchy themes, switchable with `Super+Shift+Ctrl+Space` (Tokyo Night by default)
- About 165 Omarchy key bindings, including window groups as tabs. `Super+K` lists them all.

## Requirements

- Ubuntu 26.04 with GNOME and GDM (the default desktop)
- `sudo` rights, an internet connection
- Optional apps the key bindings open: Google Chrome, VS Code, 1Password, Signal. The installer
  warns about any that are missing.

## Install

```bash
git clone https://github.com/sasvirco/myomabuntu.git
cd myomabuntu
./install.sh
```

The installer:

1. Checks it's Ubuntu with GDM, and that you're not root.
2. Backs up your GNOME settings, package list and any existing configs to
   `~/myomabuntu-backup/<date_time>/`.
3. Simulates the package install and **stops if apt would remove anything or install a different
   display manager**. Then it shows the package list and asks before installing.
4. Installs JetBrainsMono Nerd Font for your user only (no root).
5. Clones Omarchy v3.8.4 to `~/src/omarchy` for its themes and wallpapers. Omarchy's own installer
   is never run.
6. Writes configs to `~/.config/{hypr,waybar,mako,swayosd,fuzzel,alacritty,tmux,ghostty}`, copies your keyboard
   layouts from GNOME, and applies the theme.
7. Checks the Hyprland, Alacritty and Ghostty configs and confirms GNOME settings and GDM are unchanged.

Options: `-y` skips the question before installing packages, `--skip-apt` writes configs only (no
sudo), `THEME=nord ./install.sh` starts with another theme.

**Ghostty note:** GNOME's Ghostty reads the same config file, so the font and theme change there
too. Your old Ghostty config is in the backup.

## First login

1. Log out. On the login screen click your name, then the gear icon at the bottom right, and pick
   **Hyprland**. Don't pick "Hyprland (uwsm)".
2. Log in. Press `Super+Return` for a terminal and `Super+K` for the key binding list.
3. If you get a black screen: `Ctrl+Alt+F3`, log in on the text console, read
   `~/.local/share/hyprland/hyprland.log`, then `sudo systemctl restart gdm3` and pick **Ubuntu**.

## Keys to start with

| Keys | Action |
|---|---|
| `Super+K` | List all key bindings |
| `Super+Return` | Terminal |
| `Super+Shift+Return` | New terminal tab (see Tabs below) |
| `Super+Space` | Launch apps |
| `Super+Escape` | Lock, log out, suspend, reboot, shut down |
| `Super+W` | Close window |
| `Super+F` / `Super+T` | Full screen / float |
| `Super+arrows` / `Super+Shift+arrows` | Focus / swap windows |
| `Super+1…0` / `Super+Shift+1…0` | Go to / move window to workspace |
| `Super+C` / `Super+V` / `Super+X` | Copy / paste / cut in any app, including terminals |
| `Super+Ctrl+V` | Clipboard history |
| `Print` / `Super+Ctrl+C` | Screenshot region to clipboard / capture menu |
| `Super+Shift+Ctrl+Space` | Theme menu |
| `Super+Ctrl+Space` | Wallpaper menu |
| `Super+Ctrl+L` | Lock |
| `Alt+Shift` | Switch keyboard layout (if GNOME has more than one) |

### Tabs

Tabs are Hyprland window groups, like in Omarchy: windows stack in one tile with a tab bar on top.

- `Super+G` turns the focused window into a group (again to break it up).
- `Super+Shift+Return` opens a terminal as a new tab, grouping the window first if needed.
- `Super+Alt+Tab` or `Super+Ctrl+←/→` switches tabs; `Super+Alt+1…5` jumps to tab N.
- `Super+Alt+arrows` moves a window into the neighbouring group, `Super+Alt+G` takes it out.

## Themes

`Super+Shift+Ctrl+Space` lists catppuccin, catppuccin-latte, ethereal, everforest,
flexoki-light, gruvbox, hackerman, kanagawa, lumon, matte-black, miasma, nord, osaka-jade,
retro-82, ristretto, rose-pine, tokyo-night, vantablack and white. Or from a terminal:

```bash
~/.config/hypr/scripts/hypr-tools.sh theme-set nord
```

A theme recolours Hyprland, Waybar, Mako, SwayOSD, fuzzel, Hyprlock, Alacritty and Ghostty, and sets the
theme's first wallpaper. Light themes don't switch GTK apps to light mode, because that's a GNOME
setting.

## Differences from Omarchy

| Omarchy | Here |
|---|---|
| Arch, `omarchy-*` scripts | Ubuntu packages, `~/.config/hypr/scripts/hypr-tools.sh` |
| Walker launcher and menus | fuzzel |
| Lua config (v4.x) | v3.8.4 `.conf` files, because Ubuntu ships Hyprland 0.53 |
| SDDM login | GDM stays; Hyprland is an extra session |
| HEY mail/calendar, Chromium web apps | Gmail, Google Calendar, `google-chrome --app` |

Left out because Ubuntu doesn't package the tools or they're Omarchy-only: the Omarchy menu,
night light (`hyprsunset`), screen recording, OCR, dictation, reminders, weather, and terminals
that open in the current folder.

## Customising with Claude Code

The repo includes a [Claude Code](https://claude.com/claude-code) skill in
`.claude/skills/myomabuntu/`. It loads only when Claude Code runs in the cloned folder:

```bash
cd myomabuntu
claude
```

Then ask in plain words. Claude Code picks the skill up by itself, or type `/myomabuntu`
followed by your request to call it directly.

**Install and remove**

- "install myomabuntu", "install it with the nord theme"
- "uninstall myomabuntu" (shows what would be removed first, keeps packages you had before)

**Customise**

- Key bindings: "open Firefox on Super+Shift+F". It checks whether the key is taken and asks
  which to keep.
- Themes and wallpaper: "switch to gruvbox", "make a theme like nord with an orange accent",
  "use this picture as the wallpaper"
- Look: gaps, borders, rounded corners, blur, animations
- Top bar: "add a battery percentage", "show the date in the clock", restyle it
- Lock and sleep: "lock after 10 minutes instead of 5", "don't suspend on idle"
- Keyboard, touchpad, monitors: layouts, scroll direction, scaling, monitor positions
- Notifications: position, timeout, apps to hide
- Terminal and launcher: Alacritty font and settings, tmux, how fuzzel looks
- Programs started at login
- More from Omarchy: "port Omarchy's night light". It rewrites `omarchy-*` scripts with Ubuntu
  tools, and says so if Ubuntu doesn't package what's needed.

**Fix problems**

- "I get a black screen after picking Hyprland", "the login screen always starts Hyprland"
- Icons showing as boxes, the bar or notifications missing, copy/paste keys not working in
  Ghostty, config errors after an edit

**How it works on every change**

- It never installs another display manager, never changes GNOME settings, and never runs
  Omarchy's own installer.
- It backs up files before overwriting them and validates the config before saying it's done.
- It won't press keys that open windows, lock the screen or log out to test a change; it asks
  you to try them.
- Changes go to your live configs in `~/.config/` only. To keep a change in the repo (to share
  it or reinstall with it), ask it to "copy that change into the repo" and it updates
  `files/config/` too.
- If you run Claude Code from GNOME, it checks changes with `Hyprland --verify-config` and they
  apply the next time you log in to Hyprland.

## Uninstall

Pick **Ubuntu** at the login screen; GNOME was never changed, so that's enough for daily use.

To remove everything (the `apt remove` list matches what `install.sh` installs; skip any package
you used before):

```bash
mkdir -p ~/myomabuntu-backup/removed
mv ~/.config/{hypr,waybar,mako,swayosd,fuzzel,alacritty,tmux} ~/myomabuntu-backup/removed/
rm ~/.config/autostart/blueman.desktop
rm -r ~/.config/systemd/user/{waybar,mako,hypridle,hyprpolkitagent}.service.d
# restore your old Ghostty config from ~/myomabuntu-backup/<date_time>/ghostty if you had one
sudo apt remove hyprland hyprland-qtutils hyprlock hypridle hyprpolkitagent hyprpicker xdg-desktop-portal-hyprland \
  waybar mako-notifier swayosd swaybg fuzzel cliphist alacritty tmux
apt-get -s autoremove | grep '^Remv'   # read this list before running autoremove for real
```

If the login screen keeps starting Hyprland and it fails, from a text console (`Ctrl+Alt+F3`):

```bash
sudo sed -i 's/^Session=.*/Session=ubuntu/' /var/lib/AccountsService/users/$USER
sudo systemctl restart gdm3
```

## Known issues

- **Power button:** under GNOME it opens a menu; under Hyprland, systemd may shut down straight
  away. Don't press it unless you mean it.
- `Super+Ctrl+A` / `Super+Ctrl+W` open GNOME Settings (sound / Wi-Fi), which may not fully work
  outside GNOME.
- Hyprlock replaces GNOME's lock screen in this session. If your laptop is managed (company
  policies for screen lock), check the idle timeouts in `~/.config/hypr/hypridle.conf`.

## Layout

```
install.sh                         installer
files/config/hypr/                 hyprland.conf (bindings), looknfeel.conf, hypridle/hyprlock
files/config/hypr/scripts/         hypr-tools.sh (replaces omarchy-* scripts), new-tab.sh, system-menu.sh
files/config/{waybar,mako,swayosd,fuzzel,alacritty,tmux,ghostty}/
files/config/autostart/            keeps blueman's tray applet out of GNOME
files/config/systemd/user/         keeps Ubuntu's waybar/mako/hypridle/polkit units out of GNOME
```

## Credits

Look, themes, key bindings and several config files come from
[Omarchy](https://github.com/basecamp/omarchy) by David Heinemeier Hansson and contributors, MIT
licence. See [LICENSE](LICENSE).

myomabuntu is a personal project. It is not affiliated with or endorsed by Omarchy, Basecamp or
David Heinemeier Hansson. Omarchy's wallpapers are not included in this repo; the installer
downloads them from Omarchy's own repository.
