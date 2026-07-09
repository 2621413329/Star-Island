# 副岛（故事岛）美术资源总览

完整世界观见：[stday/docs/STORY_ISLAND_WORLD_SPEC.md](../../docs/STORY_ISLAND_WORLD_SPEC.md)

## 目录结构

```
islands/
  <category_id>/
    buildings/lv01.png … lv10.png
    covers/          # 列表卡封面（可选）
    backgrounds/     # 岛屿背景（可选）
```

## 统一风格 Prompt

```
isometric 45-degree view, hand-painted mobile game art style, low saturation color palette, soft natural lighting, matte materials (wood, stone, brick), painterly texture, clean silhouette, believable proportions, cozy environment, no futuristic elements, mobile game asset
```

## 等级与文件对应

| 等级 | 文件 | 布局位置 |
|------|------|----------|
| Lv1 | lv01.png | 外圈（最小） |
| Lv2–Lv3 | lv02–03 | 外圈 |
| Lv4–Lv6 | lv04–06 | 中圈 |
| Lv7–Lv9 | lv07–09 | 内圈 |
| Lv10 | lv10.png | 中心（地标） |

建筑名称见各分类在 `story_island_building_catalog.dart` 中的列表。
