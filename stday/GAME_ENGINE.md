# Game Engine Guide

本文用于说明成长小岛的世界、渲染、层级、角色、建筑、装饰、相机和交互。后续 AI 修改岛屿相关代码时必须先读本文。

## 当前定位

项目使用 Flutter/Canvas 风格组织成长岛渲染，并引入 Flame 2D 的项目依赖和游戏式层级思想。

当前核心不是传统 tile map，而是：

```text
WorldState
  -> WorldScene
  -> Layer
  -> Renderer / Painter
  -> Canvas
```

## 核心入口

岛屿首页：

```text
lib/features/island/island_home_page.dart
```

主岛可交互渲染入口：

```text
lib/island/viewport/growth_world_viewport.dart
```

副岛和首页群岛不是这条入口。它们用 `lib/world/preview/story_island_world_builder.dart` 生成快照。详见文末「两条渲染路径」。

世界场景：

```text
lib/world/scene/world_scene.dart
```

世界状态：

```text
lib/world/engine/world_state.dart
```

世界引擎：

```text
lib/world/engine/growth_world_engine.dart
```

## 世界构建流程

```text
IslandHomePage
  -> 读取 profile / moments / growth / weather / building unlocks
  -> GrowthWorldViewport
  -> WorldStateCache
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState
  -> WorldScene
```

`WorldState` 是渲染快照。不要在 layer 内部再读取 provider 或 repository。

## WorldState 内容

```text
WorldState
  island              形状、风格、海拔、prosperityTier、radius
  characters          位置、表情、道具、动作、scale
  buildings           定义 id、等级、锚点、尺寸
  flora
  environment         心情氛围、天气、时段光照
  zones
  decorations
  paths
  effects
  anchors             可带 cameraFocus，WorldScene 用它偏移视口中心
  companionGender
  schemaVersion       默认 1。WorldStateV2 是子类，由 IslandGenerator 产出
```

layer 和 renderer 只读这份快照，不再读 provider 或 repository。

## Layer 顺序

`WorldScene.onLoad` 的非 `islandOnly` 顺序：

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
MainIslandDebugOverlayLayer    仅 debug
```

`islandOnly` 只加岛体、装饰、建筑、角色和调试层。

原则：

- 背景先画。前景草在建筑之后、角色之前，用来压住建筑脚。
- 同层遮挡不要靠数组顺序。`SceneDepthPriority.ground(normalizedDy)`：y 越大 priority 越大，越晚画、越靠前。天空物体用 `SceneDepthPriority.sky`。
- HUD、建筑气泡、陪伴台词是 Flutter overlay，不写进 layer。

## Y 排序

岛屿是伪 2D 透视视觉，很多对象需要按 y 值排序：

```text
y 越大 -> 越靠前 -> 越晚绘制
y 越小 -> 越靠后 -> 越早绘制
```

适用对象：

- 建筑
- 装饰
- 角色
- 可交互的地面物体

前景草使用固定优先级 `SceneDepthPriority.foregroundGrass`（9600），高于地面物体的最大优先级，所以草裙始终压在建筑和角色脚前，不参与 y 比较。天空物体用 `sky()`，UI 特效用 `uiEffects`。

不要用固定数组顺序替代地面物体的 y 排序，除非对象是纯背景或纯 HUD。

## 坐标系统

常见坐标：

- normalized position：岛屿内部归一化位置。
- canvas position：实际绘制坐标。
- screen position：Flutter 交互/Overlay 坐标。

原则：

- 业务数据尽量保存 normalized position 或 id。
- renderer 内部转换成 canvas position。
- Flutter Overlay 使用 screen position。
- 不要把屏幕像素位置保存到业务模型。

## 相机与视图变换

主岛相机由 `GrowthWorldViewport`、`lib/island/viewport/island_view_camera.dart` 和 `WorldScene.setViewTransform` 负责。缩放夹在 0.65 到 5。首页群岛另有 `lib/world/preview/world_preview_camera.dart`，不要和主岛相机混改。

当前相机能力：

```text
zoom
rotationRadians
previewZoom
resetIslandView
setIslandViewTransform
```

规则：

- 新增建筑、装饰、角色时不要修改 Camera。
- 只有新增缩放、旋转、拖拽、视图重置能力时才改相机。
- UI 页面不要直接改 renderer 内部坐标。

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

职责：

- `island_renderer.dart`：岛体、边缘、阴影、水面接触等绘制 facade。
- `island_visual_config.dart`：岛屿视觉基准配置。
- `island_placement.dart`：岛屿几何放置约束。
- `island_shape_profile.dart`：岛屿形状。
- `growth_world_ground_painter.dart`：成长世界地面绘制。
- `realistic_lawn_renderer.dart`：草地细节。

不要为了新增建筑或装饰直接修改 `IslandRenderer`。优先改建筑/装饰配置、layer 或 resolver。

## 建筑

当前相关文件：

```text
lib/world/scene/layers/building_layer.dart
lib/island/building/
lib/island/config/building_config.dart
lib/island/service/building_resolver.dart
lib/common/island_contracts/building_config.dart
lib/common/island_contracts/building_factory.dart
```

建筑数据链路：

```text
GrowthSummary / BuildingUnlocks
  -> BuildingSystem / resolver
  -> BuildingSnapshot
  -> BuildingLayer
  -> renderer/component
```

新增建筑时优先检查：

```text
BuildingConfig
BuildingFactory
BuildingResolver
Unlock rule
Asset path
BuildingLayer display
```

不要直接修改：

```text
IslandRenderer
IslandGround
Camera
CharacterLayer
```

## 装饰 Decor

当前相关文件：

```text
lib/island/decor/decor_config.dart
lib/island/decor/decor_manager.dart
lib/island/decor/decor_placement_resolver.dart
lib/island/decor/decor_scale_resolver.dart
lib/world/scene/layers/decor_layer.dart
lib/world/scene/layers/grass_foreground_layer.dart
lib/common/island_contracts/decor_config.dart
```

新增装饰时优先检查：

```text
DecorConfig
DecorPlacementResolver
DecorScaleResolver
DecorManager
DecorLayer
Asset path
Y sort
```

不要直接修改：

```text
WorldScene
Camera
IslandRenderer
GrowthWorldEngine
```

除非装饰会影响世界状态生成。

## 角色 Character

当前相关文件：

```text
lib/world/scene/layers/character_layer.dart
lib/world/rendering/cozy_hero_renderer.dart
lib/world/rendering/companion_picture_cache.dart
lib/design_system/companion_painter.dart
lib/design_system/user_companion_view.dart
lib/world/behaviors/protagonist_behavior.dart
lib/core/models/user_companion.dart
lib/core/models/character_mood.dart
```

角色链路：

```text
GrowthWorldEngine
  -> CharacterSnapshot
  -> CharacterLayer
  -> CompanionPictureCache
  -> CompanionPainter / CozyHeroRenderer
```

新增人物样式时优先改：

```text
Companion config/catalog
CompanionPainter
CozyHeroRenderer
CharacterLayer presentation
Asset path
```

新增人物行为时优先改：

```text
ProtagonistBehavior
CharacterMotion
GrowthWorldEngine character snapshot
```

不要修改：

```text
Camera
IslandRenderer
BuildingLayer
DecorLayer
```

## 动画

常见动画来源：

- Flutter animation controller。
- WorldScene tick / time。
- Character motion。
- 环境系统的 mood/weather/day phase。
- 轻量 overlay 或 dialog。

规则：

- 动画参数属于视觉行为，重构时不要随意改。
- 性能优化优先用 cache、Picture、减少重复 paint。
- 不要在动画循环里做 API 请求。

## 碰撞与交互

当前交互包括：

- 建筑点击。
- 角色点击。
- 岛屿缩放/旋转。
- 气泡弹出。
- HUD 按钮。

相关文件：

```text
lib/world/behaviors/companion_hit_test.dart
lib/world/scene/island_gesture_surface.dart
lib/world/scene/layers/building_layer.dart
lib/features/island/island_home_page.dart
```

规则：

- hit test 只判断命中，不做业务请求。
- 业务响应在 feature page 或 provider 层处理。
- overlay 坐标要从 scene/layer 回传，不要在 renderer 内弹 UI。

## 环境系统

当前相关文件：

```text
lib/world/systems/mood_environment_controller.dart
lib/world/systems/config/day_phase_lighting_config.dart
lib/world/systems/config/mood_atmosphere_config.dart
lib/world/systems/config/weather_atmosphere_config.dart
lib/core/weather/weather_display.dart
```

环境输入：

- 心情 mood
- 天气 weather
- 时段 day phase

环境输出：

- sky
- light
- mood atmosphere
- weather atmosphere
- color/tint/glow

规则：

- 环境系统是纯计算，不调用 UI。
- 新增天气视觉时先改 config，再改 environment controller。
- 不要把天气 API 请求放进 world system。

## HUD / UI

HUD 当前属于 Flutter UI overlay，不属于底层 renderer。

相关文件：

```text
lib/island/widgets/island_hud_overlay.dart
lib/island/widgets/building_info_bubble.dart
lib/features/island/widgets/island_companion_speech_overlay.dart
```

规则：

- HUD 读取 provider 可以在 feature/page/widget 层做。
- renderer/layer 不直接显示 Flutter dialog。
- renderer/layer 只回传事件和坐标。

## 性能规则

优先：

- 使用 `WorldStateCache` 避免重复构建世界状态。
- 使用 `CompanionPictureCache` 避免重复矢量绘制。
- 把纯绘制 helper 拆小，减少重复计算。
- 避免每帧创建大量对象。

禁止：

- 每帧访问 SharedPreferences。
- 每帧访问 provider。
- 每帧请求网络。
- 每帧重新加载图片资源。

## 常见修改路线

新增建筑：

```text
Asset
  -> BuildingConfig
  -> BuildingFactory
  -> Unlock / Growth rule
  -> BuildingLayer display
```

新增装饰：

```text
Asset
  -> DecorConfig
  -> DecorPlacementResolver
  -> DecorScaleResolver
  -> DecorLayer
```

新增角色外观：

```text
Asset / catalog
  -> CompanionPainter / CozyHeroRenderer
  -> CharacterLayer
```

新增天气视觉：

```text
Weather data
  -> WeatherAtmosphereConfig
  -> MoodEnvironmentController
  -> WorldState.environment
  -> Sky/Ocean/Island layer
```

新增 HUD 信息：

```text
Provider
  -> IslandHomePage / island widget
  -> HUD overlay
```

不要进入 renderer 改业务读取。

## 两条渲染路径

主岛成长世界：

```text
资料 / 今日记录 / 解锁 / 天气
  -> IslandBuildService 或 GrowthWorldEngine
  -> WorldStateCache 复用未变化的快照
  -> GrowthWorldViewport
  -> WorldScene
```

副岛与首页群岛：

```text
StoryIslandModel + 用户等级 + 心情
  -> StoryIslandWorldBuilder.cardPreview / 详情快照
  -> features/home/widgets/world_preview_*.dart
  -> 或 story_island_static_detail_viewport.dart
```

副岛建筑坐标只改 `lib/core/constants/story_island_layout.dart` 的 `StoryIslandLayout.buildingAnchor`。Lv10 在中心，Lv1–Lv9 为三环各 3 座。主岛放置在 `lib/island/placement/`，两边不要互相借用锚点。

新增一座副岛分类时要同时改：建筑 catalog（Dart 与 `backend/app/config/story_island_buildings.py`）、`assets/images/islands/<category>/buildings/lv01.png`–`lv10.png`、`pubspec.yaml` 的 assets 声明。不要改 `IslandRenderer`。
