#!/usr/bin/env python3
"""Draw an original 8-bit home computer wallpaper in P1 phosphor green.

Pixel art at 320x180, scaled 8x with nearest neighbour to 2560x1440, plus faint scanlines.
Usage: make-8bit.py OUTPUT.png
"""
import random
import sys

from PIL import Image, ImageDraw

W, H, SCALE = 320, 180, 8

# P1 phosphor green at different drive levels, matching colors.toml
BG =     (6, 13, 6)       # background: dark CRT glass
DARK =   (9, 30, 9)       # phosphor at  7%: case and bezel fill
SEL =    (14, 57, 14)     # phosphor at 18%: faint lines, keys
BROWN =  (23, 105, 23)    # phosphor at 38%: grid, outlines
MUTED =  (28, 129, 28)    # phosphor at 48%: muted
GREEN =  (51, 255, 51)    # full P1 green #33FF33
LIGHT =  (91, 255, 91)    # slight bloom
BRIGHT = (154, 255, 154)  # strong bloom: cursor, trail heads

# 5x7 pixel font, only the characters used on the screen
FONT = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "G": ["01110", "10001", "10000", "10111", "10001", "10001", "01111"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "01100", "01100"],
    '"': ["01010", "01010", "00000", "00000", "00000", "00000", "00000"],
    " ": ["00000"] * 7,
    # Cyrillic (А, В, Е, Р look like A, B, E, P)
    "А": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "В": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "Е": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "Р": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "П": ["11111", "10001", "10001", "10001", "10001", "10001", "10001"],
    "Ц": ["10010", "10010", "10010", "10010", "10010", "11111", "00001"],
    "#": ["11111"] * 7,  # cursor block
}

SCREEN_TEXT = [
    ("ПРАВЕЦ 82", LIGHT),
    ("48K RAM SYSTEM", MUTED),   # the Pravetz 82 had 48 KB
    ("", GREEN),
    ("READY.", GREEN),
    ('10 PRINT "HELLO"', GREEN),
    ("20 GOTO 10", GREEN),
    ("RUN", GREEN),
    ("HELLO", GREEN),
]


def text(px, x, y, s, colour):
    for i, ch in enumerate(s):
        for r, row in enumerate(FONT[ch]):
            for c, bit in enumerate(row):
                if bit == "1":
                    px[x + i * 6 + c, y + r] = colour


def main(out):
    random.seed(8)
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    px = img.load()

    HORIZON = 121
    VX = W // 2

    def free(x, y):
        """Sky pixels not behind the monitor or the disk drive."""
        return not (94 <= x <= 226 and 10 <= y <= 120) and not (232 <= x <= 300 and 88 <= y <= 120)

    # --- sky: circuit traces with right-angle bends and pads ---
    for _ in range(26):
        x, y = random.randrange(4, W - 4), random.randrange(4, HORIZON - 8)
        colour = random.choice([SEL, SEL, BROWN])
        dx, dy = random.choice([(1, 0), (-1, 0), (0, 1), (0, -1)])
        for _seg in range(random.randint(2, 5)):
            for _step in range(random.randint(6, 30)):
                if not (2 <= x < W - 2 and 2 <= y < HORIZON - 4) or not free(x, y):
                    break
                px[x, y] = colour
                x, y = x + dx, y + dy
            dx, dy = (dy, dx) if random.random() < 0.5 else (-dy, -dx)   # turn 90 degrees
        if 3 <= x < W - 3 and 3 <= y < HORIZON - 4 and free(x, y):
            d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=MUTED)        # pad at the end
            px[x, y] = GREEN

    # --- floor: perspective grid toward a vanishing point on the horizon ---
    for k in range(-14, 15):                                             # lines to the horizon
        d.line([VX, HORIZON, VX + k * 36, H - 1], fill=SEL)
    gap = 1
    y = HORIZON + 1
    while y < H:                                                         # rows, wider apart up close
        d.line([0, y, W - 1, y], fill=SEL if y < HORIZON + 14 else BROWN)
        y += gap
        gap += 1
    # horizon glow
    d.line([0, HORIZON - 2, W - 1, HORIZON - 2], fill=SEL)
    d.line([0, HORIZON - 1, W - 1, HORIZON - 1], fill=MUTED)
    d.line([0, HORIZON, W - 1, HORIZON], fill=GREEN)

    # --- two light trails racing along the grid ---
    # far trail, left of the keyboard, heading right
    ty = HORIZON + 1 + sum(range(1, 3))
    d.line([0, ty, 30, ty], fill=MUTED)
    d.line([12, ty, 30, ty], fill=GREEN)
    d.rectangle([31, ty - 1, 32, ty + 1], fill=BRIGHT)
    # near trail, in front of everything, heading left
    ty2 = HORIZON + 1 + sum(range(1, 11))
    d.line([W - 1, ty2, 190, ty2], fill=MUTED)
    d.line([W - 60, ty2, 190, ty2], fill=GREEN)
    d.rectangle([186, ty2 - 1, 189, ty2 + 1], fill=BRIGHT)

    # --- monitor ---
    d.rectangle([98, 14, 222, 116], fill=DARK, outline=MUTED)           # case
    d.rectangle([99, 15, 221, 16], fill=BROWN)                           # top highlight
    d.rectangle([106, 21, 214, 101], fill=SEL)                           # bezel
    d.rectangle([108, 23, 212, 99], fill=BG)                             # glass
    for y in range(23, 100, 2):                                          # scanlines on the glass
        d.line([108, y, 212, y], fill=(4, 6, 4))
    for i, (line, colour) in enumerate(SCREEN_TEXT):
        text(px, 111, 25 + i * 8, line, colour)
    text(px, 111, 25 + len(SCREEN_TEXT) * 8, "#", BRIGHT)                 # cursor
    d.rectangle([108 + 0, 23, 108 + 1, 24], fill=SEL)                    # rounded glass corners
    d.rectangle([211, 23, 212, 24], fill=SEL)
    d.rectangle([108, 98, 109, 99], fill=SEL)
    d.rectangle([211, 98, 212, 99], fill=SEL)
    d.rectangle([200, 106, 214, 108], fill=SEL)                          # brand plate
    d.rectangle([110, 106, 112, 108], fill=GREEN)                        # power LED
    for x in range(150, 196, 3):                                         # vents
        d.line([x, 105, x, 110], fill=SEL)

    # stand
    d.rectangle([146, 117, 174, 121], fill=SEL, outline=BROWN)

    # --- keyboard / computer base ---
    d.polygon([(76, 150), (86, 124), (234, 124), (244, 150)], fill=DARK, outline=MUTED)
    d.line([87, 125, 233, 125], fill=BROWN)
    rows = [(128, 92, 14), (134, 95, 13), (140, 98, 12)]
    for y, x0, n in rows:
        for k in range(n):
            x = x0 + k * 10
            d.rectangle([x, y, x + 7, y + 4], fill=SEL, outline=BROWN)
            px[x + 1, y + 1] = MUTED
    d.rectangle([120, 146, 200, 148], fill=SEL, outline=BROWN)           # space bar
    d.rectangle([222, 140, 230, 144], fill=SEL, outline=BROWN)           # return key
    px[223, 141] = GREEN

    # --- disk drive ---
    d.rectangle([236, 92, 296, 116], fill=DARK, outline=MUTED)
    d.rectangle([242, 100, 282, 102], fill=BG)                           # slot
    d.rectangle([258, 103, 266, 104], fill=SEL)                          # latch
    d.rectangle([288, 98, 290, 100], fill=GREEN)                         # busy LED
    d.line([237, 93, 295, 93], fill=BROWN)
    # cable from drive to computer
    for x in range(236, 246):
        px[x, 120 + (x - 236) // 3] = BROWN

    # --- floppy disk on the desk ---
    d.rectangle([40, 132, 62, 151], fill=SEL, outline=MUTED)
    d.rectangle([45, 132, 57, 138], fill=BROWN)                          # shutter
    d.rectangle([44, 142, 58, 150], fill=LIGHT)                          # label
    d.line([46, 145, 56, 145], fill=MUTED)
    d.line([46, 147, 53, 147], fill=MUTED)

    # --- joystick ---
    d.rectangle([262, 140, 284, 151], fill=DARK, outline=MUTED)
    d.rectangle([272, 128, 274, 140], fill=MUTED)
    d.rectangle([270, 124, 276, 129], fill=GREEN)
    d.rectangle([265, 143, 267, 145], fill=LIGHT)                        # fire button


    big = img.resize((W * SCALE, H * SCALE), Image.NEAREST)
    # faint CRT scanlines: darken the last row of every scaled pixel row
    bp = big.load()
    for y in range(SCALE - 1, H * SCALE, SCALE):
        for x in range(W * SCALE):
            r, g, b = bp[x, y]
            bp[x, y] = (r * 3 // 4, g * 3 // 4, b * 3 // 4)
    big.save(out, optimize=True)


if __name__ == "__main__":
    main(sys.argv[1])
