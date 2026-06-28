# Architecture Governance Plan

> 本文是后续所有架构重构的执行基准。任何重构都必须先对照本文确认目录归属、依赖方向、拆分顺序和禁止事项。本文不要求新增功能。

## 0. 治理原则

- 不修改业务行为：接口路径、字段、路由路径、视觉表现、存储 key 不因架构迁移改变。
- 先抽象再迁移：先建立接口、目录和 provider 映射，再移动实现。
- 单向依赖：UI 只能向下依赖 Provider / UseCase / Repository / Datasource，不允许反向依赖。
- 小步提交：每次只迁移一个 feature 或一个超长文件族。
- 生成文件豁免：`lib/l10n/app_localizations*.dart` 不手动拆分。

## 1. 最终目录结构

```text
lib/
  app/
    app.dart
    bootstrap/
    l10n/
    provider/
    router/

  core/
    config/
    constant/
    error/
    extension/
    platform/
    permission/
    storage/
    sync/
    theme/
    util/

  common/
    component/
      companion/
      feedback/
      form/
      island_card/
      loading/
      mood/
    widget/
    painter/

  feature/
    auth/
      page/
      widget/
      provider/
      usecase/
    onboarding/
      page/
      widget/
      provider/
    story/
      page/
      widget/
      provider/
      usecase/
      controller/
    record/
      page/
      widget/
      provider/
    status/
      page/
      widget/
      provider/
      usecase/
    island/
      page/
      widget/
      provider/
      usecase/
    user/
      page/
      widget/
      provider/
      usecase/
    achievement/
      page/
      widget/
      provider/
      usecase/
    reminder/
      page/
      widget/
      provider/
      usecase/
    landing/
      page/
      widget/
      provider/
    debug/
      page/

  game/
    world/
      engine/
      model/
      scene/
      layer/
      system/
    island/
      model/
      config/
      placement/
      renderer/
      painter/
    character/
      model/
      renderer/
      painter/
      behavior/
      cache/
    building/
      model/
      config/
      renderer/
      layer/
      resolver/
    decor/
      model/
      config/
      manager/
      renderer/
      resolver/
    camera/
    animation/

  domain/
    model/
    repository/
    service/
    usecase/

  data/
    datasource/
      remote/
      local/
    dto/
    mapper/
    repository/

  service/
    notification/
    weather/
    voice/
    asset/

  provider/
    repository_provider.dart
    service_provider.dart

  router/
    app_router.dart

  config/
    app_config.dart
```

### 目录职责

| 目录 | 职责 | 禁止 |
|---|---|---|
| `app/` | 应用入口、启动、全局 l10n、全局 provider、router 组装 | 不放业务页面实现。 |
| `core/` | 无业务方向的基础能力：配置、错误、平台、权限、本地存储、主题、工具 | 不引用 `feature/`、`data/`、`provider/`、`router/`。 |
| `common/` | 可复用 UI、组件、painter；只接收参数展示 | 不读取 Riverpod provider，不调用 repository。 |
| `feature/` | 用户可感知业务模块，每个模块自带 page/widget/provider/usecase | 不直接依赖 repository 实现类。 |
| `game/` | 岛屿、世界、角色、建筑、装饰、动画等渲染和模拟 | 不引用 feature page，不读取业务 provider。 |
| `domain/` | 抽象接口、领域模型、UseCase、领域服务 | 不依赖 Flutter UI、Dio、SharedPreferences。 |
| `data/` | remote/local datasource、dto、mapper、repository 实现 | 不引用 UI、feature page、game layer。 |
| `service/` | 平台服务包装：通知、天气、语音、资源 catalog | 不承担页面状态。 |
| `provider/` | 只放跨 feature 的 repository/service provider 绑定 | 不放页面状态。 |
| `router/` | 路由表与跳转守卫 | 不放业务逻辑。 |
| `config/` | 应用级配置 | 不放动态业务状态。 |

## 2. 超过 500 行文件拆分方案

### 2.1 `lib/world/island/island_renderer.dart` 1125 行

目标目录：`lib/game/island/renderer/`

| 拆分后文件 | 职责 |
|---|---|
| `island_renderer.dart` | 对外 facade，只协调各子 renderer。 |
| `island_surface_renderer.dart` | 顶面草地、基础地表绘制。 |
| `island_side_wall_renderer.dart` | 岛体厚度、侧壁、石质边缘。 |
| `island_shadow_renderer.dart` | 投影、接触阴影、水面阴影。 |
| `island_rim_renderer.dart` | 边缘高光、rim highlight。 |
| `growth_island_surface_renderer.dart` | growth world 特化地表。 |
| `growth_island_water_contact_renderer.dart` | growth world 水面接触效果。 |

迁移顺序：

1. 复制私有绘制函数到同目录子 renderer，保持 facade API 不变。
2. 先抽无状态 painter helper，再抽需要 `_time` 的动态 renderer。
3. facade 内逐步替换私有方法调用。
4. 每步运行视觉 smoke test 或现有 island debug page。

### 2.2 `lib/features/today/write_story_page.dart` 973 行

目标目录：`lib/feature/story/`

| 拆分后文件 | 职责 |
|---|---|
| `page/write_story_page.dart` | 页面入口、路由参数、整体布局。 |
| `controller/write_story_controller.dart` | 提交、编辑、删除、退出保护、状态流转。 |
| `controller/story_photo_sync_controller.dart` | 照片上传、删除、同步。 |
| `controller/story_voice_controller.dart` | 语音录制结果、转写、清理临时文件。 |
| `widget/write_story_sheet.dart` | 弹层容器、拖拽收起、动画。 |
| `widget/story_input_mode_tabs.dart` | 文本/语音 tab。 |
| `widget/story_submit_bar.dart` | 提交按钮与上传状态展示。 |
| `usecase/save_story_moment_usecase.dart` | create/update moment 编排。 |

迁移顺序：

1. 先抽底部 tabs、按钮、展示 widget。
2. 再抽照片同步 controller。
3. 再抽语音 controller。
4. 最后把提交逻辑迁到 usecase，页面只负责调用 provider。

### 2.3 `lib/world/rendering/cozy_hero_renderer.dart` 899 行

目标目录：`lib/game/character/renderer/`

| 拆分后文件 | 职责 |
|---|---|
| `cozy_hero_renderer.dart` | facade，保留 `paintInRect` / `paintAt`。 |
| `cozy_body_renderer.dart` | 身体、手臂、头部基础形体。 |
| `cozy_face_renderer.dart` | 表情、眼睛、嘴、情绪变化。 |
| `cozy_prop_renderer.dart` | prop 与 extraProps 绘制。 |
| `cozy_shadow_renderer.dart` | 地面阴影与接触阴影。 |
| `cozy_lighting_renderer.dart` | 环境光、星核、性能等级视觉。 |

迁移顺序：

1. 先抽无外部依赖的 shadow/body。
2. 再抽 face 与 prop。
3. 最后统一 lighting 参数对象，避免长参数列表继续扩张。

### 2.4 `lib/world/scene/layers/building_layer.dart` 841 行

目标目录：`lib/game/building/layer/`

| 拆分后文件 | 职责 |
|---|---|
| `building_layer.dart` | Flame layer 生命周期与子模块协调。 |
| `building_hit_test.dart` | 点击区域、hover/selection 判断。 |
| `building_presentation_mapper.dart` | `WorldState` 到建筑展示模型映射。 |
| `building_component_factory.dart` | Flame component 创建。 |
| `building_label_renderer.dart` | 建筑标签、锁定态、提示绘制。 |

迁移顺序：

1. 抽 hit test，不改变 layer 对外行为。
2. 抽 presentation mapper，让 layer 不直接理解所有业务字段。
3. 抽 component factory。
4. 拆标签绘制。

### 2.5 `lib/island/config/growth_island_configs.dart` 770 行

目标目录：`lib/game/island/config/`

| 拆分后文件 | 职责 |
|---|---|
| `growth_island_config.dart` | 配置模型 export。 |
| `growth_island_level_config.dart` | 等级与岛屿阶段配置。 |
| `growth_island_building_config.dart` | 建筑解锁与展示配置。 |
| `growth_island_decor_config.dart` | 装饰与环境配置。 |
| `growth_island_config_repository.dart` | 只读配置查询。 |

迁移顺序：

1. 先拆纯 const/list 配置。
2. 再拆 query helper。
3. 最后保留 barrel 文件兼容旧 import，再逐步替换。

### 2.6 `lib/features/status/mood_status_page.dart` 743 行

目标目录：`lib/feature/status/`

| 拆分后文件 | 职责 |
|---|---|
| `page/mood_status_page.dart` | 页面骨架、tab 组装。 |
| `widget/emotion_filter_row.dart` | 情绪筛选。 |
| `widget/category_filter_row.dart` | 分类筛选。 |
| `widget/day_summary_card.dart` | 单日摘要卡片。 |
| `widget/status_tab_view.dart` | overview/stats/summary tab 容器。 |
| `provider/mood_status_filter_provider.dart` | 筛选状态。 |

迁移顺序：

1. 抽私有 widget 到 `widget/`。
2. 抽 filter provider。
3. 页面只保留布局与 provider 监听。

### 2.7 `lib/features/today/moment_form_widgets.dart` 736 行

目标目录：`lib/feature/story/`

| 拆分后文件 | 职责 |
|---|---|
| `widget/moment_note_field.dart` | 文本输入 UI。 |
| `controller/speech_note_controller.dart` | 录音、转写、合并文本。 |
| `widget/moment_tag_selector.dart` | 标签选择 UI。 |
| `widget/moment_tag_list_card.dart` | 标签列表卡片。 |
| `widget/moment_tag_button.dart` | 单个标签按钮。 |
| `widget/moment_tag_icon_frame.dart` | 标签图标边框展示。 |

迁移顺序：

1. 先拆 tag UI。
2. 再拆 note field。
3. 最后把语音转写从 widget state 移到 controller/usecase。

### 2.8 `lib/design_system/companion_painter.dart` 697 行

目标目录：`lib/common/painter/companion/` 或 `lib/game/character/painter/`

| 拆分后文件 | 职责 |
|---|---|
| `companion_painter.dart` | CustomPainter facade。 |
| `legacy_companion_body_painter.dart` | legacy/chibi body。 |
| `legacy_companion_face_painter.dart` | legacy/chibi face。 |
| `legacy_companion_prop_painter.dart` | legacy/chibi prop。 |
| `companion_aura_painter.dart` | aura、glow、背景效果。 |
| `companion_painter_style.dart` | painter 参数与颜色计算。 |

迁移顺序：

1. 先解除 `design_system -> world` 引用，把 cozy renderer 下沉到共同依赖层。
2. 抽 aura/style。
3. 抽 legacy body/face/prop。
4. facade 保持原构造参数。

### 2.9 `lib/features/more/my_level_page.dart` 690 行

目标目录：`lib/feature/achievement/`

| 拆分后文件 | 职责 |
|---|---|
| `page/my_level_page.dart` | 页面骨架。 |
| `provider/my_level_provider.dart` | 等级页数据聚合。 |
| `widget/level_header.dart` | 等级头部。 |
| `widget/level_progress_section.dart` | 进度展示。 |
| `widget/level_unlock_timeline.dart` | 解锁时间线。 |
| `widget/recent_activity_calendar.dart` | 最近记录日期展示。 |

迁移顺序：

1. 抽页面内展示 widget。
2. 抽 `_momentDatesProvider` 到公开 provider。
3. 把 repository 调用移入 usecase/provider。

### 2.10 `lib/world/scene/layers/character_layer.dart` 684 行

目标目录：`lib/game/character/`

| 拆分后文件 | 职责 |
|---|---|
| `layer/character_layer.dart` | Flame layer 生命周期。 |
| `model/character_presentation.dart` | 展示态模型。 |
| `renderer/character_scene_renderer.dart` | 场景角色绘制协调。 |
| `behavior/character_hit_test.dart` | 点击命中。 |
| `cache/character_picture_cache_adapter.dart` | 图片缓存调用封装。 |

迁移顺序：

1. 抽 presentation model。
2. 抽 hit test。
3. 抽 picture cache adapter。
4. layer 只保留生命周期和绘制入口。

### 2.11 `lib/island/decor/decor_config.dart` 620 行

目标目录：`lib/game/decor/config/`

| 拆分后文件 | 职责 |
|---|---|
| `decor_config.dart` | decor config barrel。 |
| `decor_model.dart` | 装饰配置模型。 |
| `decor_catalog.dart` | 全量 catalog。 |
| `decor_category_catalog.dart` | 分类索引。 |
| `decor_asset_catalog.dart` | asset path 映射。 |

迁移顺序：

1. 先拆模型。
2. 再拆 catalog 常量。
3. 最后拆查询 helper。

### 2.12 `lib/features/more/companion_showcase_page.dart` 617 行

目标目录：`lib/feature/user/`

| 拆分后文件 | 职责 |
|---|---|
| `page/companion_showcase_page.dart` | 页面骨架。 |
| `provider/collected_props_provider.dart` | 已收集道具数据。 |
| `widget/companion_preview_panel.dart` | 角色预览。 |
| `widget/prop_collection_grid.dart` | 道具网格。 |
| `widget/prop_collect_tile.dart` | 单个道具 tile。 |

迁移顺序：

1. 抽 `_collectedPropsProvider`。
2. 抽 grid/tile。
3. 页面只持有 tab/page controller。

### 2.13 `lib/data/repositories/app_repository.dart` 602 行

目标目录：`lib/domain/repository/` + `lib/data/repository/`

| 拆分后文件 | 职责 |
|---|---|
| `domain/repository/auth_repository.dart` | 鉴权抽象。 |
| `domain/repository/profile_repository.dart` | 用户资料抽象。 |
| `domain/repository/moment_repository.dart` | 日常记录抽象。 |
| `domain/repository/mood_repository.dart` | 情绪统计抽象。 |
| `domain/repository/growth_repository.dart` | 成长/等级/建筑解锁抽象。 |
| `domain/repository/voice_repository.dart` | 语音上传/转写抽象。 |
| `data/repository/*_repository_impl.dart` | Dio 实现。 |
| `data/datasource/remote/stday_api_datasource.dart` | HTTP endpoint 封装。 |

迁移顺序：

1. 先建接口，不移动 endpoint。
2. 新增 repository provider 映射到旧 `AppRepository` 适配器。
3. 逐个 feature 改依赖接口。
4. 最后拆 Dio 实现并删除 `AppRepository`。

### 2.14 `lib/world/island/realistic_lawn_renderer.dart` 562 行

目标目录：`lib/game/island/renderer/`

| 拆分后文件 | 职责 |
|---|---|
| `realistic_lawn_renderer.dart` | facade。 |
| `lawn_grass_renderer.dart` | 草地纹理。 |
| `lawn_flower_renderer.dart` | 花、点缀。 |
| `lawn_obstacle_shadow_renderer.dart` | 障碍阴影。 |
| `lawn_noise_painter.dart` | 噪声与自然化处理。 |

迁移顺序：

1. 抽无状态 helper。
2. 拆草地与点缀。
3. 拆障碍阴影。

### 2.15 生成文件豁免

| 文件 | 行数 | 处理 |
|---|---:|---|
| `lib/l10n/app_localizations.dart` | 560 | Flutter 生成文件，不拆分、不手动编辑。 |

## 3. 未来 Provider 清单

### App 层 Provider

| Provider | 依赖 | 不可依赖 |
|---|---|---|
| `appBootstrapProvider` | `AppBootstrap` | feature page。 |
| `appSplashHoldProvider` | 无 | repository。 |
| `startupProfileTimeoutProvider` | 无 | repository。 |
| `startupSettledProvider` | bootstrap/profile 状态 | UI widget。 |
| `appRouterProvider` | auth/profile/main tab | repository 实现。 |
| `localeProvider` | `LocaleUseCase` / local storage | feature page。 |
| `mainShellTabIndexProvider` | 无 | repository。 |

### Repository Provider

统一放在 `lib/provider/repository_provider.dart`。

| Provider | 产物 | 依赖 |
|---|---|---|
| `authRepositoryProvider` | `AuthRepository` | `AuthRemoteDatasource`。 |
| `profileRepositoryProvider` | `ProfileRepository` | `ProfileRemoteDatasource`、local cache 可选。 |
| `momentRepositoryProvider` | `MomentRepository` | `MomentRemoteDatasource`。 |
| `moodRepositoryProvider` | `MoodRepository` | `MoodRemoteDatasource`。 |
| `growthRepositoryProvider` | `GrowthRepository` | `GrowthRemoteDatasource`、`GrowthTagLocalDatasource`。 |
| `voiceRepositoryProvider` | `VoiceRepository` | `VoiceRemoteDatasource`、`VoiceFileService`。 |
| `weatherRepositoryProvider` | `WeatherRepository` | `WeatherRemoteDatasource`。 |
| `islandConfigRepositoryProvider` | `IslandConfigRepository` | static config datasource。 |
| `userPreferencesRepositoryProvider` | `UserPreferencesRepository` | local storage + profile remote。 |

### Service Provider

统一放在 `lib/provider/service_provider.dart`。

| Provider | 产物 | 依赖 |
|---|---|---|
| `httpClientProvider` | Dio 或 HttpClient wrapper | `SessionStore`、`AppConfig`。 |
| `sessionStoreProvider` | `SessionStore` | SharedPreferences。 |
| `storyReminderServiceProvider` | `StoryReminderService` facade | permission/scheduler/payload services。 |
| `reminderPermissionServiceProvider` | `ReminderPermissionService` | platform plugin。 |
| `reminderSchedulerProvider` | `ReminderScheduler` | local notifications plugin。 |
| `weatherServiceProvider` | `WeatherService` | `WeatherRepository`。 |
| `voiceRecorderServiceProvider` | `VoiceRecorderService` | record/path_provider/permission。 |
| `assetCatalogServiceProvider` | `AssetCatalogService` | AssetManifest。 |

### Feature Provider

| Provider | 所属 | 依赖 |
|---|---|---|
| `authProvider` | `feature/auth/provider/` | `AuthRepository`、`SessionStore`。 |
| `profileProvider` | `feature/user/provider/` | `ProfileRepository`、`UserPreferencesRepository`。 |
| `userCompanionProvider` | `feature/user/provider/` | `profileProvider`。 |
| `moodPaletteProvider` | `feature/user/provider/` | `profileProvider`、`storyDayViewProvider`。 |
| `todayMomentsProvider` | `feature/story/provider/` | `MomentRepository`。 |
| `selectedStoryDayProvider` | `feature/story/provider/` | 无。 |
| `storyDayViewProvider` | `feature/story/provider/` | `MomentRepository`、`profileProvider`。 |
| `writeStoryControllerProvider` | `feature/story/provider/` | story usecases。 |
| `speechNoteControllerProvider` | `feature/story/provider/` | `VoiceRepository`、`VoiceRecorderService`。 |
| `moodStatusPeriodProvider` | `feature/status/provider/` | 无。 |
| `moodStatusCategoryFilterProvider` | `feature/status/provider/` | 无。 |
| `moodStatusEmotionFilterProvider` | `feature/status/provider/` | 无。 |
| `moodStatusPageProvider` | `feature/status/provider/` | 无。 |
| `moodStatusAllMomentsProvider` | `feature/status/provider/` | `MomentRepository`。 |
| `moodPeriodSummaryProvider` | `feature/status/provider/` | `MoodRepository`。 |
| `moodStatusViewProvider` | `feature/status/provider/` | `MoodRepository`、`MomentRepository`。 |
| `moodReportCheckInProvider` | `feature/status/provider/` | `MoodRepository`。 |
| `growthTagCatalogProvider` | `feature/story/provider/` 或 `feature/status/provider/` | `GrowthRepository`。 |
| `weeklySummaryProvider` | `feature/record/provider/` | `GrowthRepository`。 |
| `growthSummaryProvider` | `feature/achievement/provider/` | `GrowthRepository`。 |
| `buildingUnlocksProvider` | `feature/island/provider/` | `GrowthRepository`。 |
| `islandWeatherProvider` | `feature/island/provider/` | `WeatherRepository`。 |
| `islandWorldProvider` | `feature/island/provider/` | `GrowthWorldEngine`、profile、story、weather、growth summary。 |
| `growthWorldEngineProvider` | `game/world/provider/` 或 `provider/service_provider.dart` | 无或 game config。 |
| `myLevelProvider` | `feature/achievement/provider/` | `GrowthRepository`、`MomentRepository`。 |
| `collectedPropsProvider` | `feature/user/provider/` | `GrowthRepository` 或 `ProfileRepository`。 |
| `reminderSettingsProvider` | `feature/reminder/provider/` | `UserPreferencesRepository`、`StoryReminderService`。 |
| `reminderIconCatalogProvider` | `feature/reminder/provider/` | `AssetCatalogService`。 |

## 4. 未来 Repository / Service / Manager 清单

### Repository

| Repository | 职责 | 可依赖 | 不可依赖 |
|---|---|---|---|
| `AuthRepository` | 登录、注册、auth entry | datasource、mapper | UI、provider。 |
| `ProfileRepository` | profile、昵称、性别、陪伴角色、偏好同步 | datasource、local cache | feature page。 |
| `MomentRepository` | 日常 CRUD、照片、日期、最近记录 | datasource、file service | widget。 |
| `MoodRepository` | 情绪报告、周期摘要、check-in | datasource | UI。 |
| `GrowthRepository` | 成长值、等级、标签、建筑解锁、周总结 | datasource、local cache | game renderer。 |
| `VoiceRepository` | 语音转写、分析轮询 | datasource、voice file service | widget state。 |
| `WeatherRepository` | 真实天气快照 | datasource | UI。 |
| `IslandConfigRepository` | 岛屿、建筑、decor 静态配置查询 | static datasource | remote UI state。 |
| `UserPreferencesRepository` | 本地与远端偏好同步 | local storage、profile datasource | page。 |

### Service

| Service | 职责 | 可依赖 | 不可依赖 |
|---|---|---|---|
| `StoryReminderService` | 提醒 facade，编排权限、调度、payload | reminder 子服务 | feature page。 |
| `ReminderPermissionService` | 通知/精确闹钟权限 | platform plugin | repository。 |
| `ReminderScheduler` | 本地通知调度与取消 | local notifications plugin | UI。 |
| `ReminderPayloadBuilder` | 通知标题、正文、图标 payload | core model | plugin。 |
| `WeatherService` | 天气业务解释，如展示文案/兜底 | `WeatherRepository` | Dio。 |
| `VoiceRecorderService` | 录音、权限、临时文件 | record/path_provider | repository 实现。 |
| `VoiceFileService` | voice file 删除、路径、URL 处理 | platform/file API | UI。 |
| `IslandBuildService` | 由成长、心情、天气产出 `WorldState` | game engine/config | feature page。 |
| `IslandStyleResolver` | 心情/天气到岛屿样式映射 | config | provider。 |
| `IslandGrowthScaleService` | growth scale 计算 | config/model | UI。 |
| `AssetCatalogService` | AssetManifest catalog 读取 | Flutter asset bundle | repository。 |

### Manager

| Manager | 职责 | 可依赖 | 不可依赖 |
|---|---|---|---|
| `DecorRuntimeManager` | 运行时 decor component 生命周期 | game decor config、component factory | feature provider。 |
| `DecorComponentFactory` | 创建 decor component | decor model/config | UI。 |

规则：后续避免新增泛化 `Manager`。能命名为 `Resolver`、`Factory`、`Service`、`Controller`、`Notifier` 时不要使用 `Manager`。

## 5. 依赖关系图

### 标准业务链路

```text
UI Page / Widget
  ↓
Feature Provider / Controller
  ↓
UseCase
  ↓
Domain Repository Interface
  ↓
Data Repository Impl
  ↓
Datasource
  ↓
HTTP / SharedPreferences / Plugin / AssetManifest
```

禁止：

```text
Datasource → Repository Interface → UseCase → Provider → UI
```

### 游戏渲染链路

```text
Feature Island Provider
  ↓
IslandBuildService / GrowthWorldEngine
  ↓
Game WorldState / Presentation Model
  ↓
Scene Layer
  ↓
Renderer / Painter
  ↓
Canvas / Flame Component
```

禁止：

```text
Renderer / Layer → Feature Provider
Renderer / Layer → Data Repository
Game Config → Feature Page
```

### App 启动链路

```text
main.dart
  ↓
AppBootstrap
  ↓
ProviderScope overrides / App Provider
  ↓
Router / Auth / Profile
  ↓
Feature Page
```

禁止：

```text
core/api → authProvider
core/storage → AppRepository
```

## 6. 依赖准入规则

| 来源 | 允许依赖 | 禁止依赖 |
|---|---|---|
| `core/` | Dart/Flutter 基础、纯模型、平台 wrapper | `feature/`、`provider/`、`data/`、`game/`、`router/`。 |
| `common/` | `core/`、纯参数模型 | provider、repository、feature page。 |
| `feature/` | `core/`、`common/`、`domain/`、自身 provider/widget/usecase | `data/repository/*_impl.dart`、game renderer 私有实现。 |
| `domain/` | `core/`、domain model | Flutter UI、Dio、SharedPreferences、provider。 |
| `data/` | `core/`、`domain/`、datasource、dto、mapper | UI、feature、game layer。 |
| `service/` | `core/`、domain repository、plugin wrapper | feature page、widget state。 |
| `game/` | `core/`、`common/painter`、game model/config | feature provider、repository、router。 |
| `router/` | app provider、feature page | repository 实现、game renderer。 |

## 7. 当前架构违规清单

### P0：必须优先处理

| 位置 | 问题 | 风险 | 治理动作 |
|---|---|---|---|
| `core/api/api_client.dart` → `providers/auth_provider.dart` | `core` 反向依赖 provider | 核心网络层绑定应用状态，难测试、难替换 | 抽 `SessionStore`，由 app 层注入 token 与 relogin 行为。 |
| `core/storage/user_app_preferences_sync.dart` → `data/repositories/app_repository.dart` | `core/storage` 依赖具体 repository | core 失去独立性 | 改依赖 `UserPreferencesRepository` 抽象。 |
| `design_system/companion_painter.dart` ↔ `world/rendering/companion_picture_cache.dart` | `design_system` 与 `world` 模块级双向依赖 | 容易形成循环、移动困难 | 把 companion 绘制统一下沉到 `common/painter/companion` 或 `game/character/painter`。 |
| `island/*` ↔ `world/*` | island 与 world 双向穿透 | game 相关代码边界不清 | 整体迁入 `game/`，建立 `game/model`。 |
| `data/repositories/app_repository.dart` | God Repository | 任意页面都可能误改全局 API | 拆 domain repository 接口与 data impl。 |
| 多个 page/widget 直接 `ref.read(appRepositoryProvider)` | UI 直连数据实现 | UI 难测试、业务编排散落 | 通过 feature provider/usecase 调用。 |

### P1：重要但可分批处理

| 位置 | 问题 | 风险 | 治理动作 |
|---|---|---|---|
| `design_system/growth_reward_dialog.dart` | 设计组件直接引用 repository/provider | common 组件携带业务 | 迁到 `feature/achievement/widget`。 |
| `design_system/moment_tag_chips.dart` | 设计组件引用 `growthTagProvider` | 纯展示组件不纯 | Provider 上移，组件只收参数。 |
| `design_system/companion_loading.dart` | 设计组件读取 app provider | common 依赖业务状态 | 拆纯 loading 与业务 wrapper。 |
| `island/widgets/growth_progress_panel.dart` → `features/landing/*` | island widget 依赖 landing feature | feature 互相依赖 | 抽公共 achievement progress component。 |
| `core/growth/island_unlock_catalog.dart` → `island/config` / `decor` | core 依赖 game/feature 配置 | core 被业务污染 | 移到 `game/island/config` 或 `feature/achievement`。 |
| `core/weather/weather_display.dart` → `island/config/weather_atmosphere_config.dart` | core weather 依赖 island config | core 边界破坏 | weather display 留 core，island atmosphere 移 game config。 |
| `core/l10n/locale_controller.dart` → `AppRepository` | l10n controller 依赖数据实现 | app 语言设置与数据层耦合 | 改 `ProfileRepository` / `UserPreferencesRepository` 抽象。 |
| `IslandWeatherService` 自建 Dio | 网络配置分裂 | token、超时、错误处理不一致 | 统一通过 `httpClientProvider` 或 weather datasource。 |

### P2：整理优化

| 位置 | 问题 | 风险 | 治理动作 |
|---|---|---|---|
| `features/`、`providers/`、`data/models/` 复数命名 | 命名不统一 | AI 搜索入口不稳定 | 统一迁到单数目录。 |
| 私有 provider 写在 page 文件中 | provider 不可复用、难定位 | 后续重复创建 | 迁到 feature provider 文件。 |
| 超长页面内多个私有 widget | 页面可读性低 | 修改误伤 | 拆到 `widget/`。 |
| 大型 config 文件集中 | 配置查找困难 | 修改冲突 | 按模型、catalog、query 拆。 |
| `Controller` 与 `Notifier` 命名混用 | 状态职责不清 | AI 容易新增重复概念 | Riverpod 状态统一 `Notifier`，纯流程类才叫 `Controller`。 |

## 8. 重构执行顺序

### Phase 1：建立边界，不移动业务

1. 新建 `domain/repository/` 接口。
2. 新建 `provider/repository_provider.dart`。
3. 用旧 `AppRepository` 做临时 adapter。
4. 新建依赖规则文档与 import 检查脚本。

### Phase 2：移除 P0 反向依赖

1. `core/api` 改依赖 `SessionStore`。
2. `core/storage` 改依赖 `UserPreferencesRepository`。
3. companion painter/cache 下沉到统一目录。
4. `island` 与 `world` 合并到 `game` 边界。

### Phase 3：拆 God Repository

1. 抽 `AuthRepository`，迁 auth page/provider。
2. 抽 `ProfileRepository`，迁 profile/locale/preferences。
3. 抽 `MomentRepository`，迁 story/record。
4. 抽 `MoodRepository`，迁 status。
5. 抽 `GrowthRepository`，迁 achievement/island unlock。
6. 抽 `VoiceRepository`，迁 voice transcription。

### Phase 4：拆超长文件

1. `app_repository.dart`。
2. `write_story_page.dart` 与 `moment_form_widgets.dart`。
3. `island_renderer.dart`、`cozy_hero_renderer.dart`、`companion_painter.dart`。
4. `building_layer.dart`、`character_layer.dart`。
5. `growth_island_configs.dart`、`decor_config.dart`。
6. 其他 feature 页面。

### Phase 5：统一目录命名

1. `features/` → `feature/`。
2. `data/models/` → `data/model/`。
3. `data/repositories/` → `data/repository/`。
4. `design_system/` → `common/component` / `common/painter`。
5. `world/` + 非页面 `island/` → `game/`。

## 9. 每次重构验收标准

- `flutter analyze` 无新增 error/warning。
- 相关 feature smoke test 可手动通过。
- import 方向没有新增违规。
- 原公开 provider 名称如要迁移，需要先保留临时 export，再分批替换。
- 单个非生成 Dart 文件目标不超过 500 行。
- Page 文件目标不超过 300 行，Widget 文件目标不超过 250 行，Renderer 文件目标不超过 400 行。

## 10. 禁止事项

- 禁止在 `core/` 中引用 `provider/`、`feature/`、`data/`。
- 禁止在 `common/` 中读取 provider 或调用 repository。
- 禁止在 `feature/page` 中直接调用 Dio repository 实现。
- 禁止在 `game/renderer` 中读取 Riverpod provider。
- 禁止新增 `AppRepository` 式聚合仓库。
- 禁止新增泛化 `Manager` 作为临时收纳箱。
- 禁止手动编辑 l10n 生成文件。
- 禁止借目录迁移修改业务逻辑。
