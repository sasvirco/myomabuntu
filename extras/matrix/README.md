# Matrix theme (optional extra)

Green-on-black colours from the 1999 film and an animated **digital rain** wallpaper: mirrored
half-width katakana and digits falling down every monitor, behind your windows, in the theme's
colours. Alacritty turns 70% opaque with this theme so the rain shows through your terminals
(other themes keep a solid terminal). Change `opacity` in `alacritty.toml` here and re-run the
installer, or edit `~/src/omarchy/themes/matrix/alacritty-extra.toml` and switch to the theme again.

## Install

Install myomabuntu first (`./install.sh`), then:

```bash
extras/matrix/install.sh
```

It simulates the apt install and asks before installing anything. It then puts the theme in
`~/src/omarchy/themes/matrix`, copies the rain to `~/.config/hypr/scripts/matrix-rain.py` and
switches to the theme. Options: `-y` (don't ask), `--skip-apt`, `--no-switch`, `--uninstall`.

Packages (all from Ubuntu's repos): `gir1.2-gtklayershell-0.1`, `gir1.2-gtk-3.0`, `python3-gi`,
`python3-gi-cairo`, `fonts-noto-cjk`, `git`. Most are already on an Ubuntu desktop.

## Use

- `Super+Shift+Ctrl+Space`: pick **matrix** (or any other theme; other themes use still wallpapers).
- `Super+Ctrl+Space`: pick **Digital rain (animated)** or one of the theme's still wallpapers.

Re-running the main `./install.sh` replaces `~/.config/hypr` and removes the rain; run
`extras/matrix/install.sh` again afterwards. Until then the theme falls back to a still wallpaper.

## CPU use

An animated wallpaper isn't free: the rain draws 8 frames a second and uses roughly a third of
one CPU core (the script plus Hyprland redrawing). It pauses on a monitor that shows a fullscreen
window, is switched off, or is locked. On battery, a still wallpaper from `Super+Ctrl+Space` costs
nothing. Tune `FPS`, `CELL` (character size) and `SPEED` at the top of `matrix-rain.py`.

## Credits

Theme colours and still wallpapers:
[BVisagie/omarchy-matrix-theme](https://github.com/BVisagie/omarchy-matrix-theme) (MIT),
pinned to a known-good commit in `install.sh`. The digital rain is myomabuntu's own.
