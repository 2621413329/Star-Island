#!/usr/bin/env python3
"""程序化生成 Growth Island cozy 风格 GLB 占位模型。

用法:
  pip install trimesh numpy
  python scripts/generate_island_glb.py

输出目录: stday/assets/3d/models/
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "stday" / "assets" / "3d" / "models"

WHITE = [248, 248, 248, 255]
SOFT_WHITE = [236, 236, 236, 255]
GREEN = [102, 187, 106, 255]
GREEN_DARK = [67, 160, 71, 255]
BROWN = [121, 85, 72, 255]
GRAY = [144, 164, 174, 255]
GRASS = [126, 200, 122, 255]
SAND = [232, 224, 212, 255]
SEA = [91, 181, 213, 255]


def _paint(mesh: trimesh.Trimesh, rgba: list[int]) -> trimesh.Trimesh:
    mesh = mesh.copy()
    mesh.visual.vertex_colors = np.tile(rgba, (len(mesh.vertices), 1)).astype(np.uint8)
    return mesh


def _export(scene: trimesh.Scene, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    scene.export(path)
    size_kb = path.stat().st_size / 1024
    print(f"  wrote {path.relative_to(ROOT)} ({size_kb:.1f} KB)")


def build_hero() -> trimesh.Scene:
    """白色 marshmallow 小人（低多边形）。"""
    scene = trimesh.Scene()

    body = trimesh.creation.capsule(radius=0.24, height=0.58, count=[20, 20])
    body.apply_translation([0, 0.38, 0])
    scene.add_geometry(_paint(body, WHITE), geom_name="body")

    head = trimesh.creation.icosphere(subdivisions=3, radius=0.27)
    head.apply_translation([0, 0.95, 0])
    scene.add_geometry(_paint(head, SOFT_WHITE), geom_name="head")

    for side, x in [("arm_l", -0.30), ("arm_r", 0.30)]:
        arm = trimesh.creation.icosphere(subdivisions=2, radius=0.085)
        arm.apply_translation([x, 0.48, 0])
        scene.add_geometry(_paint(arm, WHITE), geom_name=side)

    for side, x in [("foot_l", -0.12), ("foot_r", 0.12)]:
        foot = trimesh.creation.box(extents=[0.14, 0.06, 0.18])
        foot.apply_translation([x, 0.03, 0.02])
        scene.add_geometry(_paint(foot, SOFT_WHITE), geom_name=side)

    leaf = trimesh.creation.icosphere(subdivisions=1, radius=0.06)
    leaf.apply_scale([1.2, 0.5, 0.3])
    leaf.apply_translation([0, 0.58, 0.24])
    scene.add_geometry(_paint(leaf, GREEN), geom_name="leaf")

    return scene


def build_tree_pine() -> trimesh.Scene:
    scene = trimesh.Scene()
    trunk = trimesh.creation.cylinder(radius=0.07, height=0.42, sections=12)
    trunk.apply_translation([0, 0.21, 0])
    scene.add_geometry(_paint(trunk, BROWN), geom_name="trunk")

    for i, (y, r, h) in enumerate([(0.55, 0.38, 0.42), (0.82, 0.30, 0.36), (1.05, 0.22, 0.30)]):
        cone = trimesh.creation.cone(radius=r, height=h, sections=16)
        cone.apply_translation([0, y, 0])
        color = GREEN if i == 0 else GREEN_DARK
        scene.add_geometry(_paint(cone, color), geom_name=f"foliage_{i}")
    return scene


def build_tree_puffy() -> trimesh.Scene:
    scene = trimesh.Scene()
    trunk = trimesh.creation.cylinder(radius=0.06, height=0.36, sections=10)
    trunk.apply_translation([0, 0.18, 0])
    scene.add_geometry(_paint(trunk, BROWN), geom_name="trunk")

    clusters = [
        ([0, 0.58, 0], [1.0, 1.0, 1.0], 0.30),
        ([-0.20, 0.50, 0.05], [1.1, 0.85, 0.9], 0.22),
        ([0.18, 0.52, -0.04], [0.95, 1.05, 0.85], 0.20),
        ([0.02, 0.72, 0.02], [1.05, 0.95, 1.0], 0.24),
    ]
    for i, (pos, scale, radius) in enumerate(clusters):
        blob = trimesh.creation.icosphere(subdivisions=2, radius=radius)
        blob.apply_scale(scale)
        blob.apply_translation(pos)
        scene.add_geometry(_paint(blob, GREEN if i % 2 == 0 else GREEN_DARK), geom_name=f"leaf_{i}")
    return scene


def build_rock() -> trimesh.Scene:
    rock = trimesh.creation.icosphere(subdivisions=2, radius=0.22)
    rock.apply_scale([1.2, 0.65, 1.0])
    rock.apply_translation([0, 0.12, 0])
    scene = trimesh.Scene()
    scene.add_geometry(_paint(rock, GRAY), geom_name="rock")
    return scene


def build_island_ground() -> trimesh.Scene:
    scene = trimesh.Scene()
    grass = trimesh.creation.cylinder(radius=4.0, height=0.32, sections=48)
    grass.apply_translation([0, 0.16, 0])
    scene.add_geometry(_paint(grass, GRASS), geom_name="grass")

    rim = trimesh.creation.cylinder(radius=4.18, height=0.20, sections=48)
    rim.apply_translation([0, 0.08, 0])
    scene.add_geometry(_paint(rim, SAND), geom_name="sand_rim")

    sea = trimesh.creation.cylinder(radius=6.5, height=0.06, sections=48)
    sea.apply_translation([0, -0.02, 0])
    scene.add_geometry(_paint(sea, SEA), geom_name="sea_ring")
    return scene


def main() -> None:
    print(f"Generating cozy island GLB assets -> {OUT}")
    _export(build_hero(), "hero.glb")
    _export(build_tree_pine(), "tree_pine.glb")
    _export(build_tree_puffy(), "tree_puffy.glb")
    _export(build_rock(), "rock.glb")
    _export(build_island_ground(), "island_ground.glb")
    print("Done.")


if __name__ == "__main__":
    main()
