# Cursor Game System Context

改岛屿、建筑、装饰、角色、动画、相机前读本文件。产品行为见 `docs/CLIENT_SYSTEMS.md`，美术名见 `docs/STORY_ISLAND_WORLD_SPEC.md`。

## 先判断改的是哪条世界

主岛（用户等级、解锁建筑、天气、可缩放旋转）：

```text
IslandHomePage
  -> GrowthWorldViewport
  -> WorldStateCache
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState
  -> WorldScene
  -> Layer
  -> Renderer / Painter
```

副岛和首页群岛（故事岛等级、静态或轻量预览）：

```text
StoryIslandModel
  -> StoryIslandWorldBuilder
  -> features/home/widgets/world_preview_*.dart
  -> 或 features/island/widgets/story_island_static_detail_viewport.dart
```

不要为了副岛去改 `IslandRenderer`、主岛 `island/placement/` 或相机。

核心文件：

```text
lib/features/island/island_home_page.dart
lib/island/viewport/growth_world_viewport.dart
lib/island/viewport/island_view_camera.dart
lib/world/engine/growth_world_engine.dart
lib/world/engine/world_state.dart
lib/world/engine/world_state_v2.dart
lib/world/rendering/world_state_cache.dart
lib/world/scene/world_scene.dart
lib/world/preview/story_island_world_builder.dart
lib/world/preview/world_island_layout.dart
lib/world/preview/world_preview_camera.dart
lib/island/generator/island_generator.dart
```

`IslandGenerator.generate` 返回 `WorldStateV2`。渲染代码按 `WorldState` 读。

## WorldState

渲染快照。字段：

```text
island            shapeKey、style、elevation、prosperityTier、radius
characters
buildings
flora
environment
zones
decorations
paths
effects
anchors           cameraFocus 的锚点会拉动 WorldScene 视口中心
companionGender
schemaVersion
```

layer / renderer 里禁止再读 provider 或 repository。

## Layer 顺序

`WorldScene.onLoad`，非 `islandOnly`：

```text
SkyLayer
CloudLayer
DistantLayer
OceanLayer
IslandLayer
DecorLayer
BuildingLayer
GrassForegroundLayer
CharacterLayer
EffectLayer
UIOverlayLayer
MainIslandDebugOverlayLayer     仅 kDebugMode 且 showDebugOverlay
```

`islandOnly`：岛体、装饰、建筑、角色、调试层。

前景草在建筑之后，用来压住建筑脚。HUD、气泡、陪伴台词是 Flutter overlay。

## Y 排序

地面建筑、装饰、角色用 `SceneDepthPriority.ground(normalizedDy)`：

```text
y 越大 -> priority 越大 -> 越晚绘制 -> 越靠前
```

`groundBase` 是 1200，y 从 0 到 1 再加最多 8000。前景草是固定 9600，始终压过地面物体。天空用 `sky()`（9800 起）。UI 特效 9900。

不要用 children 数组顺序代替地面物体的 y 排序。

## 主岛几何

```text
lib/world/island/island_renderer.dart
lib/world/island/island_visual_config.dart
lib/world/island/island_placement.dart
lib/world/island/island_shape_profile.dart
lib/world/island/growth_world_ground_painter.dart
lib/world/island/realistic_lawn_renderer.dart
lib/island/placement/island_building_layout.dart
lib/island/placement/main_island_placement_zones.dart
lib/island/placement/large_tree_shore_parcels.dart
```

新增建筑或装饰时不要改 `island_renderer.dart`。

## 主岛建筑

```text
Asset
  -> lib/island/config/building_config.dart
  -> lib/island/building/building_factory.dart
  -> lib/island/service/building_resolver.dart
  -> lib/world/systems/building_system.dart
  -> lib/world/scene/layers/building_layer.dart
  -> lib/common/island_contracts/ 对应 export
  -> 解锁：lib/core/growth/island_unlock_catalog.dart
```

不要为此改 `IslandRenderer`、相机、`CharacterLayer`、`DecorLayer`。

## 主岛装饰

```text
Asset
  -> lib/island/decor/decor_config.dart
  -> decor_placement_resolver.dart
  -> decor_scale_resolver.dart
  -> decor_manager.dart
  -> lib/world/scene/layers/decor_layer.dart
  -> grass_foreground_layer.dart
  -> common/island_contracts/decor_*.dart
```

不要为此改 `WorldScene` 的层序、相机、`IslandRenderer`、`GrowthWorldEngine`。

## 副岛建筑

```text
assets/images/islands/<category>/buildings/lv01.png … lv10.png
  -> StoryIslandBuildingCatalog
  -> backend/app/config/story_island_buildings.py     名称必须一致
  -> StoryIslandLayout.buildingAnchor                 只改副岛坐标
  -> StoryIslandWorldBuilder                          把等级映射成 BuildingSnapshot
```

Lv10 在岛心。Lv1–Lv9 三环各 3 座，半径 0.48、0.32、0.18。详情缩放 1.58，小人站位 `(0.50, 0.56)`。这些常量在 `lib/core/constants/story_island_layout.dart`。

每级 30 成长值，满级 300，在 `story_island_size.dart`。这不是用户 Lv1–Lv20。

首页槽位最多主岛加 5 座副岛，坐标在 `world_island_layout.dart` 的 `rank_0` … `rank_4`。

## 角色

```text
GrowthWorldEngine
  -> CharacterSnapshot
  -> CharacterLayer
  -> CompanionPictureCache / companion_asset_resolver.dart
  -> CompanionPainter / CozyHeroRenderer
```

```text
lib/world/scene/layers/character_layer.dart
lib/world/rendering/cozy_hero_renderer.dart
lib/world/rendering/companion_picture_cache.dart
lib/design_system/companion_painter.dart
lib/design_system/user_companion_view.dart
lib/world/behaviors/protagonist_behavior.dart
lib/core/constants/companion_roles.dart
lib/core/models/user_companion.dart
```

新外观不要改相机、`IslandRenderer`、`BuildingLayer`、`DecorLayer`。

## 相机

主岛：`GrowthWorldViewport`、`island_view_camera.dart`、`WorldScene.setViewTransform`。缩放 0.65–5，可旋转。带 `cameraFocus` 的 anchor 会把视口中心拉向该点 0.22 的比例。

首页群岛：`world_preview_camera.dart`。副岛详情缩放是 `StoryIslandLayout.detailViewportScale`，不是主岛相机。

新增建筑、装饰、人物时不要改相机。

## 环境

```text
lib/world/systems/mood_environment_controller.dart
lib/world/systems/config/day_phase_lighting_config.dart
lib/world/systems/config/mood_atmosphere_config.dart
lib/world/systems/config/weather_atmosphere_config.dart
lib/world/systems/prosperity_system.dart
```

天气 HTTP 在 `lib/core/weather/` 与 `islandWeatherProvider`。world 只吃已经准备好的输入。

岛与欢迎页 BGM 的昼夜是 6:00–19:00，和这里的光照 config 是两套参数。改视觉昼夜不要顺手改 BGM 时段，除非需求明确要求对齐。

## 性能

优先用 `WorldStateCache`、`CompanionPictureCache`。禁止在 layer 的每帧里读 provider、打 API、读 SharedPreferences、重新加载图片。

`worldVisualIdentityChanged` 用繁荣度、半径、建筑数、装饰数、角色等级、路径数、特效数判断要不要重绘身份。改快照字段时看这个函数还够不够。

## 修改前判断

| 需求 | 改哪里 |
|---|---|
| 主岛新建筑 | config / factory / resolver / unlock / BuildingLayer |
| 主岛新装饰 | decor config / resolver / manager / DecorLayer |
| 副岛新分类或换建筑图 | catalog、Python 配置、`assets/images/islands/`、pubspec |
| 副岛挪位置 | `StoryIslandLayout` 或 `WorldIslandLayout`，不要动主岛 placement |
| 人物外观 | painter / renderer / CharacterLayer / companion catalog |
| 天气视觉 | weather atmosphere config / environment controller |
| 新 HUD | `features/island` 或 `island/widgets`，不改 renderer |
