---
name: myomabuntu
description: Install, customise, troubleshoot or remove myomabuntu, the Omarchy-style Hyprland session for Ubuntu 26.04 that runs next to GNOME. Use when the user wants to install it, change key bindings, themes, wallpaper, Waybar, notifications, the lock screen, idle timeouts, the terminal or launcher, add or adapt Omarchy features, fix a black screen or config error after login, or uninstall it.
---

# myomabuntu

myomabuntu puts Omarchy v3.8.4's look, themes and key bindings on Ubuntu 26.04 as an **extra
Hyprland login session**. GNOME, GDM and GNOME settings stay untouched, so picking **Ubuntu** at
the login screen always gets the user back.

The repo root (where this skill lives under `.claude/skills/`) contains `install.sh`,
`files/config/` (the configs it installs) and `README.md`. Read `README.md` for what users see;
read [reference.md](reference.md) for file locations, the helper script and how each part works.

## Rules (never break these)

1. **Never install or enable another display manager** (SDDM, LightDM, greetd). GDM stays.
2. **Never change GNOME settings, dconf, GDM config or `/etc/systemd/logind.conf`** to make
   Hyprland work. Everything lives in `~/.config/{hypr,waybar,mako,swayosd,fuzzel,alacritty,tmux,ghostty}`.
   Reading GNOME settings (`gsettings get`, `dconf dump`) is fine.
3. **Never run Omarchy's own installer** or `source` files from `~/src/omarchy`. It is Arch-only
   and replaces system config. Copy and adapt pieces instead.
4. **No PPAs or building from source** unless the user explicitly asks. Use Ubuntu's repos.
5. **Back up before overwriting** a config file the user may have edited
   (`cp file ~/myomabuntu-backup/<date>/`).
6. **Validate every change** before telling the user it's done (see "Checking changes").
7. `~/.config/ghostty/config.ghostty` is also used by Ghostty in GNOME. Say so when changing it.

## Installing

Run the installer from the repo root and let the user answer the package prompt:

```bash
./install.sh            # backs up, simulates apt, asks, installs, writes configs, verifies
./install.sh --skip-apt # configs only, no sudo
THEME=nord ./install.sh # start with another theme (any folder in ~/src/omarchy/themes)
```

- It needs `sudo`. If `sudo -n true` fails, ask the user to run it themselves with
  `! ./install.sh` so they can type their password.
- It stops on its own if apt would remove packages or pull in a display manager. Don't work
  around that; show the user the output.
- After it finishes, the user logs out, picks **Hyprland** (not "Hyprland (uwsm)") from the gear
  icon on the GDM login screen, and logs in. `Super+K` lists all key bindings.
- On a managed or work laptop, suggest checking with IT first: Hyprlock replaces GNOME's lock
  screen and GNOME lock policies don't apply in this session.

## Customising

**Edit the live files in `~/.config/`**, check them, and reload. If the user wants the change kept
in the repo (to share or reinstall), copy the same change into `files/config/` too. Live and
repo copies are separate.

Common requests:

| Request | Where | Apply with |
|---|---|---|
| Add or change a key binding | `~/.config/hypr/hyprland.conf` (`bindd` lines, grouped by `# Section`) | `hyprctl reload` |
| Switch theme | `~/.config/hypr/scripts/hypr-tools.sh theme-set <name>` or `Super+Shift+Ctrl+Space` | automatic |
| Wallpaper | `Super+Ctrl+Space`, or copy an image to `~/.config/hypr/wallpaper.jpg` | `hypr-tools.sh theme-set` or restart swaybg |
| Gaps, borders, blur, animations | `~/.config/hypr/looknfeel.conf` | `hyprctl reload` |
| Keyboard layout, touchpad | `input { }` in `hyprland.conf` | `hyprctl reload` |
| Monitors, scaling | `monitor = ` line in `hyprland.conf` | `hyprctl reload` |
| Lock and sleep timeouts | `~/.config/hypr/hypridle.conf` | `pkill hypridle; hyprctl dispatch exec hypridle` |
| Top bar modules | `~/.config/waybar/config.jsonc`, `style.css` | `pkill -SIGUSR2 waybar` |
| Notifications | `~/.config/mako/core.ini` (rules; `config` is generated) | `makoctl reload` |
| Launcher look | `~/.config/fuzzel/fuzzel.ini` (`theme.ini` is generated) | next launch |
| Terminal font, settings | `~/.config/alacritty/alacritty.toml` | automatic |
| tmux | `~/.config/tmux/tmux.conf` | prefix `Ctrl+Space`, then `q` |
| GNOME's Ghostty | `~/.config/ghostty/config.ghostty` | `Ctrl+Shift+,` in Ghostty |
| Programs started at login | `exec-once = ` lines in `hyprland.conf` | next login |

Don't edit the generated theme files (`hypr/theme.conf`, `hypr/theme-hyprlock.conf`,
`waybar/theme.css`, `swayosd/theme.css`, `mako/config`, `fuzzel/theme.ini`,
`ghostty/themes/omarchy`, `alacritty/theme.toml`). `theme-set` rewrites them. To change a theme's colours, edit its
`colors.toml` in a copy under `~/src/omarchy/themes/<new-name>/` and `theme-set` that.

### Key bindings

Write bindings as `bindd` so `Super+K` shows them:

```ini
bindd = $mod SHIFT, B, Browser, exec, google-chrome
#       mods        key description  dispatcher, args
```

- Variants: `bindmd` (mouse), `bindeld` (repeat, works when locked), `bindld` (works when locked).
- Number-row keys use keycodes (`code:10` = `1` … `code:19` = `0`, `code:20` = `-`,
  `code:21` = `=`) so they work in any keyboard layout.
- Before adding, check the key is free:
  `grep -nE '^bind[a-z]* *= *MODS, KEY,' ~/.config/hypr/hyprland.conf`. If it's taken, tell the
  user what it does now and ask which to keep.
- For anything more than one command, add an action to `~/.config/hypr/scripts/hypr-tools.sh`
  (a `case` branch) instead of a long inline command.
- Hyprland is **0.53** (Ubuntu's version). Check syntax against that version; Omarchy v4.x Lua
  configs and newer options like the `scrolling` layout don't work.

### Porting more from Omarchy

Omarchy's source is at `~/src/omarchy` (tag v3.8.4). Its bindings are in
`default/hypr/bindings/*.conf` and `config/hypr/bindings.conf`; its scripts are in `bin/`. To port
a feature: read the `omarchy-*` script, rewrite it with plain tools in `hypr-tools.sh`, and replace
Arch-only commands (`pacman`, `yay`, `uwsm app --`, `omarchy-launch-*`, `xdg-terminal-exec`, Walker)
with Ubuntu ones (`apt`, plain commands, `alacritty -e`, fuzzel). If it needs a package Ubuntu
doesn't have, say so instead of building it.

## Checking changes

Always run what applies and show failures to the user:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.conf | tail -1   # must print "config ok"
hyprctl configerrors                                                 # empty when running
alacritty migrate --dry-run -c ~/.config/alacritty/alacritty.toml    # after Alacritty changes
ghostty +validate-config                                             # after Ghostty changes
bash -n ~/.config/hypr/scripts/hypr-tools.sh                         # after script changes
python3 -c "import json,sys;json.load(open(sys.argv[1]))" ~/.config/waybar/config.jsonc
# keys bound twice (only ALT, Tab and ALT SHIFT, Tab are intended):
grep -E '^bind[a-z]* *=' ~/.config/hypr/hyprland.conf | sed -E 's/^bind[a-z]* *= *//' \
  | cut -d, -f1,2 | sort | uniq -d
```

Hyprland rejects blocks written on one line (`touchpad { natural_scroll = true }`); write them
across several lines.

`hyprctl` only works from inside a running Hyprland session. When the user runs Claude Code from
GNOME, use `Hyprland --verify-config` and tell them the change applies at their next Hyprland
login.

Don't press keys or run actions that open windows, lock the screen, change monitors or log out
to "test" them. Ask the user to try them.

## Troubleshooting

- **Black screen or back at the login screen after picking Hyprland:** `Ctrl+Alt+F3`, log in,
  read `~/.local/share/hyprland/hyprland.log` or `$XDG_RUNTIME_DIR/hypr/*/hyprland.log`, fix,
  then `sudo systemctl restart gdm3`. Usually a config error: run `Hyprland --verify-config`.
- **GDM keeps starting Hyprland:**
  `sudo sed -i 's/^Session=.*/Session=ubuntu/' /var/lib/AccountsService/users/$USER` then
  `sudo systemctl restart gdm3`.
- **Icons show as boxes:** the JetBrainsMono Nerd Font is missing; `fc-list | grep -c 'JetBrainsMono Nerd'`
  should be non-zero. Re-run the font step from `install.sh`.
- **Bar, notifications or OSD missing:** check the process (`pgrep -a waybar`) and start it with
  `hyprctl dispatch exec <name>` to see errors.
- **`Super+C`/`V` don't work in Alacritty:** `alacritty.toml` needs the `Shift+Insert` (Paste)
  and `Control+Insert` (Copy) bindings.
- **Brightness keys do nothing:** Ubuntu's brightnessctl has no logind support, so writing the
  backlight needs the `video` group. `hypr-tools.sh brightness` and `kbd-brightness` set it through
  systemd-logind (`set_brightness`) instead; don't switch them back to `swayosd-client --brightness`
  or `brightnessctl set`.
- **A tmux pane ignores typing:** output was paused with `Ctrl+S`; `Ctrl+Q` resumes it.
- **`Super+C`/`V` don't work in Ghostty:** `config.ghostty` needs
  `keybind = shift+insert=paste_from_clipboard` and `keybind = control+insert=copy_to_clipboard`.
- **Power button shuts down at once:** expected under Hyprland (logind handles it). Changing
  `logind.conf` breaks rule 2; tell the user instead.

## Uninstalling

Follow the "Uninstall" section of `README.md`. Show the `apt-get -s autoremove` list to the user
before removing anything, and never remove packages they had before (compare with
`~/myomabuntu-backup/<date>/apt-manual.txt`).
