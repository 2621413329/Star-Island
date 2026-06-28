# Cursor Game System Context

本文件是 Cursor 修改岛屿、建筑、装饰、角色、动画、相机前必须读的上下文。

## 核心链路

```text
IslandHomePage
  -> GrowthWorldViewport
  -> WorldStateCache
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState
  -> WorldScene
  -> Layer
  -> Renderer / Painter
  -> Canvas
```

核心文件：

```text
lib/features/island/island_home_page.dart
lib/island/viewport/growth_world_viewport.dart
lib/world/engine/growth_world_engine.dart
lib/world/engine/world_state.dart
lib/world/scene/world_scene.dart
```

## WorldState

`WorldState` 是渲染快照。

包含：

```text
island
characters
buildings
flora
environment
companionGender
```

不要在 layer/renderer 中重新读取 provider 或 repository。

## Layer 顺序

典型顺序：

```text
SkyLayer
OceanLayer
IslandLayer
GrassForegroundLayer
DecorLayer
BuildingLayer
CharacterLayer
HUD / Flutter Overlay
```

规则：

- 背景先画。
- 岛体和地面在中层。
- 装饰、建筑、角色按遮挡关系排序。
- HUD 和气泡属于 Flutter overlay，不写进底层 renderer。

## Y 排序

```text
y 越大 -> 越靠前 -> 越晚绘制
y 越小 -> 越靠后 -> 越早绘制
```

适用：

- 建筑。
- 装饰。
- 角色。
- 前景草。

不要随意用固定数组顺序替代 Y 排序。

## 岛屿

核心文件：

```text
lib/world/island/island_renderer.dart
lib/world/island/island_visual_config.dart
lib/world/island/island_placement.dart
lib/world/island/island_shape_profile.dart
lib/world/island/growth_world_ground_painter.dart
lib/world/island/realistic_lawn_renderer.dart
```

不要为了新增建筑或装饰直接改 `island_renderer.dart`。

## 建筑

新增建筑应该走：

```text
Asset
  -> BuildingConfig
  -> BuildingFactory
  -> BuildingResolver / BuildingSystem
  -> Unlock rule
  -> BuildingLayer
```

优先文件：

```text
lib/island/config/building_config.dart
lib/island/building/
lib/island/service/building_resolver.dart
lib/world/systems/building_system.dart
lib/world/scene/layers/building_layer.dart
lib/common/island_contracts/building_config.dart
lib/common/island_contracts/building_factory.dart
```

不要直接修改：

```text
IslandRenderer
IslandGround
Camera
CharacterLayer
DecorLayer
```

## 装饰 Decor

新增装饰应该走：

```text
Asset
  -> DecorConfig
  -> DecorPlacementResolver
  -> DecorScaleResolver
  -> DecorManager
  -> DecorLayer
```

优先文件：

```text
lib/island/decor/decor_config.dart
lib/island/decor/decor_placement_resolver.dart
lib/island/decor/decor_scale_resolver.dart
lib/island/decor/decor_manager.dart
lib/world/scene/layers/decor_layer.dart
lib/world/scene/layers/grass_foreground_layer.dart
lib/common/island_contracts/decor_config.dart
```

不要直接修改：

```text
WorldScene
Camera
IslandRenderer
GrowthWorldEngine
```

## 角色

角色链路：

```text
GrowthWorldEngine
  -> CharacterSnapshot
  -> CharacterLayer
  -> CompanionPictureCache
  -> CompanionPainter / CozyHeroRenderer
```

优先文件：

```text
lib/world/scene/layers/character_layer.dart
lib/world/rendering/cozy_hero_renderer.dart
lib/world/rendering/companion_picture_cache.dart
lib/design_system/companion_painter.dart
lib/design_system/user_companion_view.dart
lib/world/behaviors/protagonist_behavior.dart
```

新增人物样式不要修改：

```text
Camera
IslandRenderer
BuildingLayer
DecorLayer
```

## 相机

相机相关由 `GrowthWorldViewport` / `WorldScene` 处理：

```text
zoom
rotationRadians
previewZoom
resetIslandView
setIslandViewTransform
```

新增建筑、装饰、人物时不要改相机。

## 环境系统

核心文件：

```text
lib/world/systems/mood_environment_controller.dart
lib/world/systems/config/day_phase_lighting_config.dart
lib/world/systems/config/mood_atmosphere_config.dart
lib/world/systems/config/weather_atmosphere_config.dart
```

天气 API 不放在 world system；world system 只接收天气输入并计算视觉环境。

## 性能规则

优先使用：

```text
WorldStateCache
CompanionPictureCache
Picture cache
Renderer helper
```

禁止：

```text
每帧读取 provider
每帧请求 API
每帧访问 SharedPreferences
每帧重新加载图片资源
```

## 修改前判断

新增建筑：改 config/factory/resolver/layer。

新增装饰：改 decor config/resolver/manager/layer。

新增人物外观：改 companion painter/renderer/character layer。

新增天气视觉：改 weather atmosphere config / environment controller / layer tint。

新增 HUD：改 feature island widget，不改 renderer。
