# Refactor Phase 1

## 本阶段范围

已按“一次只完成一个模块”的规则，分批处理 P0：

- `core/api` 反向依赖 `authProvider`
- `core/storage/user_app_preferences_sync.dart` 反向依赖 `AppRepository`
- `world/rendering/companion_picture_cache.dart` 反向依赖 `design_system/companion_painter.dart`
- `world/rendering/world_state_cache.dart` 反向依赖 `island/service/island_build_service.dart`
- `world` 环境系统反向依赖 `island/config` 下的时段/心情/天气氛围配置
- `data/repositories/app_repository.dart` God Repository
- page/widget/provider 直接读取 `appRepositoryProvider`
- `world` 目录直接 import `island/*` 实现文件

未处理 P1、P2 项。

## 修改文件

| 文件 | 修改内容 |
|---|---|
| `lib/core/api/api_session.dart` | 新增 `ApiSessionCallbacks` 抽象，统一提供 `readAccessToken` 与 `forceRelogin` 回调。 |
| `lib/core/api/api_client.dart` | 移除对 `providers/auth_provider.dart` 的直接引用，Dio interceptor 改为通过 `api_session.dart` 读取 token 和触发 401 登出。 |
| `lib/providers/auth_provider.dart` | 在创建 `AuthNotifier` 时注册 `ApiSessionCallbacks`，保持原有 token 注入和强制登出行为。 |
| `lib/core/storage/user_app_preferences_sync.dart` | 新增 `UserAppPreferencesPatcher` 抽象，移除对 `AppRepository` 的直接依赖。 |
| `lib/data/repositories/app_repository.dart` | 临时实现 `UserAppPreferencesPatcher`，保持现有偏好同步接口行为。 |
| `lib/providers/app_providers.dart` | `userAppPreferencesSyncProvider` 改为向 `UserAppPreferencesSync` 注入抽象 patcher。 |
| `lib/world/rendering/companion_picture_cache.dart` | 移除对 `CompanionPainter` 的直接导入，缓存层改为接收 `CompanionPicturePainter` 回调生成 `Picture`。 |
| `lib/world/scene/layers/character_layer.dart` | 将原有 `CompanionPainter.paint` 逻辑作为 rasterize 回调传给缓存层，保持绘制参数不变。 |
| `lib/world/rendering/world_state_cache.dart` | 移除对 `IslandBuildService` 的直接依赖，缓存层改为接收 `WorldStateBuilder` 回调。 |
| `lib/island/viewport/growth_world_viewport.dart` | 在调用缓存时注入原有 `IslandBuildService.build` 逻辑，保持世界构建参数不变。 |
| `lib/world/systems/config/day_phase_lighting_config.dart` | 新增环境系统时段光照配置，内容从 `island/config` 迁移。 |
| `lib/world/systems/config/mood_atmosphere_config.dart` | 新增环境系统心情氛围配置，内容从 `island/config` 迁移。 |
| `lib/world/systems/config/weather_atmosphere_config.dart` | 新增环境系统天气氛围配置，内容从 `island/config` 迁移。 |
| `lib/world/engine/world_state.dart` | 改为引用 `world/systems/config/day_phase_lighting_config.dart`。 |
| `lib/world/systems/mood_environment_controller.dart` | 改为引用同模块下的环境配置。 |
| `lib/features/island/growth_island_visual_debug_page.dart` | 改为引用新的时段光照配置位置。 |
| `lib/core/weather/weather_display.dart` | 改为引用新的天气氛围配置位置。 |
| `lib/island/service/island_style_resolver.dart` | 改为引用新的心情/天气氛围配置位置。 |
| `lib/island/config/day_phase_lighting_config.dart` | 改为兼容 export 包装，保留旧导入路径给测试/旧调用方。 |
| `lib/island/config/mood_atmosphere_config.dart` | 改为兼容 export 包装，避免重复定义。 |
| `lib/island/config/weather_atmosphere_config.dart` | 改为兼容 export 包装，避免重复定义。 |
| `lib/data/repositories/app_repository.dart` | 将 `AppRepository` 降级为内部 `StdayApiDatasource`，新增按职责拆分的 `AuthRepository`、`ProfileRepository`、`MomentRepository`、`VoiceRepository`、`MoodRepository`、`GrowthRepository`、`IslandConfigRepository`、`AppLocalizationRepository`、`UserPreferencesRepository` provider。 |
| `lib/providers/app_providers.dart` | 改为使用职责 repository provider，不再读取聚合仓库。 |
| `lib/providers/story_day_provider.dart` | 改为依赖 `MomentRepository`。 |
| `lib/providers/mood_status_provider.dart` | 改为分别依赖 `MomentRepository` 与 `MoodRepository`。 |
| `lib/providers/growth_observation_provider.dart` | 改为依赖 `GrowthRepository`。 |
| `lib/providers/growth_tag_provider.dart` | 改为依赖 `GrowthRepository`。 |
| `lib/providers/mood_report_check_in_provider.dart` | 改为依赖 `MoodRepository`。 |
| `lib/island/providers/growth_summary_provider.dart` | 改为依赖 `GrowthRepository` 与 `MomentRepository`。 |
| `lib/island/providers/building_unlocks_provider.dart` | 改为依赖 `GrowthRepository`。 |
| `lib/core/l10n/locale_controller.dart` | 改为依赖 `AppLocalizationRepository`。 |
| `lib/features/auth/auth_page.dart` | 改为依赖 `AuthRepository`。 |
| `lib/features/auth/register_page.dart` | 改为依赖 `AuthRepository`。 |
| `lib/features/today/write_story_page.dart` | 改为依赖 `MomentRepository` 与 `MoodRepository`。 |
| `lib/features/today/moment_form_widgets.dart` | 改为依赖 `VoiceRepository`。 |
| `lib/features/today/voice_analysis_poll.dart` | 改为依赖 `MomentRepository`。 |
| `lib/features/today/edit_moment_tags_page.dart` | 改为依赖 `MomentRepository`。 |
| `lib/features/today/moment_mood_picker.dart` | 改为依赖 `MomentRepository`。 |
| `lib/features/records/record_page.dart` | 改为依赖 `MomentRepository`。 |
| `lib/features/more/reminder_settings_page.dart` | 改为依赖 `UserPreferencesRepository`。 |
| `lib/features/more/my_level_page.dart` | 改为依赖 `MomentRepository`。 |
| `lib/features/more/companion_showcase_page.dart` | 改为依赖 `MomentRepository`。 |
| `lib/design_system/growth_reward_dialog.dart` | 改为依赖 `GrowthRepository` 与 `MomentRepository`，消除聚合仓库直连。 |
| `lib/world/island/island_visual_config.dart` | 新增 world 归属的岛屿视觉基准配置。 |
| `lib/world/island/island_placement.dart` | 新增 world 归属的岛屿几何放置约束。 |
| `lib/island/config/island_visual_config.dart` | 改为兼容 export 包装。 |
| `lib/island/placement/island_placement.dart` | 改为兼容 export 包装。 |
| `lib/common/island_contracts/*` | 新增 building/decor/growth contract export，供 world 层引用，避免 world 直接 import island 实现路径。 |
| `lib/world/engine/growth_world_engine.dart` | 改为引用 `world/island/island_visual_config.dart`。 |
| `lib/world/island/island_renderer.dart` | 改为引用同模块视觉配置。 |
| `lib/world/systems/prosperity_system.dart` | 改为引用 `world/island` 下的 placement/visual config。 |
| `lib/world/island/growth_world_ground_painter.dart` | 改为引用同模块 placement。 |
| `lib/world/island/island_shape_profile.dart` | 改为引用同模块 placement。 |
| `lib/world/island/realistic_lawn_renderer.dart` | 改为引用同模块 placement。 |
| `lib/world/island/lawn_obstacle_mask.dart` | 改为通过 common contract 引用 decor 能力。 |
| `lib/world/scene/layers/grass_foreground_layer.dart` | 改为通过 common contract 引用 decor/growth 配置，并引用 `world/island` 基础配置。 |
| `lib/world/scene/layers/island_layer.dart` | 改为通过 common contract 引用 decor 能力。 |
| `lib/world/scene/layers/decor_layer.dart` | 改为通过 common contract 引用 decor manager。 |
| `lib/world/scene/layers/building_layer.dart` | 改为通过 common contract 引用 building/growth 配置。 |
| `lib/design_system/growth_reward_dialog.dart` | 补充 async gap 后的 `context.mounted` guard，消除 analyzer info。 |
| `lib/features/today/widgets/story_voice_input_panel.dart` | 异步录音流程提前缓存本地化文案，避免 async gap 后读取 `BuildContext`。 |
| `lib/features/today/write_story_page.dart` | 照片同步失败文案在 `mounted` 后读取，消除 async gap info。 |
| `lib/design_system/moment_tag_chips.dart` | 移除 Riverpod 依赖，`MomentTagChipRow` 改为接收 catalog 参数的纯展示组件。 |
| `lib/features/today/edit_moment_tags_page.dart` | 在页面层读取标签 catalog 并传给 `MomentTagChipRow`。 |
| `lib/features/today/moment_detail_page.dart` | 在页面层读取标签 catalog 并传给 `MomentTagChipRow`。 |
| `lib/design_system/companion_loading.dart` | 移除 Riverpod wrapper，仅保留纯展示加载组件。 |
| `lib/features/shared/widgets/mood_companion_loading.dart` | 新增 Riverpod 版加载 wrapper，承载原 `MoodCompanionLoading*`。 |
| `lib/features/island/island_home_page.dart` | 改为引用 shared loading wrapper。 |
| `lib/features/more/my_level_page.dart` | 改为引用 shared loading wrapper。 |
| `lib/features/status/mood_status_page.dart` | 改为引用 shared loading wrapper。 |
| `lib/features/today/write_story_page.dart` | 改为引用 shared loading wrapper。 |
| `lib/features/achievement/growth_reward_actions.dart` | 新增成长奖励业务编排，承载 `fetchCurrentGrowthSummary` 与 `showGrowthRewardsAfterAction`。 |
| `lib/design_system/growth_reward_dialog.dart` | 移除 Riverpod/provider/repository 依赖，仅保留成长奖励弹窗、数值 overlay 和升级庆祝 UI。 |
| `lib/features/records/record_page.dart` | 改为引用 achievement 成长奖励 action。 |
| `lib/features/today/mood_today_card.dart` | 改为引用 achievement 成长奖励 action。 |
| `lib/features/today/daily_entry_flow.dart` | 改为引用 achievement 成长奖励 action。 |
| `lib/core/config/app_config.dart` | 预留 `API_SCHEME` / `API_HOST` / `API_PORT`，兼容完整 `API_BASE_URL`，便于后续 HTTP 快速切 HTTPS。 |
| `README.md` | 补充 API 配置和 HTTPS 切换说明。 |
| `lib/data/repositories/app_repository_facades.dart` | 新增 repository facade/provider part 文件，拆出原 `app_repository.dart` 中的仓储门面职责。 |
| `lib/data/repositories/app_repository.dart` | 保留 `StdayApiDatasource` HTTP 实现，引用 facade part，降低单文件职责。 |

## 为什么修改

`architecture_plan.md` 将 `core/api/api_client.dart -> providers/auth_provider.dart` 标记为 P0，因为 `core` 作为基础层不应反向依赖应用状态层。

本次修改后依赖方向变为：

```text
providers/auth_provider.dart
  ↓
core/api/api_session.dart

core/api/api_client.dart
  ↓
core/api/api_session.dart
```

`core/api` 不再知道 `authProvider` 的存在，只依赖会话抽象回调。这样保留了原有网络行为，同时减少核心层与应用状态层耦合。

`architecture_plan.md` 同时将 `core/storage/user_app_preferences_sync.dart -> data/repositories/app_repository.dart` 标记为 P0。本次将同步类改为依赖 `UserAppPreferencesPatcher` 抽象，当前仍由旧 `AppRepository` 临时实现该接口，后续拆分 repository 时可平滑替换为 `UserPreferencesRepository`。

`architecture_plan.md` 还将 `design_system/companion_painter.dart` 与 `world/rendering/companion_picture_cache.dart` 的双向依赖标记为 P0。本次让 `CompanionPictureCache` 只负责缓存与 Picture 生命周期，不再知道 `CompanionPainter` 的存在；具体绘制仍由原调用方 `character_layer.dart` 使用相同参数完成。

`architecture_plan.md` 将 `island/*` 与 `world/*` 的双向穿透标记为 P0。本次只处理其中一个小模块：`WorldStateCache`。它现在只负责 fingerprint 与缓存复用，具体 `WorldState` 构建由 `GrowthWorldViewport` 注入回调完成，避免 `world/rendering` 直接依赖 `island/service`。

同一 P0 下，环境系统配置原本位于 `island/config`，但被 `world/engine`、`world/systems`、`core/weather` 共同引用。本次将时段光照、心情氛围、天气氛围三份纯配置迁移到 `world/systems/config`，让环境计算归属到 world system，减少 `world -> island/config` 穿透。

`AppRepository` 原本同时承载鉴权、profile、moment、voice、mood、growth、i18n、island config 等职责。本次保留原 HTTP endpoint 实现为 `StdayApiDatasource`，在外层新增按职责拆分的 Repository facade，并将所有调用点切换到具体 provider。代码中已不再存在 `AppRepository` / `appRepositoryProvider`。

对剩余 `world -> island` 直接实现引用，本次先将基础 placement/visual config 下沉到 `world/island`，并为 decor/building/growth 配置建立 `common/island_contracts` contract export。这样 `world` 不再直接引用 `island/*` 实现路径，后续大目录迁移时可以逐步把 contract 背后的实现迁到 `game/`。

后续服务端从 HTTP 切 HTTPS 时，不再需要搜索业务代码改 URL。现在可以通过完整 `API_BASE_URL` 覆盖，也可以只传 `--dart-define=API_SCHEME=https`，由 `AppConfig` 统一组装 baseUrl。

Repository facade/provider 已从 `app_repository.dart` 拆到 `app_repository_facades.dart`，外部 import 路径保持不变。当前 `StdayApiDatasource` 仍集中保存 endpoint 实现，后续可继续按 auth/profile/moment/mood/growth/i18n 拆成 datasource part 或独立 datasource 文件。

## 保持不变

- 未修改接口路径、请求参数、响应解析。
- 默认开发 API 地址仍为 `http://127.0.0.1:9000`；生产空值归一化仍指向生产域名。
- 未修改登录、登出、401 处理业务逻辑。
- 未修改偏好同步 key、本地缓存策略、远端 patch payload。
- 未修改 companion 绘制参数、缓存 key、缓存容量和 Picture 释放策略。
- 未修改 WorldState fingerprint、缓存清理策略和 island 构建参数。
- 未修改时段光照、心情氛围、天气氛围配置的常量值和计算规则。
- 未修改任何 repository 方法的 API path、payload、解析模型和超时设置。
- 未修改 island placement、visual config、decor、building、growth 配置的常量值。
- 未修改 UI、路由、页面行为。
- 未修改任何 Dart 文件之外的业务资源。
- async gap 修复仅调整 `BuildContext` 使用时机，不改变提示文案、录音流程、照片同步流程。
- design_system 分层修复只移动业务读取位置，不改变组件视觉参数和调用语义。

## 遗留问题

剩余问题不再是 P0 或 analyzer 问题，归入后续 P2 架构治理：

- `common/island_contracts/*` 目前是过渡 contract export，后续目录重排时应把背后的 decor/building/growth 实现正式迁到 `game/` 或 `domain/`。
- `StdayApiDatasource` 仍集中保存 HTTP endpoint 实现，后续可继续按 endpoint 域拆成 remote datasource part 或独立 datasource 文件，但外部已不再以 God Repository 方式使用。
- 超过 500 行文件拆分属于 P2/P1 后续工作，本轮未展开。

## 验证

已运行 `flutter analyze`。结果：`No issues found!`

已运行 `flutter test test/app_config_test.dart`。结果：`All tests passed!`

已静态核对：

- `lib/core/api/` 中不再出现 `authProvider` 或 `providers/auth_provider` 引用。
- `lib/core/storage/` 中不再出现 `AppRepository` 或 `data/repositories` 引用。
- `lib/world/rendering/companion_picture_cache.dart` 中不再出现 `CompanionPainter`、`design_system` 或 `companion_painter.dart` 引用。
- `lib/world/rendering/world_state_cache.dart` 中不再出现 `IslandBuildService`、`buildService` 或 `island/service` 引用。
- 代码中不再出现 `AppRepository` 或 `appRepositoryProvider`。
- `lib/world/` 中不再直接 import `../../../island/...` 或 `../../island/...` 的外部 island 实现路径；只保留对自身 `world/island` 子模块的引用。
- `lib/design_system/` 中不再出现 Riverpod、provider、repository 或 `WidgetRef` 依赖。
- API 协议可通过 `API_SCHEME` 独立切换，仍兼容旧的 `API_BASE_URL` 完整覆盖。
