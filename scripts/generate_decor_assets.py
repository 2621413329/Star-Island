#!/usr/bin/env python3
"""Generate placeholder PNG assets for the island decor unlock system."""

from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "stday" / "assets" / "images" / "decor"

DECOR_STYLES: dict[str, tuple[tuple[int, int, int, int], tuple[int, int, int, int]]] = {
    "grass": ((72, 140, 72, 255), (48, 100, 48, 255)),
    "flower": ((240, 120, 160, 255), (80, 160, 80, 255)),
    "stone": ((140, 140, 150, 255), (100, 100, 110, 255)),
    "bush": ((60, 120, 60, 255), (40, 90, 40, 255)),
    "tree_small": ((50, 110, 50, 255), (90, 60, 40, 255)),
    "tree_large": ((40, 100, 40, 255), (80, 55, 35, 255)),
    "mushroom": ((220, 80, 80, 255), (240, 230, 210, 255)),
    "wood": ((120, 80, 50, 255), (90, 60, 35, 255)),
    "butterfly": ((255, 200, 80, 255), (180, 100, 220, 255)),
    "cloud": ((255, 255, 255, 220), (230, 240, 255, 200)),
    "flower_field": ((255, 180, 200, 255), (70, 150, 70, 255)),
    "bird": ((60, 60, 80, 255), (200, 200, 210, 255)),
    "pond": ((80, 160, 220, 255), (50, 120, 180, 255)),
    "firefly": ((255, 255, 120, 255), (40, 40, 60, 200)),
    "rare_flower": ((180, 80, 220, 255), (60, 140, 80, 255)),
    "rainbow_cloud": ((255, 180, 180, 220), (180, 220, 255, 220)),
    "seagull_group": ((240, 240, 250, 255), (100, 120, 140, 255)),
    "life_tree": ((30, 160, 80, 255), (120, 80, 40, 255)),
}

ASSETS = [
    "grass_01.png",
    "grass_02.png",
    "grass_03.png",
    "flower_01.png",
    "flower_02.png",
    "flower_03.png",
    "stone_01.png",
    "stone_02.png",
    "bush_01.png",
    "bush_02.png",
    "tree_small_01.png",
    "tree_small_02.png",
    "tree_small_03.png",
    "mushroom_01.png",
    "wood_01.png",
    "butterfly_01.png",
    "tree_large_01.png",
    "cloud_01.png",
    "cloud_02.png",
    "cloud_03.png",
    "flower_field_01.png",
    "bird_01.png",
    "tree_large_02.png",
    "pond_01.png",
    "bird_02.png",
    "bird_03.png",
    "cloud_04.png",
    "firefly_01.png",
    "rare_flower_01.png",
    "rainbow_cloud_01.png",
    "seagull_group_01.png",
    "life_tree_01.png",
]


def _chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def _style_for(name: str) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int]]:
    for key, colors in DECOR_STYLES.items():
        if name.startswith(key):
            return colors
    return ((128, 128, 128, 255), (96, 96, 96, 255))


def _write_png(path: Path, w: int, h: int, top, bottom) -> None:
    px = []
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
        for _ in range(w):
            px.extend(color)
    rows = []
    for y in range(h):
        row = bytearray([0])
        row.extend(px[y * w * 4 : (y + 1) * w * 4])
        rows.append(bytes(row))
    raw = b"".join(rows)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
        + _chunk(b"IDAT", zlib.compress(raw, 9))
        + _chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    for filename in ASSETS:
        stem = filename.replace(".png", "")
        top, bottom = _style_for(stem)
        size = 96 if "life_tree" in stem or "tree_large" in stem else 64
        if "cloud" in stem or "bird" in stem or "butterfly" in stem:
            size = 80
        _write_png(ROOT / filename, size, size, top, bottom)
        print(f"Wrote {ROOT / filename}")


if __name__ == "__main__":
    main()
