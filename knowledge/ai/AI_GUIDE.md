# AI Guide

| | |
|---|---|
| 编号 | KB-09 |
| 回答的问题 | 新增一类能力时按什么步骤改哪些文件 |
| 不负责 | 现行行为的动作链 |
| 何时更新 | 新增步骤变了 |
| 路由 | 只在 `knowledge/README.md` |


按场景改文件的步骤在下面。先打开哪一份，按 `knowledge/README.md` 的任务路由。

## 总原则

修改代码时优先遵守：

1. 不改业务行为。
2. 不改 UI 效果。
3. 不改 API path、payload、response parse。
4. 不改存储 key。
5. 不随意删除 assets。
6. 不扩大 `core`、`design_system`、`world` 的依赖方向。
7. 每次只改一个模块或一个强相关文件族。

改了一条用户能感知的行为，就改对应这一节。回写约定在 `knowledge/README.md` 的任务路由。

## 历史材料，不要当现行说明

`stday/architecture_plan.md`、`stday/future_refactor_notes.md`、`stday/refactor_phase_1.md` 是旧重构笔记。删资源前查 `stday/unused_assets.md` 和 `stday/cleanup_report.md`。

## 快速判断文件该放哪

放置表以 KB-04 为准。下面是同一规则的文件名形态。

新增页面：

```text
stday/lib/features/<module>/<xxx>_page.dart
```

新增 feature widget：

```text
stday/lib/features/<module>/widgets/<xxx>.dart
```

新增纯 UI：

```text
stday/lib/design_system/<xxx>.dart
```

新增 provider：

```text
stday/lib/providers/<xxx>_provider.dart
```

或只属于某 feature 时：

```text
stday/lib/features/<module>/<xxx>_provider.dart
```

新增 API：

```text
stday/lib/data/repositories/app_repository_facades.dart
stday/lib/data/repositories/app_repository.dart
```

后续拆分后再迁到：

```text
stday/lib/data/datasource/remote/
```

新增游戏渲染：

```text
stday/lib/world/
```

不要把游戏渲染放进 `features/` 页面。

## 如果新增一个岛屿建筑

应该检查：

```text
Asset
  -> BuildingConfig
  -> BuildingFactory
  -> BuildingResolver / BuildingSystem
  -> Unlock rule
  -> BuildingLayer
  -> HUD / bubble if needed
```

优先文件：

```text
stday/lib/island/config/building_config.dart
stday/lib/island/building/
stday/lib/island/service/building_resolver.dart
stday/lib/world/systems/building_system.dart
stday/lib/world/scene/layers/building_layer.dart
stday/lib/common/island_contracts/building_config.dart
```

不要直接修改：

```text
stday/lib/world/island/island_renderer.dart
stday/lib/world/island/growth_world_ground_painter.dart
stday/lib/world/scene/layers/character_layer.dart
stday/lib/island/viewport/growth_world_viewport.dart
```

除非需求明确涉及岛体形状、相机或角色交互。

## 如果新增一个装饰 Decor

应该检查：

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
stday/lib/island/decor/decor_config.dart
stday/lib/island/decor/decor_placement_resolver.dart
stday/lib/island/decor/decor_scale_resolver.dart
stday/lib/island/decor/decor_manager.dart
stday/lib/world/scene/layers/decor_layer.dart
stday/lib/world/scene/layers/grass_foreground_layer.dart
```

不要直接修改：

```text
WorldScene
Camera
IslandRenderer
GrowthWorldEngine
```

## 如果新增人物或人物样式

应该检查：

```text
Companion catalog / asset
  -> CompanionPainter
  -> CozyHeroRenderer
  -> CharacterLayer
  -> UserCompanionView
```

优先文件：

```text
stday/lib/design_system/companion_painter.dart
stday/lib/design_system/user_companion_view.dart
stday/lib/world/rendering/cozy_hero_renderer.dart
stday/lib/world/scene/layers/character_layer.dart
stday/lib/core/models/user_companion.dart
```

不要修改：

```text
Camera
IslandRenderer
BuildingLayer
DecorLayer
```

除非人物需要新的世界交互或遮挡规则。

## 如果新增一座故事岛分类或改副岛建筑

同时改：

```text
stday/lib/core/constants/story_island_building_catalog.dart
backend/app/config/story_island_buildings.py
assets/images/islands/<category>/buildings/lv01.png … lv10.png
stday/pubspec.yaml
```

挪副岛建筑只改 `stday/lib/core/constants/story_island_layout.dart`。首页五座岛的位置只改 `stday/lib/world/preview/world_island_layout.dart`。快照组装在 `StoryIslandWorldBuilder`。

不要改：

```text
stday/lib/island/placement/
stday/lib/world/island/island_renderer.dart
GrowthWorldViewport 的相机
```

任务和岛屿 CRUD 走 `StoryIslandRepository`。把一条日常放到某座岛走 `MomentRepository.updateMomentStoryIsland`。

非 VIP 每个分类只能有 1 座未归档岛。改这个额度只动 `nonVipStoryIslandLimitPerCategory`，并确认创建入口 `IslandHomePage._createStoryIsland` 仍在用它。

## 如果新增会员门槛

读 `isVipProvider`。弹窗用 `stday/lib/core/membership/vip_guard.dart` 的 `showVipRequiredDialog`，它会转到 `/more/membership`。蒙版用 `VipFeatureMask`。

购买、恢复、激活码分别走 `IapRepository` 和 `MemberRepository`。商品 ID 只定义在 `stday/lib/core/membership/iap_product_ids.dart`，并与后端 `member_products.product_id` 一致。

不要在 `design_system` 或 `world` 里判断 VIP。

## 如果新增日常记录能力

应该检查：

```text
UI Page / Widget
  -> Provider / Action
  -> MomentRepository
  -> StdayApiDatasource
  -> API
```

优先文件：

```text
stday/lib/features/today/
stday/lib/features/records/
stday/lib/providers/story_day_provider.dart
stday/lib/data/repositories/app_repository_facades.dart
stday/lib/data/repositories/app_repository.dart
```

不要直接在页面中：

- 创建 Dio。
- 拼接 API baseUrl。
- 读写 SharedPreferences，除非是页面局部明确需求。
- 修改 growth/world renderer。

## 如果新增成长等级或解锁

应该检查：

```text
GrowthSystem
  -> GrowthSummary
  -> BuildingUnlocks
  -> LevelUnlockPreview
  -> Island / HUD / Dialog
```

优先文件：

```text
stday/lib/core/growth/growth_system.dart
stday/lib/core/growth/island_unlock_catalog.dart
stday/lib/core/growth/level_unlock_preview.dart
stday/lib/island/providers/growth_summary_provider.dart
stday/lib/features/achievement/growth_reward_actions.dart
stday/lib/design_system/growth_reward_dialog.dart
```

注意：

- `design_system/growth_reward_dialog.dart` 是纯 UI。
- 业务编排在 `features/achievement/growth_reward_actions.dart`。

## 如果新增 API

流程：

```text
Repository facade method
  -> Datasource method
  -> unwrap
  -> model parse
  -> provider/usecase
  -> page
```

当前文件：

```text
stday/lib/data/repositories/app_repository_facades.dart
stday/lib/data/repositories/app_repository.dart
```

规则：

- endpoint path 写在 datasource。
- page 不直接调用 Dio。
- 不把新接口塞进无关 repository。
- 如果 API 返回结构变化，新增或调整 model。
- 修改 API 配置时同步测试 `stday/test/app_config_test.dart`。

## 如果 HTTP 要切 HTTPS

不要全局搜索替换业务代码。

优先使用：

```powershell
flutter run --dart-define=API_SCHEME=https
```

或：

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

相关文件：

```text
stday/lib/core/config/app_config.dart
stday/test/app_config_test.dart
README.md
```

## 如果新增资源

检查：

```text
stday/assets/images/...
stday/assets/images/islands/<分类>/buildings/
stday/assets/audio/
stday/pubspec.yaml
Asset catalog / config
stday/unused_assets.md
```

规则：

- 不要删除动态资源。
- 不要只看 `rg` 结果判断资源未使用。
- 很多资源通过目录扫描、AssetManifest、服务端字段引用。

## 如果修改 design_system

允许：

- 视觉组件。
- painter。
- loading view。
- dialog UI。
- chip UI。

禁止：

- import `flutter_riverpod`。
- import `providers/`。
- import `data/repositories/`。
- 使用 `WidgetRef`。
- 调用 API。

如果需要业务数据：

```text
features/<module>/widgets/<wrapper>.dart
  -> 读取 provider
  -> 传普通参数给 design_system
```

## 如果修改 core

允许：

- 配置。
- 工具。
- 存储抽象。
- API 通用封装。
- 通知/权限/平台能力。

禁止：

- import `features/`。
- import `providers/`。
- import `data/repositories/`。
- 写页面逻辑。

core 需要上层行为时，用 callback 或抽象接口注入。

当前示例：

```text
core/api/api_session.dart
  <- providers/auth_provider.dart 注册回调
```

## 如果修改 world

允许：

- world engine。
- world state。
- scene。
- layer。
- renderer。
- system。
- behavior。

禁止：

- 读取 Riverpod provider。
- 调用 repository。
- import feature page。
- 弹 Flutter dialog。

world 需要业务数据时，由 feature/provider 先构造成 `WorldState` 或输入模型再传入。

## 如果拆超长文件

优先顺序：

1. 抽纯 UI widget。
2. 抽纯绘制 helper。
3. 抽纯计算 resolver/mapper。
4. 抽 controller/usecase。
5. 最后移动带 provider 和外部依赖的代码。

每步要求：

- 对外类名和 public 方法尽量不变。
- 旧 import 路径可保留 export wrapper。
- 每拆一次运行 `flutter analyze`。

## 禁止操作

不要做：

- 为了修架构改接口字段。
- 为了整理删除资源。
- 在 `core` 里读 provider。
- 在 `design_system` 里读 provider。
- 在 `world` 里调 API。
- 在页面里直接 new Dio。
- 无需求地重命名大量文件。
- 一次移动多个大模块。
- 删除兼容 export wrapper，除非已确认所有引用迁移完成。

## 推荐验证

通用：

```powershell
flutter analyze
```

API 配置：

```powershell
cd stday
flutter test test/app_config_test.dart
```

视觉/岛屿：

- 打开 `/island`。
- 检查角色、建筑、装饰、HUD、点击气泡。
- 检查缩放、旋转、切 tab 后恢复。

日常记录：

- 新增文字日常。
- 新增语音日常。
- 编辑标签。
- 删除记录。

## 如果改了用户能感知的行为

给人审的稿是 KB-10。找到对应节，或按同样格式新增一节：

1. 用编号写出改完之后的动作，从用户操作到 repository 或本地状态。
2. 把这一节原来的动作写进「和之前的差异」。
3. 最后一行写审核时要打开的函数。

不要只更新 `knowledge/ai/feature_map.md`。文件地图给改代码用，审核稿给人对动作和差异。

## 一句话规则

新增业务走 feature，新增展示走 design_system，新增 API 走 repository/datasource，新增岛屿元素走 config/layer/renderer，不要跨层偷改。
