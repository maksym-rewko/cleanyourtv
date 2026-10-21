#!/usr/bin/env python3
"""Write a dark gradient wallpaper for the launcher: cool black in one corner, deep blue in the other.

Usage: python3 tools/make-wallpaper.py [--from "#05070C"] [--to "#0A2A5E"] [--out themes/maksym/wallpaper.jpg]

Needs numpy and Pillow (the system python3 has them; tools/venv does not). The picture is 1920x1080, with a
touch of noise so a dark gradient does not show bands on a TV, and the JPEG quality is lowered until the file
is under 300 KB (a 1 GB TV decodes it into memory on every Home start, see themes/README.md).
"""
import argparse
import io
import sys

import numpy as np
from PIL import Image

W, H = 1920, 1080
LIMIT = 300 * 1024


def rgb(hexstr):
    h = hexstr.lstrip("#")
    if len(h) != 6:
        sys.exit(f"colour must be #RRGGBB, got {hexstr!r}")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--from", dest="start", default="#05070C", help="cool black, top-left")
    ap.add_argument("--to", dest="end", default="#0A2A5E", help="deep blue, bottom-right")
    ap.add_argument("--out", default="themes/maksym/wallpaper.jpg")
    ap.add_argument("--noise", type=float, default=1.1, help="dither strength in 8-bit levels")
    args = ap.parse_args()

    a, b = rgb(args.start), rgb(args.end)
    y, x = np.mgrid[0:H, 0:W]
    # Diagonal 0..1, eased so the black holds across the top-left half and the blue builds toward the corner.
    t = (0.35 * x / W + 0.65 * y / H)
    t = np.clip(t, 0, 1) ** 1.6
    img = a[None, None, :] + (b - a)[None, None, :] * t[:, :, None]
    img += np.random.default_rng(7).normal(0, args.noise, img.shape)
    pic = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))

    for q in range(92, 40, -4):
        buf = io.BytesIO()
        pic.save(buf, "JPEG", quality=q, subsampling=0)
        if buf.tell() <= LIMIT:
            break
    open(args.out, "wb").write(buf.getvalue())
    print(f"{args.out}: {W}x{H}, quality {q}, {buf.tell() // 1024} KB")


if __name__ == "__main__":
    main()
