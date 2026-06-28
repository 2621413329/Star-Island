# Architecture Review

> 目标：提高后续 AI Coding 效率。本文只做架构审视与重组建议，不新增功能。

## 1. 当前结论

当前 `lib/` 已经过一轮无用代码与资源清理，整体可运行面更清晰，但架构仍然偏“按技术横切目录 + 历史演进堆叠”。主要问题不是功能缺失，而是：

- 目录职责混合：`features/`、`providers/`、`data/`、`island/`、`world/`、`design_system/` 同时承载业务、状态、渲染、接口与 UI 组件，AI 后续修改时需要跨目录追踪。
- 依赖方向不稳定：`core` 反向引用 `providers` / `data`，`design_system` 引用业务 provider，`island` 与 `world` 互相引用。
- 单文件职责过宽：多个页面、渲染器、配置仓库、统一 API repository 超过 500 行，其中 `world/island/island_renderer.dart` 超过 1000 行。
- 抽象边界不足：页面和 provider 大量直接引用 `AppRepository`，渲染、录音、天气、通知等实现类也被直接创建或直接暴露。

建议后续重组优先级：

1. 先统一目录与依赖方向。
2. 再拆分超长文件。
3. 最后统一命名与抽象接口。

## 2. 建议目录标准

建议把 `lib/` 收敛为以下稳定结构：

```text
lib/
  app/
    app.dart
    bootstrap/
    router/
    l10n/
  core/
    config/
    constants/
    error/
    platform/
    permission/
    storage/
    theme/
    utils/
  common/
    component/
    widget/
    extension/
  feature/
    auth/
      page/
      widget/
      provider/
      service/
    onboarding/
    today/
    records/
    status/
    island/
    more/
  game/
    engine/
    scene/
    rendering/
    system/
    behavior/
    model/
  data/
    model/
    repository/
    service/
    datasource/
  domain/
    model/
    repository/
    service/
  provider/
  router/
  config/
```

### 目录迁移建议

| 当前目录 | 建议归属 | 说明 |
|---|---|---|
| `features/` | `feature/` | 统一单数命名，每个 feature 内部按 `page/widget/provider/service/model` 分层。 |
| `providers/` | 优先迁入各 `feature/*/provider/` 或 `app/provider/` | 避免全局 provider 池继续膨胀。仅保留真正跨 feature 的 app 级 provider。 |
| `data/models/` | `data/model/` | 统一单数命名。后续可按业务拆 `auth/profile/moment/growth`。 |
| `data/repositories/` | `data/repository/` | 具体实现放 data，抽象接口放 `domain/repository/`。 |
| `design_system/` | `common/component/` 或 `common/widget/` | 只保留纯 UI、纯 painter、无业务 provider 的组件。 |
| `world/` | `game/` | `engine/scene/rendering/system/behavior` 命名已经接近目标，适合整体迁移。 |
| `island/` | 拆到 `feature/island/` 与 `game/` | 页面状态和业务展示进 feature，纯渲染/布局/配置进 game 或 data config。 |
| `router/` | `app/router/` 或 `router/` | 二选一即可，建议路由作为 app 入口能力放 `app/router/`。 |
| `l10n/` | `app/l10n/` | 生成文件可保持现状，但业务代码引用应统一。 |

## 3. 命名规则

建议统一以下命名：

- 目录统一小写单数：`feature`、`provider`、`repository`、`model`、`service`、`widget`、`page`。
- 页面以 `Page` 结尾，弹层以 `Sheet` 结尾，纯展示以 `View` 或 `Widget` 结尾。
- Riverpod 状态类以 `Notifier` 结尾，provider 文件按业务命名，如 `today_moments_provider.dart`。
- 纯业务服务以 `Service` 结尾，外部接口实现以 `RepositoryImpl` 结尾，抽象接口不加 `Impl`。
- 渲染类以 `Renderer` / `Painter` / `Layer` 区分：`Renderer` 管绘制策略，`Painter` 接 Flutter 绘制生命周期，`Layer` 接场景层级。
- 避免 `app_providers.dart`、`app_repository.dart` 这类过宽名称继续扩张。

## 4. 超长文件与 God Class 风险

### 超过 1000 行

| 文件 | 行数 | 风险 | 建议拆分 |
|---|---:|---|---|
| `lib/world/island/island_renderer.dart` | 1125 | 单个 renderer 同时负责岛体、阴影、边缘、水面接触、地表细节、growth world 特化绘制 | 拆为 `island_surface_renderer.dart`、`island_rim_renderer.dart`、`island_shadow_renderer.dart`、`growth_island_surface_renderer.dart`。 |

### 超过 500 行

| 文件 | 行数 | 风险 | 建议拆分 |
|---|---:|---|---|
| `lib/features/today/write_story_page.dart` | 973 | 页面、表单状态、照片同步、语音、提交、退出动画混在一起 | 拆 `page/`、`controller/`、`widget/`、`service/`。 |
| `lib/world/rendering/cozy_hero_renderer.dart` | 899 | 单类承担角色绘制全流程 | 按 body、face、props、shadow 拆 renderer。 |
| `lib/world/scene/layers/building_layer.dart` | 841 | layer 同时处理布局、点击、绘制、状态映射 | 拆 `building_layer.dart`、`building_hit_test.dart`、`building_presentation_mapper.dart`。 |
| `lib/island/config/growth_island_configs.dart` | 770 | 配置数据与 repository 混合 | 配置常量、解析、repository 分离。 |
| `lib/features/status/mood_status_page.dart` | 743 | 页面与多个筛选/卡片 widget 混合 | 页面只组装 tab，筛选行和卡片进 `widget/`。 |
| `lib/features/today/moment_form_widgets.dart` | 736 | 表单组件直接处理录音、转写、tag UI | 拆 `moment_note_field.dart`、`moment_tag_selector.dart`、`speech_note_controller.dart`。 |
| `lib/features/more/my_level_page.dart` | 690 | 页面、等级展示、数据拉取、滚动展示混合 | 数据 provider 与展示 widget 分离。 |
| `lib/world/scene/layers/character_layer.dart` | 684 | 角色绘制、缓存、交互、状态映射混合 | 拆角色 presenter、hit test、picture cache 使用层。 |
| `lib/island/decor/decor_config.dart` | 620 | 大量 decor 配置集中 | 拆静态配置、分类索引、解析工具。 |
| `lib/features/more/companion_showcase_page.dart` | 617 | 页面、资源 catalog 展示、接口调用混合 | 拆收藏状态 provider 与展示 widget。 |
| `lib/data/repositories/app_repository.dart` | 602 | 典型 God Repository，覆盖鉴权、profile、moment、growth、mood、voice、building | 拆成多个 repository 接口和 data 实现。 |
| `lib/world/island/realistic_lawn_renderer.dart` | 562 | 地表细节绘制集中 | 拆草地、障碍 mask、装饰阴影绘制。 |

生成文件 `lib/l10n/app_localizations.dart` 超过 500 行属于 Flutter l10n 生成物，不建议手动拆分。

## 5. 循环依赖与跨模块引用

### 高优先级依赖反转

- `core/api/api_client.dart` 引用 `providers/auth_provider.dart`：`core` 不应依赖应用状态层。建议把 token 读取与强制登出抽象为 `AuthSession` / `SessionStore` 接口，由 app 层注入。
- `core/storage/user_app_preferences_sync.dart` 引用 `data/repositories/app_repository.dart`：`core/storage` 不应依赖具体网络仓库。建议改依赖 `UserPreferencesRepository` 抽象。
- `core/growth/island_unlock_catalog.dart` 引用 `island/config` 与 `island/decor`：`core` 不应依赖 feature/game 配置。建议把成长岛解锁 catalog 移到 `feature/island` 或 `game/config`。

### 模块互相穿透

- `design_system/companion_painter.dart` 引用 `world/rendering/cozy_hero_renderer.dart`，同时 `world/rendering/companion_picture_cache.dart` 又引用 `design_system/companion_painter.dart`。这会形成 `design_system <-> world` 的模块级环。建议把 companion 纯绘制能力移动到 `common/component/companion` 或 `game/rendering/companion`，两侧只依赖同一个底层 renderer。
- `island/*` 多处引用 `world/engine/world_state.dart`，`world/*` 也大量引用 `island/config`、`island/decor`、`island/building`。建议统一为 `game` 内部依赖，或建立 `game/model` 作为共享模型，禁止 `island` 与 `world` 双向引用。
- `design_system` 中存在 `companion_loading.dart`、`moment_tag_chips.dart`、`growth_reward_dialog.dart` 直接引用 provider 或 repository。设计系统应为纯展示组件，业务读取应上移到 feature 页面或 feature widget。
- 多个页面直接引用 `data/repositories/app_repository.dart`，例如 `write_story_page.dart`、`record_page.dart`、`my_level_page.dart`、`companion_showcase_page.dart`、`moment_form_widgets.dart`。页面应通过 feature provider / use case 间接访问。

## 6. Repository / Service / Controller / Manager 职责

### Repository

当前 `AppRepository` 职责过宽，建议拆为：

- `AuthRepository`：登录、注册、auth entry。
- `ProfileRepository`：profile、nickname、gender、companion、onboarding、app preferences。
- `MomentRepository`：moment CRUD、照片、日期、最近记录。
- `MoodRepository`：mood report、check-in、status。
- `GrowthRepository`：growth summary、growth tags、weekly observation、building unlocks。
- `VoiceRepository`：语音上传、转写、分析轮询。
- `IslandConfigRepository`：岛屿样式、建筑配置等只读配置。

抽象接口放 `domain/repository/`，Dio 实现放 `data/repository/*_repository_impl.dart`。

### Service

- `StoryReminderService` 当前既处理权限、时区、通知内容、附件 bitmap、调度持久化，建议拆 `ReminderPermissionService`、`ReminderScheduler`、`ReminderPayloadBuilder`。
- `IslandWeatherService` 自己创建 `Dio`，建议依赖统一 `HttpClient` 或 `WeatherRepository`，避免多套网络配置。
- `IslandBuildService`、`IslandStyleResolver`、`BuildingResolver` 命名接近，但边界需要明确：resolver 只做纯映射，service 可以聚合输入并产出业务结果。

### Controller

- `MoodEnvironmentController` 是纯环境状态推进器，职责清晰，可保留在 `game/system/` 或 `game/controller/`。
- `LocaleController` 是 Riverpod `AsyncNotifier`，建议改名为 `LocaleNotifier` 或迁到 `app/l10n/provider/`，避免 Controller 与 Notifier 混用。
- 页面内私有 `_State` 承担 controller 职责较多，尤其 `WriteStoryPage`、`MomentNoteField`。建议为语音、提交、照片同步建立独立 controller/use case。

### Manager

- `DecorManager` 当前属于运行时装饰对象管理，建议明确为 `DecorRuntimeManager` 或拆成 `DecorPlacementController` + `DecorComponentFactory`。
- 避免新增泛化 `Manager`。如果只是映射用 `Resolver`，如果是业务编排用 `Service`，如果是状态推进用 `Controller` / `Notifier`。

## 7. 推荐依赖方向

建议统一为单向依赖：

```text
app
  -> feature
  -> domain
  -> data

feature
  -> common
  -> core

game
  -> core
  -> common

data
  -> domain
  -> core
```

约束：

- `core` 不引用 `feature`、`provider`、`data`。
- `common/component` 不引用 provider、repository、feature page。
- `feature/page` 不直接引用 Dio repository 实现，只引用 feature provider 或 domain use case。
- `game` 内部允许 engine、scene、rendering、system 互相协作，但不要再和 `feature/island` 双向引用。
- `router` 可以引用 page，但 page 不引用 router 实现，只通过导航接口或 `context.go` 做轻量跳转。

## 8. 建议迁移顺序

1. 建立空目录与 barrel 规则：先建立 `feature/`、`common/`、`game/`、`domain/`、`data/repository/`，不改行为。
2. 拆 `AppRepository`：先只抽接口和 provider，不改 API 路径、不改返回模型。
3. 修正核心反向依赖：处理 `core/api`、`core/storage`、`core/growth` 对上层目录的引用。
4. 迁移 `world/` 与 `island/`：先统一到 `game/`，再把页面级 `island_home_page` 留在 `feature/island/page/`。
5. 清理 `design_system`：只保留无业务依赖组件，其余迁到对应 feature widget。
6. 拆超长文件：从 `island_renderer.dart`、`write_story_page.dart`、`app_repository.dart` 三个最大风险点开始。
7. 增加 architecture lint：用 import 规则或脚本禁止 `core -> provider/data/feature`、`common -> provider/data`、`feature/page -> data/repository_impl`。

## 9. 本轮不建议做的事

- 不删除 `unused_assets.md` 中列出的动态资源。它们处于 pubspec 声明目录或 AssetManifest runtime catalog 下，当前报告已建议保留。
- 不为了拆目录改业务流程、接口字段、路由路径或视觉表现。
- 不手动修改 l10n 生成文件。
- 不一次性大规模移动所有文件。应按依赖方向和测试可验证边界分批迁移。

## 10. AI Coding 效率收益

完成以上整理后，后续 AI 修改可以按固定入口定位：

- 页面问题：`feature/<name>/page/`
- UI 小组件：`feature/<name>/widget/` 或 `common/widget/`
- 状态问题：`feature/<name>/provider/`
- API 问题：`domain/repository/` + `data/repository/`
- 渲染问题：`game/rendering/` 或 `game/scene/layer/`
- 配置问题：`core/config/`、`game/config/` 或 `data/model/`

这样可以显著减少跨目录搜索、误改无关模块和重复创建抽象的概率。
