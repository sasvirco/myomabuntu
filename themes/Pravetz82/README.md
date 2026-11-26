# Pravetz82

A green-screen theme after the Pravetz 82, the Bulgarian Apple II-compatible home computer of the
1980s. Installed with myomabuntu; pick it with `Super+Shift+Ctrl+Space`.

- **Colours:** like a green monochrome monitor of the Pravetz 82 era. One P1 phosphor green
  (`#33FF33`, the Apple II-era green screen) on dark glass. A monochrome screen shows colours only
  as brightness, so each terminal colour is the green shade of its grey value, and bright colours
  bloom toward white. Selection is INVERSE (dark text on a solid green bar), as on the Apple II and
  Pravetz 82; muted text is the phosphor at half drive. Inspired by
  [Phosphor Green](https://github.com/squatchware/omarchy-phosphor-green-theme).
- **Icons:** `Yaru-olive-dark` (only used by Omarchy itself; myomabuntu leaves GNOME's icon theme alone).
- **Wallpaper:** original pixel art of an 8-bit computer whose screen reads `ПРАВЕЦ 82` /
  `48K RAM SYSTEM`, on a Tron-style neon grid. `make-wallpaper.py` draws it; edit the text or
  colours there and run:

      python3 make-wallpaper.py backgrounds/01-8bit-grid.png

- **Terminal:** Alacritty turns 85% opaque with this theme (`alacritty-extra.toml`) so the
  wallpaper shows through.
