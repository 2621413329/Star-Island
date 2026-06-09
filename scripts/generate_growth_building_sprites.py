from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "stday"
OUT = ROOT / "assets" / "images" / "buildings"
DECOR_OUT = ROOT / "assets" / "images" / "decor"


def _chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


class Canvas:
    def __init__(self, w: int = 192, h: int = 192):
        self.w = w
        self.h = h
        self.px = [(0, 0, 0, 0)] * (w * h)

    def save(self, path: Path) -> None:
        rows = []
        for y in range(self.h):
            row = bytearray([0])
            for x in range(self.w):
                row.extend(self.px[y * self.w + x])
            rows.append(bytes(row))
        raw = b"".join(rows)
        png = (
            b"\x89PNG\r\n\x1a\n"
            + _chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
            + _chunk(b"IDAT", zlib.compress(raw, 9))
            + _chunk(b"IEND", b"")
        )
        path.write_bytes(png)

    def blend(self, x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        sr, sg, sb, sa = color
        if sa <= 0:
            return
        idx = y * self.w + x
        dr, dg, db, da = self.px[idx]
        a = sa / 255
        inv = 1 - a
        out_a = sa + da * inv
        if out_a <= 0:
            self.px[idx] = (0, 0, 0, 0)
            return
        self.px[idx] = (
            int(sr * a + dr * inv),
            int(sg * a + dg * inv),
            int(sb * a + db * inv),
            int(out_a),
        )

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, color):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    self.blend(x, y, color)

    def rect(self, x0: float, y0: float, x1: float, y1: float, color):
        for y in range(int(y0), int(y1)):
            for x in range(int(x0), int(x1)):
                self.blend(x, y, color)

    def gradient_rect(self, x0: float, y0: float, x1: float, y1: float, top, bottom):
        y0i = int(y0)
        y1i = int(y1)
        span = max(1, y1i - y0i)
        for y in range(y0i, y1i):
            t = (y - y0i) / span
            color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
            for x in range(int(x0), int(x1)):
                self.blend(x, y, color)

    def line(self, x0: float, y0: float, x1: float, y1: float, color, width: int = 1):
        dx = x1 - x0
        dy = y1 - y0
        steps = int(max(abs(dx), abs(dy), 1))
        radius = max(0, width // 2)
        for i in range(steps + 1):
            t = i / steps
            x = int(round(x0 + dx * t))
            y = int(round(y0 + dy * t))
            for yy in range(y - radius, y + radius + 1):
                for xx in range(x - radius, x + radius + 1):
                    self.blend(xx, yy, color)

    def rect_outline(self, x0: float, y0: float, x1: float, y1: float, color, width: int = 1):
        self.line(x0, y0, x1, y0, color, width)
        self.line(x1, y0, x1, y1, color, width)
        self.line(x1, y1, x0, y1, color, width)
        self.line(x0, y1, x0, y0, color, width)

    def poly(self, pts, color):
        min_y = max(0, int(min(p[1] for p in pts)))
        max_y = min(self.h - 1, int(max(p[1] for p in pts)) + 1)
        for y in range(min_y, max_y + 1):
            xs = []
            for i, p in enumerate(pts):
                q = pts[(i + 1) % len(pts)]
                if (p[1] <= y < q[1]) or (q[1] <= y < p[1]):
                    t = (y - p[1]) / (q[1] - p[1])
                    xs.append(p[0] + t * (q[0] - p[0]))
            xs.sort()
            for a, b in zip(xs[0::2], xs[1::2]):
                for x in range(int(a), int(b) + 1):
                    self.blend(x, y, color)


def draw_base(c: Canvas):
    c.ellipse(96, 160, 54, 13, (35, 70, 75, 30))
    c.ellipse(96, 157, 42, 8, (255, 255, 255, 18))


def house(path: Path, level: int = 1):
    c = Canvas()
    draw_base(c)
    w = 58 + level * 10
    h = 42 + level * 6
    left = 96 - w / 2
    right = 96 + w / 2
    top = 130 - h
    c.ellipse(96, 135, w * 0.62, 12, (35, 70, 75, 26))
    c.gradient_rect(left, top, right, 130, (255, 244, 224, 248), (226, 205, 178, 248))
    c.rect_outline(left, top, right, 130, (138, 113, 91, 100), 2)
    c.poly([(left - 10, top + 3), (96, top - 34), (right + 10, top + 3)], (112, 80, 62, 246))
    c.poly([(left - 3, top + 6), (96, top - 25), (right + 3, top + 6)], (148, 104, 75, 220))
    c.line(left + 6, top + 8, right - 6, top + 8, (255, 240, 206, 75), 2)
    c.gradient_rect(88, 111, 104, 130, (219, 172, 102, 236), (160, 108, 68, 236))
    c.rect_outline(88, 111, 104, 130, (99, 72, 56, 130), 1)
    c.ellipse(101, 120, 1.6, 1.6, (255, 230, 157, 220))
    for x in (72, 120):
        c.gradient_rect(x, 94, x + 13, 107, (176, 224, 206, 225), (103, 157, 160, 225))
        c.rect_outline(x, 94, x + 13, 107, (82, 111, 112, 120), 1)
        c.line(x + 6, 95, x + 6, 106, (255, 255, 255, 80), 1)
    if level >= 2:
        c.rect(64, 78, 75, 91, (236, 223, 202, 232))
        c.poly([(61, 78), (69, 67), (78, 78)], (112, 80, 62, 230))
        c.ellipse(126, 114, 8, 5, (244, 178, 204, 190))
    c.save(path)


def stone(path: Path):
    c = Canvas()
    draw_base(c)
    c.ellipse(96, 130, 30, 9, (35, 70, 75, 24))
    c.ellipse(96, 124, 28, 20, (176, 190, 197, 238))
    c.ellipse(93, 121, 21, 14, (207, 218, 222, 210))
    c.ellipse(86, 114, 7, 4, (238, 245, 244, 105))
    c.line(82, 127, 109, 130, (111, 133, 140, 95), 1)
    c.line(99, 108, 105, 119, (111, 133, 140, 75), 1)
    c.save(path)


def tower(path: Path, lighthouse: bool = False):
    c = Canvas()
    draw_base(c)
    c.ellipse(96, 140, 24, 7, (35, 70, 75, 26))
    c.poly([(83, 70), (109, 70), (114, 138), (78, 138)], (210, 218, 215, 245))
    c.poly([(89, 73), (105, 73), (108, 136), (86, 136)], (244, 248, 239, 238))
    c.rect_outline(82, 70, 110, 138, (101, 121, 124, 95), 1)
    c.poly([(79, 70), (96, 44), (113, 70)], (122, 87, 68, 245))
    c.poly([(86, 69), (96, 53), (106, 69)], (160, 113, 80, 225))
    c.gradient_rect(90, 78, 102, 92, (168, 214, 213, 220), (103, 153, 163, 220))
    c.rect_outline(90, 78, 102, 92, (80, 105, 112, 110), 1)
    for y in (102, 119):
        c.line(84, y, 108, y, (155, 169, 164, 92), 1)
    if lighthouse:
        c.ellipse(96, 50, 30, 13, (255, 244, 181, 100))
        c.ellipse(96, 50, 44, 17, (255, 244, 181, 42))
        c.gradient_rect(86, 48, 106, 61, (236, 248, 246, 245), (175, 205, 207, 245))
        c.line(80, 55, 112, 55, (255, 238, 166, 125), 2)
    c.save(path)


def plaza(path: Path):
    c = Canvas()
    draw_base(c)
    c.ellipse(96, 132, 52, 20, (178, 157, 130, 96))
    c.ellipse(96, 126, 48, 18, (224, 213, 193, 235))
    c.ellipse(96, 123, 34, 10, (239, 231, 212, 130))
    c.line(54, 126, 138, 126, (150, 125, 104, 80), 1)
    c.line(96, 109, 96, 143, (150, 125, 104, 65), 1)
    c.ellipse(96, 119, 13, 22, (174, 198, 206, 225))
    c.ellipse(96, 114, 9, 14, (213, 232, 232, 160))
    c.ellipse(96, 106, 8, 8, (235, 198, 119, 218))
    c.ellipse(96, 104, 14, 11, (255, 238, 169, 52))
    c.save(path)


def small(path: Path, kind: str):
    c = Canvas()
    draw_base(c)
    if kind == "pier":
        for i in range(4):
            y = 116 + i * 9
            c.gradient_rect(50, y, 142, y + 5, (151, 110, 75, 228), (96, 72, 54, 228))
            c.line(53, y + 1, 139, y + 1, (229, 187, 128, 65), 1)
        for x in (58, 132):
            c.gradient_rect(x, 108, x + 6, 154, (121, 89, 62, 225), (74, 58, 47, 225))
    elif kind == "tent":
        c.poly([(58, 138), (96, 82), (134, 138)], (238, 221, 190, 240))
        c.poly([(96, 82), (134, 138), (110, 138)], (196, 151, 118, 230))
        c.line(96, 83, 96, 138, (125, 91, 72, 95), 1)
        c.line(62, 137, 130, 137, (255, 247, 224, 80), 2)
    elif kind == "flowerbed":
        c.ellipse(96, 132, 45, 16, (84, 138, 78, 220))
        c.ellipse(96, 126, 37, 11, (126, 185, 101, 190))
        for i in range(13):
            a = i * math.pi * 2 / 9
            c.ellipse(96 + math.cos(a) * 25, 127 + math.sin(a) * 7, 4, 4, (244, 178, 204, 225))
            c.ellipse(96 + math.cos(a) * 14, 126 + math.sin(a) * 4, 3, 3, (255, 232, 158, 210))
    elif kind == "mailbox":
        c.gradient_rect(90, 102, 96, 138, (137, 99, 69, 236), (89, 66, 52, 236))
        c.gradient_rect(78, 88, 118, 109, (242, 218, 176, 245), (194, 149, 103, 245))
        c.ellipse(98, 88, 20, 12, (242, 218, 176, 245))
        c.rect_outline(78, 89, 118, 109, (114, 82, 60, 100), 1)
        c.line(108, 92, 116, 88, (214, 85, 76, 220), 2)
    else:
        c.gradient_rect(70, 104, 122, 138, (241, 235, 214, 242), (211, 201, 180, 242))
        c.rect_outline(70, 104, 122, 138, (118, 111, 94, 90), 1)
        c.poly([(64, 104), (96, 76), (128, 104)], (112, 137, 99, 238))
        c.poly([(76, 104), (96, 86), (116, 104)], (145, 168, 118, 208))
        c.gradient_rect(88, 117, 104, 138, (205, 158, 89, 220), (144, 96, 62, 220))
        c.gradient_rect(111, 112, 121, 124, (166, 207, 193, 200), (97, 144, 151, 200))
    c.save(path)


def academy(path: Path):
    c = Canvas()
    draw_base(c)
    c.ellipse(96, 143, 62, 12, (35, 70, 75, 28))
    c.gradient_rect(44, 91, 148, 140, (245, 236, 219, 248), (211, 198, 178, 248))
    c.rect_outline(44, 91, 148, 140, (118, 105, 89, 90), 2)
    c.poly([(36, 91), (96, 54), (156, 91)], (112, 84, 62, 248))
    c.poly([(49, 90), (96, 63), (143, 90)], (156, 112, 78, 220))
    for x in (66, 90, 114):
        c.gradient_rect(x, 108, x + 12, 136, (162, 200, 167, 224), (94, 138, 122, 224))
        c.rect_outline(x, 108, x + 12, 136, (71, 101, 89, 100), 1)
    c.ellipse(96, 76, 9, 9, (235, 198, 119, 224))
    c.ellipse(96, 76, 17, 13, (255, 238, 169, 35))
    c.line(56, 100, 136, 100, (255, 250, 230, 80), 2)
    c.save(path)


def observatory(path: Path):
    c = Canvas()
    draw_base(c)
    c.gradient_rect(70, 108, 122, 140, (232, 227, 214, 244), (199, 190, 174, 244))
    c.rect_outline(70, 108, 122, 140, (111, 105, 94, 90), 1)
    c.ellipse(96, 101, 35, 22, (183, 205, 211, 235))
    c.ellipse(96, 95, 26, 13, (225, 239, 240, 120))
    c.line(75, 103, 117, 92, (102, 137, 150, 130), 2)
    c.line(96, 79, 96, 58, (126, 138, 152, 160), 2)
    c.ellipse(96, 56, 5, 5, (255, 238, 169, 180))
    c.save(path)


def decor_grass(path: Path):
    c = Canvas(64, 64)
    c.ellipse(32, 54, 22, 5, (35, 70, 75, 16))
    for i in range(13):
        x = 8 + i * 4
        h = 9 + (i % 4) * 4
        c.poly([(x, 54), (x + 2, 54 - h), (x + 4, 54)], (83, 163, 91, 185))
        if i % 3 == 0:
            c.line(x + 2, 54, x + 2, 54 - h + 2, (184, 219, 145, 90), 1)
    c.save(path)


def decor_flower(path: Path):
    c = Canvas(64, 64)
    c.ellipse(32, 55, 20, 4, (35, 70, 75, 14))
    colors = [(244, 178, 204, 220), (255, 213, 128, 220), (174, 213, 129, 190)]
    for i in range(7):
        x = 10 + i * 7
        y = 38 + (i % 3) * 2
        c.rect(x, 43, x + 2, 55, (82, 155, 90, 160))
        c.ellipse(x + 1, y, 4, 4, colors[i % len(colors)])
        c.ellipse(x + 1, y, 1.5, 1.5, (255, 248, 225, 225))
    c.save(path)


def decor_tree(path: Path, pine: bool = False):
    c = Canvas(96, 96)
    c.ellipse(48, 82, 18, 5, (35, 70, 75, 24))
    c.gradient_rect(43, 48, 52, 82, (139, 98, 67, 225), (88, 65, 49, 225))
    if pine:
        for y, w in [(30, 44), (44, 56), (58, 66)]:
            c.poly([(48, y), (48 - w / 2, y + 24), (48 + w / 2, y + 24)], (78, 151, 84, 225))
            c.line(48, y + 5, 48, y + 23, (180, 220, 150, 70), 1)
    else:
        for x, y, r in [(38, 35, 18), (56, 36, 19), (46, 25, 17), (48, 48, 22)]:
            c.ellipse(x, y, r, r * 0.82, (101, 171, 98, 220))
            c.ellipse(x - 5, y - 4, r * 0.45, r * 0.28, (187, 222, 152, 55))
    c.save(path)


def decor_rock(path: Path):
    c = Canvas(64, 64)
    c.ellipse(32, 46, 18, 6, (35, 70, 75, 24))
    c.ellipse(31, 38, 18, 11, (154, 170, 174, 225))
    c.ellipse(25, 34, 6, 3, (236, 244, 245, 70))
    c.line(22, 41, 43, 43, (96, 119, 125, 75), 1)
    c.save(path)


def decor_cloud(path: Path):
    c = Canvas(96, 64)
    c.ellipse(28, 34, 18, 9, (255, 255, 255, 105))
    c.ellipse(46, 29, 24, 12, (255, 255, 255, 125))
    c.ellipse(66, 35, 18, 9, (255, 255, 255, 100))
    c.ellipse(49, 42, 38, 7, (117, 168, 178, 30))
    c.save(path)


def decor_stream(path: Path):
    c = Canvas(96, 64)
    c.ellipse(48, 42, 42, 8, (35, 70, 75, 18))
    c.line(12, 38, 32, 32, (112, 190, 205, 150), 5)
    c.line(32, 32, 58, 40, (112, 190, 205, 160), 5)
    c.line(58, 40, 84, 33, (112, 190, 205, 150), 5)
    c.line(18, 36, 80, 36, (232, 250, 250, 80), 1)
    c.save(path)


def decor_fence(path: Path):
    c = Canvas(96, 64)
    c.ellipse(48, 52, 38, 5, (35, 70, 75, 16))
    for x in range(18, 80, 12):
        c.gradient_rect(x, 31, x + 5, 54, (184, 139, 91, 220), (106, 78, 58, 220))
    c.line(15, 39, 83, 35, (147, 103, 70, 220), 4)
    c.line(15, 48, 83, 44, (147, 103, 70, 210), 4)
    c.save(path)


def decor_bench(path: Path, long: bool = False):
    c = Canvas(96, 64)
    c.ellipse(48, 53, 36 if long else 24, 5, (35, 70, 75, 18))
    w = 68 if long else 46
    x0 = 48 - w / 2
    for y in (34, 43):
        c.gradient_rect(x0, y, x0 + w, y + 5, (166, 116, 73, 225), (99, 70, 52, 225))
    for x in (x0 + 8, x0 + w - 12):
        c.line(x, 47, x - 5, 55, (82, 64, 54, 190), 2)
        c.line(x + 4, 47, x + 9, 55, (82, 64, 54, 190), 2)
    c.save(path)


def decor_lamp(path: Path):
    c = Canvas(64, 96)
    c.ellipse(32, 82, 15, 4, (35, 70, 75, 22))
    c.gradient_rect(30, 35, 34, 82, (96, 111, 118, 220), (54, 65, 72, 220))
    c.ellipse(32, 31, 14, 12, (255, 226, 140, 95))
    c.ellipse(32, 31, 8, 7, (255, 235, 160, 190))
    c.line(23, 38, 41, 38, (70, 78, 82, 210), 2)
    c.save(path)


def decor_bridge(path: Path):
    c = Canvas(96, 64)
    c.ellipse(48, 49, 38, 5, (35, 70, 75, 18))
    c.line(17, 42, 48, 26, (151, 110, 75, 220), 5)
    c.line(48, 26, 79, 42, (151, 110, 75, 220), 5)
    for x in range(28, 72, 10):
        c.line(x, 35, x, 48, (104, 75, 55, 180), 2)
    c.save(path)


def decor_birds(path: Path):
    c = Canvas(96, 64)
    for x, y, s in [(24, 31, 1.0), (46, 24, 0.8), (68, 34, 0.9)]:
        c.line(x - 7 * s, y, x, y - 4 * s, (67, 84, 94, 170), 2)
        c.line(x, y - 4 * s, x + 7 * s, y, (67, 84, 94, 170), 2)
    c.save(path)


def decor_hill(path: Path):
    c = Canvas(96, 64)
    c.ellipse(48, 49, 42, 15, (108, 169, 112, 130))
    c.ellipse(64, 45, 27, 11, (141, 190, 132, 110))
    c.line(14, 48, 82, 48, (255, 255, 255, 35), 1)
    c.save(path)


def generate_decor():
    DECOR_OUT.mkdir(parents=True, exist_ok=True)
    for name in [
        "grass.png",
        "footprint_grass.png",
        "lawn_ring.png",
        "reed_edge.png",
        "garden_path.png",
    ]:
        decor_grass(DECOR_OUT / name)
    for name in [
        "tiny_flower.png",
        "flower_group_a.png",
        "firefly_dot.png",
        "flower_line.png",
        "book_flowerbed.png",
        "courtyard_flower.png",
    ]:
        decor_flower(DECOR_OUT / name)
    for name in [
        "guardian_tree.png",
        "tree_cluster_west.png",
        "roadside_tree.png",
        "dense_tree_back.png",
        "tall_tree.png",
        "large_canopy.png",
        "full_ecology_pack.png",
    ]:
        decor_tree(DECOR_OUT / name, pine="pine" in name or "tall" in name)
    for name in [
        "small_stone.png",
        "bush_low.png",
        "shore_rock.png",
        "stone_step_ring.png",
    ]:
        decor_rock(DECOR_OUT / name)
    decor_cloud(DECOR_OUT / "cloud_shadow.png")
    decor_cloud(DECOR_OUT / "cloud_far.png")
    decor_stream(DECOR_OUT / "stream_a.png")
    decor_hill(DECOR_OUT / "far_hill.png")
    decor_fence(DECOR_OUT / "life_area_fence.png")
    decor_fence(DECOR_OUT / "low_fence.png")
    decor_bench(DECOR_OUT / "bench_small.png")
    decor_bench(DECOR_OUT / "long_bench.png", long=True)
    decor_bridge(DECOR_OUT / "bridge_small.png")
    decor_lamp(DECOR_OUT / "lamp_post.png")
    decor_birds(DECOR_OUT / "bird_group.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    stone(OUT / "starter_stone.png")
    house(OUT / "growth_house.png", 1)
    house(OUT / "growth_house_lv2.png", 2)
    tower(OUT / "growth_clocktower.png")
    academy(OUT / "growth_academy.png")
    tower(OUT / "lighthouse.png", True)
    tower(OUT / "lighthouse_base.png", True)
    plaza(OUT / "memory_fountain.png")
    plaza(OUT / "story_plaza.png")
    plaza(OUT / "companion_plaza.png")
    small(OUT / "harbor_pier.png", "pier")
    small(OUT / "record_shed.png", "shed")
    small(OUT / "memory_mailbox.png", "mailbox")
    small(OUT / "emotion_windchime.png", "shed")
    small(OUT / "habit_flowerbed.png", "flowerbed")
    small(OUT / "quiet_tent.png", "tent")
    small(OUT / "library_seed.png", "shed")
    small(OUT / "memory_gallery.png", "shed")
    observatory(OUT / "dream_observatory.png")
    generate_decor()


if __name__ == "__main__":
    main()
