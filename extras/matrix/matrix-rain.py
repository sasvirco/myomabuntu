#!/usr/bin/env python3
"""Animated digital-rain wallpaper for Hyprland.

Draws falling characters on the background layer of every monitor, in the
colours of the current Omarchy theme (background, accent, bright_foreground).
Started by `hypr-tools.sh wallpaper-start` when the wallpaper mode is "rain".
"""
import os
import random
import tomllib

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell, Pango, PangoCairo  # noqa: E402
import cairo  # noqa: E402

FPS = int(os.environ.get("RAIN_FPS", 8))  # each frame makes Hyprland redraw: keep it low
SPEED = (4.5, 13.5)  # rows per second, slowest/fastest stream
CELL = 20          # logical px per character cell
TAIL = (8, 30)     # min/max trail length in characters
FONT = "Noto Sans Mono CJK JP 14"
CHARS = [chr(c) for c in range(0xFF66, 0xFF9E)] + list("0123456789Z:.=*+-<>|")

THEMES = os.path.expanduser(os.environ.get("OMARCHY_THEMES", "~/src/omarchy/themes"))


def hex_rgb(value, fallback):
    v = (value or fallback).lstrip("#")[:6]
    return tuple(int(v[i:i + 2], 16) / 255 for i in (0, 2, 4))


def theme_colours():
    try:
        name = open(os.path.expanduser("~/.config/hypr/theme.name")).read().strip()
        with open(os.path.join(THEMES, name, "colors.toml"), "rb") as f:
            c = tomllib.load(f)
    except (OSError, tomllib.TOMLDecodeError):
        c = {}
    bg = hex_rgb(c.get("background"), "#0D0208")
    body = hex_rgb(c.get("accent"), "#00FF41")
    head = hex_rgb(c.get("bright_foreground"), "#DCFFDB")
    dim = tuple(b * 0.45 + g * 0.55 for b, g in zip(body, bg))
    return bg, body, head, dim


class Glyphs:
    """Pre-rendered characters, mirrored like the film's, per colour and scale."""

    def __init__(self, scale, colours, bg):
        self.cache = {}
        for key, rgb in colours.items():
            self.cache[key] = [self._render(ch, rgb, scale, bg) for ch in CHARS]

    @staticmethod
    def _render(ch, rgb, scale, bg):
        surf = cairo.ImageSurface(cairo.FORMAT_RGB24, CELL * scale, CELL * scale)
        surf.set_device_scale(scale, scale)
        cr = cairo.Context(surf)
        cr.set_source_rgb(*bg)
        cr.paint()
        layout = PangoCairo.create_layout(cr)
        layout.set_font_description(Pango.FontDescription.from_string(FONT))
        layout.set_text(ch, -1)
        _, ext = layout.get_pixel_extents()
        cr.translate(CELL, 0)
        cr.scale(-1, 1)  # mirror
        cr.move_to((CELL - ext.width) / 2 - ext.x, (CELL - ext.height) / 2 - ext.y)
        cr.set_source_rgb(*rgb)
        PangoCairo.show_layout(cr, layout)
        return surf

    def pick(self, key):
        return random.choice(self.cache[key])


class Rain(Gtk.Window):
    def __init__(self, monitor, colours):
        super().__init__()
        self.bg, body, head, dim = colours
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_monitor(self, monitor)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.BACKGROUND)
        GtkLayerShell.set_namespace(self, "wallpaper")
        GtkLayerShell.set_exclusive_zone(self, -1)
        for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                     GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(self, edge, True)
        self.colours = {"body": body, "head": head, "dim": dim}
        self.trail = None
        self.glyphs = None
        self.drops = []
        self.connect("draw", self.on_draw)
        self.connect("size-allocate", lambda *_: self.reset())
        self.show_all()

    def reset(self):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        gdkwin = self.get_window()
        if not gdkwin or w < 2 or h < 2:
            return
        scale = gdkwin.get_scale_factor()
        if self.trail and self.trail.get_width() == w * scale and self.trail.get_height() == h * scale:
            return
        self.trail = cairo.ImageSurface(cairo.FORMAT_RGB24, w * scale, h * scale)
        self.trail.set_device_scale(scale, scale)
        cr = cairo.Context(self.trail)
        cr.set_source_rgb(*self.bg)
        cr.paint()
        self.glyphs = Glyphs(scale, self.colours, self.bg)
        self.rows = h // CELL + 1
        self.drops = [self.new_drop(random.uniform(-2 * self.rows, 0)) for _ in range(w // CELL + 1)]

    @staticmethod
    def new_drop(start):
        # [row position, speed in rows per frame, last drawn row, trail length]
        return [start, random.uniform(*SPEED) / FPS, -1, random.randint(*TAIL)]

    def step(self):
        """Only touch the cells that change: new head, old head, dimming point, tail end."""
        if not self.trail:
            return
        cr = cairo.Context(self.trail)
        dirty = []
        for x, drop in enumerate(self.drops):
            pos, speed, last, tail = drop
            row = int(pos)
            if row != last:
                for r in range(max(last, -1) + 1, row + 1):  # rows passed this frame
                    self._cell(cr, x, r, "head", dirty)
                    self._cell(cr, x, r - 1, "body", dirty)
                    self._cell(cr, x, r - tail // 2, "dim", dirty)
                    self._cell(cr, x, r - tail, None, dirty)
                drop[2] = row
            drop[0] += speed
            if row - tail > self.rows:
                self.drops[x] = self.new_drop(random.uniform(-1.5 * self.rows, 0))  # pause before the next stream
        # a few characters inside the trails change, like the film's
        for _ in range(len(self.drops) // 5):
            x = random.randrange(len(self.drops))
            pos, _, _, tail = self.drops[x]
            back = random.randint(2, max(2, tail // 2 - 1))
            self._cell(cr, x, int(pos) - back, "body", dirty)
        for x, y in dirty:
            self.queue_draw_area(x, y, CELL, CELL)

    def _cell(self, cr, x, row, key, dirty):
        if row < 0 or row >= self.rows:
            return
        px, py = x * CELL, row * CELL
        if key:
            cr.set_source_surface(self.glyphs.pick(key), px, py)
        else:
            cr.set_source_rgb(*self.bg)
        cr.rectangle(px, py, CELL, CELL)
        cr.fill()
        dirty.append((px, py))

    def on_draw(self, _widget, cr):
        if not self.trail:
            self.reset()
        if self.trail:
            cr.set_source_surface(self.trail, 0, 0)
            cr.get_source().set_filter(cairo.FILTER_NEAREST)
            cr.paint()
        return True


def hyprlock_running():
    for pid in os.listdir("/proc"):
        if pid.isdigit():
            try:
                with open(f"/proc/{pid}/comm") as f:
                    if f.read().strip() == "hyprlock":
                        return True
            except OSError:
                pass
    return False


def hypr(cmd):
    """Ask Hyprland over its socket (cheaper than running hyprctl)."""
    import json
    import socket
    path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                        os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket.sock")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(1)
        s.connect(path)
        s.sendall(cmd.encode())
        data = b""
        while chunk := s.recv(65536):
            data += chunk
    return json.loads(data)


def main():
    colours = theme_colours()
    display = Gdk.Display.get_default()
    windows = {}

    def sync(*_):
        current = [display.get_monitor(i) for i in range(display.get_n_monitors())]
        for mon in list(windows):
            if mon not in current:
                windows.pop(mon).destroy()
        for mon in current:
            if mon not in windows:
                windows[mon] = Rain(mon, colours)

    display.connect("monitor-added", sync)
    display.connect("monitor-removed", sync)
    sync()

    hidden = set()  # monitors where nobody can see the rain

    def check_hidden():
        """Every 2 s: skip monitors that are off, locked, or showing a fullscreen window."""
        hidden.clear()
        try:
            mons = hypr("j/monitors")
            full = {w["id"] for w in hypr("j/workspaces") if w.get("hasfullscreen")}
            locked = hyprlock_running()
        except (OSError, ValueError):
            return True
        for gmon in windows:
            g = gmon.get_geometry()
            for m in mons:
                if (m["x"], m["y"]) == (g.x, g.y) and (
                        locked or not m.get("dpmsStatus", True)
                        or m["activeWorkspace"]["id"] in full):
                    hidden.add(gmon)
        return True

    def tick():
        for mon, win in windows.items():
            if mon not in hidden:
                win.step()
        return True

    check_hidden()
    GLib.timeout_add_seconds(2, check_hidden)

    GLib.timeout_add(1000 // FPS, tick)
    Gtk.main()


if __name__ == "__main__":
    main()
