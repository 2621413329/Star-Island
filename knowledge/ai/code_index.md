# 代码索引

| | |
|---|---|
| 编号 | KB-04 |
| 回答的问题 | 每个源文件在哪个目录；新文件放哪 |
| 不负责 | 业务怎么串、接口字段、画面层序 |
| 何时更新 | 新增、删除或移动源文件；目录职责变了 |
| 路由 | 只在 `knowledge/README.md` |



## 目录

- [新文件放哪](#kb-新文件放哪)
- [客户端 stday/lib](#kb-客户端-stday-lib)
  - [stday/lib](#kb-stday-lib)
  - [stday/lib/common/island_contracts](#kb-stday-lib-common-island-contracts)
  - [stday/lib/core/api](#kb-stday-lib-core-api)
  - [stday/lib/core/audio](#kb-stday-lib-core-audio)
  - [stday/lib/core/bootstrap](#kb-stday-lib-core-bootstrap)
  - [stday/lib/core/config](#kb-stday-lib-core-config)
  - [stday/lib/core/constants](#kb-stday-lib-core-constants)
  - [stday/lib/core/growth](#kb-stday-lib-core-growth)
  - [stday/lib/core/l10n](#kb-stday-lib-core-l10n)
  - [stday/lib/core/layout](#kb-stday-lib-core-layout)
  - [stday/lib/core/legal](#kb-stday-lib-core-legal)
  - [stday/lib/core/membership](#kb-stday-lib-core-membership)
  - [stday/lib/core/models](#kb-stday-lib-core-models)
  - [stday/lib/core/notifications](#kb-stday-lib-core-notifications)
  - [stday/lib/core/permissions](#kb-stday-lib-core-permissions)
  - [stday/lib/core/platform](#kb-stday-lib-core-platform)
  - [stday/lib/core/speech](#kb-stday-lib-core-speech)
  - [stday/lib/core/storage](#kb-stday-lib-core-storage)
  - [stday/lib/core/sync](#kb-stday-lib-core-sync)
  - [stday/lib/core/theme](#kb-stday-lib-core-theme)
  - [stday/lib/core/utils](#kb-stday-lib-core-utils)
  - [stday/lib/core/voice](#kb-stday-lib-core-voice)
  - [stday/lib/core/weather](#kb-stday-lib-core-weather)
  - [stday/lib/core/widgets](#kb-stday-lib-core-widgets)
  - [stday/lib/data/local](#kb-stday-lib-data-local)
  - [stday/lib/data/models](#kb-stday-lib-data-models)
  - [stday/lib/data/repositories](#kb-stday-lib-data-repositories)
  - [stday/lib/design_system](#kb-stday-lib-design-system)
  - [stday/lib/features/achievement](#kb-stday-lib-features-achievement)
  - [stday/lib/features/auth](#kb-stday-lib-features-auth)
  - [stday/lib/features/home](#kb-stday-lib-features-home)
  - [stday/lib/features/home/providers](#kb-stday-lib-features-home-providers)
  - [stday/lib/features/home/widgets](#kb-stday-lib-features-home-widgets)
  - [stday/lib/features/island](#kb-stday-lib-features-island)
  - [stday/lib/features/island/widgets](#kb-stday-lib-features-island-widgets)
  - [stday/lib/features/landing](#kb-stday-lib-features-landing)
  - [stday/lib/features/legal](#kb-stday-lib-features-legal)
  - [stday/lib/features/membership](#kb-stday-lib-features-membership)
  - [stday/lib/features/more](#kb-stday-lib-features-more)
  - [stday/lib/features/more/widgets](#kb-stday-lib-features-more-widgets)
  - [stday/lib/features/onboarding](#kb-stday-lib-features-onboarding)
  - [stday/lib/features/onboarding/widgets](#kb-stday-lib-features-onboarding-widgets)
  - [stday/lib/features/records](#kb-stday-lib-features-records)
  - [stday/lib/features/records/widgets](#kb-stday-lib-features-records-widgets)
  - [stday/lib/features/shared/widgets](#kb-stday-lib-features-shared-widgets)
  - [stday/lib/features/status](#kb-stday-lib-features-status)
  - [stday/lib/features/status/widgets](#kb-stday-lib-features-status-widgets)
  - [stday/lib/features/today](#kb-stday-lib-features-today)
  - [stday/lib/features/today/widgets](#kb-stday-lib-features-today-widgets)
  - [stday/lib/island/anchor](#kb-stday-lib-island-anchor)
  - [stday/lib/island/building](#kb-stday-lib-island-building)
  - [stday/lib/island/config](#kb-stday-lib-island-config)
  - [stday/lib/island/debug](#kb-stday-lib-island-debug)
  - [stday/lib/island/decor](#kb-stday-lib-island-decor)
  - [stday/lib/island/generator](#kb-stday-lib-island-generator)
  - [stday/lib/island/placement](#kb-stday-lib-island-placement)
  - [stday/lib/island/providers](#kb-stday-lib-island-providers)
  - [stday/lib/island/service](#kb-stday-lib-island-service)
  - [stday/lib/island/viewport](#kb-stday-lib-island-viewport)
  - [stday/lib/island/widgets](#kb-stday-lib-island-widgets)
  - [stday/lib/l10n](#kb-stday-lib-l10n)
  - [stday/lib/providers](#kb-stday-lib-providers)
  - [stday/lib/router](#kb-stday-lib-router)
  - [stday/lib/services](#kb-stday-lib-services)
  - [stday/lib/world/behaviors](#kb-stday-lib-world-behaviors)
  - [stday/lib/world/engine](#kb-stday-lib-world-engine)
  - [stday/lib/world/island](#kb-stday-lib-world-island)
  - [stday/lib/world/preview](#kb-stday-lib-world-preview)
  - [stday/lib/world/rendering](#kb-stday-lib-world-rendering)
  - [stday/lib/world/scene](#kb-stday-lib-world-scene)
  - [stday/lib/world/scene/layers](#kb-stday-lib-world-scene-layers)
  - [stday/lib/world/systems](#kb-stday-lib-world-systems)
  - [stday/lib/world/systems/config](#kb-stday-lib-world-systems-config)
- [客户端测试 stday/test](#kb-客户端测试-stday-test)
- [原生](#kb-原生)
- [后端 backend](#kb-后端-backend)
  - [backend/app](#kb-backend-app)
  - [backend/app/agents](#kb-backend-app-agents)
  - [backend/app/api](#kb-backend-app-api)
  - [backend/app/api/v1](#kb-backend-app-api-v1)
  - [backend/app/api/v1/endpoints](#kb-backend-app-api-v1-endpoints)
  - [backend/app/config](#kb-backend-app-config)
  - [backend/app/core](#kb-backend-app-core)
  - [backend/app/database](#kb-backend-app-database)
  - [backend/app/exceptions](#kb-backend-app-exceptions)
  - [backend/app/middleware](#kb-backend-app-middleware)
  - [backend/app/models](#kb-backend-app-models)
  - [backend/app/prompts](#kb-backend-app-prompts)
  - [backend/app/rag](#kb-backend-app-rag)
  - [backend/app/repositories](#kb-backend-app-repositories)
  - [backend/app/schemas](#kb-backend-app-schemas)
  - [backend/app/services](#kb-backend-app-services)
  - [backend/app/tests](#kb-backend-app-tests)
  - [backend/app/utils](#kb-backend-app-utils)
  - [backend/alembic/versions](#kb-backend-alembic-versions)
  - [backend/scripts](#kb-backend-scripts)

每个目录写职责，每个源文件写类型名或入口函数。业务链路看 KB-03，不要在这里重写。

<a id="kb-新文件放哪"></a>

## 新文件放哪

| 要加的东西 | 放哪 | 不要放哪 |
|---|---|---|
| 新页面 | `stday/lib/features/<模块>/<名>_page.dart` | `core/`、`world/`、`design_system/` |
| 只属于该页的控件 | `stday/lib/features/<模块>/widgets/` | `design_system/`（那里不能读 provider） |
| 纯展示控件 | `stday/lib/design_system/` | 任何会 `ref.watch` 的目录 |
| 跨页面状态 | `stday/lib/providers/` | 不要把单页状态放成全局 |
| HTTP | `stday/lib/data/repositories/app_repository.dart` 里的 facade | 页面里直接 new Dio |
| 主岛建筑、装饰、放置 | `stday/lib/island/` 与 `stday/lib/world/` | 副岛锚点不要写进 `island/placement/` |
| 副岛预览 | `stday/lib/world/preview/` 与 `StoryIslandLayout` | `island/placement/` |
| 后端接口 | `backend/app/api/v1/endpoints/` + `services/` + `schemas/` | `agents/`、`story_engine/`、`prompts/`（空壳） |

`stday/DIRECTORY.md` 里的 `app/`、`feature/`、`game/`、`domain/` 是旧目标，当前代码不在那些目录。新文件按上表放。

<a id="kb-客户端-stday-lib"></a>

## 客户端 `stday/lib`

<a id="kb-stday-lib"></a>

### `stday/lib`

客户端入口。业务不要堆在这里。

- `stday/lib/app.dart` — StdayApp 与路由壳。
- `stday/lib/debug_growth_island_visual_main.dart` — 主岛视觉调试入口，不是正式 App 启动。
- `stday/lib/main.dart` — 正式启动。Host 顺序在 runApp 之前接好。

<a id="kb-stday-lib-common-island-contracts"></a>

### `stday/lib/common/island_contracts`

过渡再导出。真正实现在 island/ 与 world/。新代码不要只改这里。

- `stday/lib/common/island_contracts/building_config.dart` — 再导出 ../../island/config/building_config.dart
- `stday/lib/common/island_contracts/building_factory.dart` — 再导出 ../../island/building/building_factory.dart
- `stday/lib/common/island_contracts/decor_config.dart` — 再导出 ../../island/decor/decor_config.dart
- `stday/lib/common/island_contracts/decor_manager.dart` — 再导出 ../../island/decor/decor_manager.dart
- `stday/lib/common/island_contracts/decor_placement_resolver.dart` — 再导出 ../../island/decor/decor_placement_resolver.dart
- `stday/lib/common/island_contracts/decor_scale_resolver.dart` — 再导出 ../../island/decor/decor_scale_resolver.dart
- `stday/lib/common/island_contracts/grass_skirt_painter.dart` — 再导出 ../../island/decor/grass_skirt_painter.dart
- `stday/lib/common/island_contracts/growth_island_config_models.dart` — 再导出 ../../island/config/growth_island_config_models.dart
- `stday/lib/common/island_contracts/growth_island_configs.dart` — 再导出 ../../island/config/growth_island_configs.dart

<a id="kb-stday-lib-core-api"></a>

### `stday/lib/core/api`

Dio、会话、401。不能 import authProvider。

- `stday/lib/core/api/api_client.dart` — ApiException；dioProvider。面向用户的网络异常提示（不暴露后端地址与技术细节）。
- `stday/lib/core/api/api_session.dart` — AccessTokenReader, ForceReloginCallback, ApiSessionCallbacks

<a id="kb-stday-lib-core-audio"></a>

### `stday/lib/core/audio`

BGM / 音效资源名与播放。

- `stday/lib/core/audio/app_audio_assets.dart` — AppBgmContext, AppSfx, AppAudioAssets
- `stday/lib/core/audio/app_audio_controller.dart` — AppAudioController
- `stday/lib/core/audio/app_audio_settings.dart` — AppAudioSettings

<a id="kb-stday-lib-core-bootstrap"></a>

### `stday/lib/core/bootstrap`

启动时组装依赖，交给 ProviderScope。

- `stday/lib/core/bootstrap/app_bootstrap.dart` — AppBootstrap。在 [main] 中从 SharedPreferences 同步读出，避免首帧时登录态未知导致白屏/闪跳。

<a id="kb-stday-lib-core-config"></a>

### `stday/lib/core/config`

API 地址唯一入口 AppConfig。

- `stday/lib/core/config/app_config.dart` — AppConfig。开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。

<a id="kb-stday-lib-core-constants"></a>

### `stday/lib/core/constants`

故事岛、陪伴、心情、等级、内购商品等常量。和后端同名配置必须一起改。

- `stday/lib/core/constants/catalog.dart` — 再导出 mood_types.dart
- `stday/lib/core/constants/companion_base_asset.dart` — companionBaseAssetId, normalizeEmotionId, companionBaseAssetPath
- `stday/lib/core/constants/companion_prop_labels.dart` — CompanionPropLabels。配饰 id / 资源文件名 → 中文展示名（存储与展示统一使用）。
- `stday/lib/core/constants/companion_roles.dart` — CompanionRoles, UserProfileCompanionRoleX。登岛伙伴角色 id（与 RBAC 权限角色无关）。
- `stday/lib/core/constants/companion_write_asset.dart` — CompanionWriteAssets。「记录今天的故事」等写作入口使用的角色立绘资源。 新增角色时： 1. 将 PNG 放入 [assetDir] 2. 在 [assetFileByRoleId]…
- `stday/lib/core/constants/emotion_catalog.dart` — EmotionDefinition。资源替换说明见 [assets/images/mood_faces/README.md]。
- `stday/lib/core/constants/growth_tag_seed.dart` — buildBundledGrowthTagCatalog。内置成长标签库（与后端 [GROWTH_TAG_SEED] 一致），供离线编辑与 API 失败时回退。
- `stday/lib/core/constants/island_weather.dart` — IslandWeather, IslandSkyStyle
- `stday/lib/core/constants/moment_limits.dart` — 今日日常补充说明（note）长度与展示相关常量。
- `stday/lib/core/constants/mood_types.dart` — MoodOption, MoodFaceType。每日心情 · 表情插图目录：`assets/images/mood_faces/`
- `stday/lib/core/constants/story_island_building_catalog.dart` — StoryIslandBuildingCatalog。副岛各标签 Lv1–Lv10 建筑名称（与 backend story_island_buildings.py 一致）。 Lv1 外圈起步 → Lv10 中心…
- `stday/lib/core/constants/story_island_layout.dart` — StoryIslandLayout。副岛建筑布局与缩放（不影响主岛 [IslandBuildingLayout]）。
- `stday/lib/core/constants/story_island_size.dart` — StoryIslandSizeOption。每日上限：副岛待办成长 15；副岛日常入驻成长 20；日常入驻用户经验 20。

<a id="kb-stday-lib-core-growth"></a>

### `stday/lib/core/growth`

用户等级、当日经验、解锁庆祝。数值与 growth_points_service.py 对齐。

- `stday/lib/core/growth/daily_level_unlock_prompt.dart` — maybeShowDailyLevelUnlockPrompt, showLevelUnlockCelebration。进入岛屿/欢迎页时：若等级高于上次已确认等级，补弹解锁提示。
- `stday/lib/core/growth/growth_system.dart` — GrowthSystem, GrowthSummary, IslandGrowthStage。与后端 `growth_points_service` 规则一致的客户端成长计算（离线兜底）。
- `stday/lib/core/growth/island_unlock_catalog.dart` — IslandUnlockItem, IslandUnlockKind, IslandUnlockLevelGroup。岛屿解锁目录（Lv.1–20）：主岛装饰 + 成长建筑，与 [DecorConfigs] / [GrowthIslandConfigs] 同步。
- `stday/lib/core/growth/level_title_assets.dart` — LevelTitleAssets, LevelTitleBadgeImage。等级称号图片资源（`assets/images/titles/`，文件名为拼音）。
- `stday/lib/core/growth/level_unlock_celebration.dart` — collectNewUnlockItems, levelUnlockCelebrationSubline, levelUnlockRangeSummary。收集 (fromLevel, currentLevel] 区间内新解锁的内容。
- `stday/lib/core/growth/level_unlock_preview.dart` — LevelUnlockPreviewAssets。等级 / 装饰解锁预览。
- `stday/lib/core/growth/today_mood_display.dart` — resolveTodayLandingMoodId, normalizeEmotionId, companionWeatherLabelForEmotionId。引导页/小星仔：仅当今日已选择感受时返回 profile 心情，否则默认兴奋。
- `stday/lib/core/growth/week_activity.dart` — WeekActivity。本周登岛 / 活跃天数统计（周一至周日）。

<a id="kb-stday-lib-core-l10n"></a>

### `stday/lib/core/l10n`

文案读取扩展。生成物在 lib/l10n。

- `stday/lib/core/l10n/l10n_extension.dart` — L10nContext。统一访问国际化文案：`context.l10n.saveSuccess`
- `stday/lib/core/l10n/locale_controller.dart` — LocaleSettings, LocaleController；localeControllerProvider

<a id="kb-stday-lib-core-layout"></a>

### `stday/lib/core/layout`

壳层边距和自适应布局数字。

- `stday/lib/core/layout/app_layout.dart` — AppLayout。全局布局常量（基于 390 宽设计稿）。
- `stday/lib/core/layout/main_shell_insets.dart` — MainShellInsets。MainShell 内页内容区安全边距（浮动底栏 + 状态栏）。

<a id="kb-stday-lib-core-legal"></a>

### `stday/lib/core/legal`

用户协议与隐私政策正文，页面只负责展示。

- `stday/lib/core/legal/legal_documents.dart` — LegalDocument, LegalSection。应用法律文档正文（用户协议、隐私政策）——生产环境正式版。
- `stday/lib/core/legal/legal_urls.dart` — LegalUrls。App Store / 应用内使用的公开法律文档 URL。 正式站点：https://lcxxingyu.fun （官网 SPA 路由 /privacy、/t…

<a id="kb-stday-lib-core-membership"></a>

### `stday/lib/core/membership`

内购商品 ID 与 VIP 门闩。

- `stday/lib/core/membership/iap_lifecycle_host.dart` — IapLifecycleHost。登录后在 iOS 上初始化 App Store 内购监听。
- `stday/lib/core/membership/iap_product_ids.dart` — IapProductIds, VipPlanUi。App Store Connect 内购商品 ID（须与 member_products.product_id 一致）。
- `stday/lib/core/membership/member_lifecycle_host.dart` — MemberLifecycleHost。App 生命周期内按需刷新会员状态。
- `stday/lib/core/membership/vip_guard.dart` — VipFeatureMask。未开通 VIP 时弹出提示。

<a id="kb-stday-lib-core-models"></a>

### `stday/lib/core/models`

不依赖页面的小模型。

- `stday/lib/core/models/character_mood.dart` — CharacterMood。角色与世界环境共用的情绪枚举。
- `stday/lib/core/models/companion_spec.dart` — CompanionSpec。由 AI / 后端 visual_payload 驱动的小人表演规格。
- `stday/lib/core/models/mood_island_config.dart` — MoodIslandConfig, MoodIslandRegistry。每种心情独立岛屿配置（与后端 mood_island_styles 表对应）。
- `stday/lib/core/models/reminder_record.dart` — ReminderRecord。用户自定义本地提醒记录，持久化在 [app_preferences.custom_reminders]。
- `stday/lib/core/models/user_companion.dart` — UserCompanion, CompanionStoryContext。当前用户小人的基础样貌（全局统一对象）。 [companionRoleId] 为登岛角色；[renderGender] 供绘制层选择男女向资源。

<a id="kb-stday-lib-core-notifications"></a>

### `stday/lib/core/notifications`

本地提醒调度与通知附件。

- `stday/lib/core/notifications/notification_attachment_storage.dart` — 再导出 notification_attachment_storage_stub.dart
- `stday/lib/core/notifications/notification_attachment_storage_io.dart` — persistNotificationIconPng, notificationIconFileExists
- `stday/lib/core/notifications/notification_attachment_storage_stub.dart` — persistNotificationIconPng, notificationIconFileExists
- `stday/lib/core/notifications/reminder_lifecycle_host.dart` — ReminderLifecycleHost。App 回到前台时重新注册本地提醒（应对部分机型清掉闹钟）。
- `stday/lib/core/notifications/reminder_notification_bitmap.dart` — ReminderNotificationBitmap。将提醒编辑页所选图标（PNG / WebP / SVG）转为各平台通知可用资源。
- `stday/lib/core/notifications/story_reminder_service.dart` — ReminderScheduleStatus, StoryReminderService；storyReminderServiceProvider

<a id="kb-stday-lib-core-permissions"></a>

### `stday/lib/core/permissions`

麦克风和相册权限。

- `stday/lib/core/permissions/media_pick_permissions.dart` — MediaPickPermissions。日常照片拍摄 / 选图前的运行时权限申请。
- `stday/lib/core/permissions/microphone_permission.dart` — MicrophonePermission。日常语音录制前的麦克风权限（iOS / Android）。

<a id="kb-stday-lib-core-platform"></a>

### `stday/lib/core/platform`

设备信息。

- `stday/lib/core/platform/device_profile.dart` — AppTerminal, DeviceProfile。终端形态：用于布局与渲染管线分流。

<a id="kb-stday-lib-core-speech"></a>

### `stday/lib/core/speech`

按住说话的录音与转写请求，不是语音日常。

- `stday/lib/core/speech/speech_note_merge.dart` — mergeSpeechIntoNote, insertSpeechAtSelection, insertSpeechAtSelection

<a id="kb-stday-lib-core-storage"></a>

### `stday/lib/core/storage`

本地偏好：当日心情弹层、升级庆祝、偏好同步。

- `stday/lib/core/storage/daily_level_unlock_store.dart` — DailyLevelUnlockStore。记录用户已确认「等级解锁提示」的最高等级，避免重复弹窗。
- `stday/lib/core/storage/daily_mood_prompt_store.dart` — DailyMoodPromptStore。记录每位用户每日首次「今日心情 / 今日日常」引导的日历日（yyyy-MM-dd）。
- `stday/lib/core/storage/user_app_preferences_sync.dart` — UserAppPreferencesPatcher, UserAppPreferencesSync

<a id="kb-stday-lib-core-sync"></a>

### `stday/lib/core/sync`

日常幂等 client_event_id。

- `stday/lib/core/sync/client_event_id.dart` — ClientEventId。Generates client-side event ids used for idempotent sync requests.

<a id="kb-stday-lib-core-theme"></a>

### `stday/lib/core/theme`

字体与心情主题色。

- `stday/lib/core/theme/app_fonts.dart` — appFontFamily, appTextStyle。统一中文界面字体，避免 Windows 上 Roboto 缺字导致同一段文字混用多种字体（粗细不一）。
- `stday/lib/core/theme/mood_theme.dart` — MoodPalette

<a id="kb-stday-lib-core-utils"></a>

### `stday/lib/core/utils`

纯函数：日期、标签统计、台词占位符、心情统计。

- `stday/lib/core/utils/api_datetime.dart` — parseApiDateTime, parseApiDateTime, formatMembershipExpireDate。API 时间解析：无时区偏移时按 UTC 理解（与后端 timezone-aware 字段一致）。
- `stday/lib/core/utils/companion_base_expression.dart` — companionBaseExpressionFromMoodId, companionBaseAssetId, companionBaseExpressionFromMood。将心情 id 映射到 `assets/images/companion/base/{gender}_{拼音 id}.png`。
- `stday/lib/core/utils/companion_dialogue.dart` — applyCompanionNickname, applyCompanionNicknameLines。小人对话台词：存储 `{nickname}` 模板，展示时替换为当前昵称。
- `stday/lib/core/utils/companion_prop_infer.dart` — CompanionPropInfer。根据标签与备注推断小人配饰（与后端 companion_action_ai 规则对齐）。
- `stday/lib/core/utils/moment_date_groups.dart` — MomentDateGroup。按 [momentDate] 分组的日常列表（日期新 → 旧，组内保持接口顺序）。
- `stday/lib/core/utils/moment_highlight.dart` — emotionValenceScore, momentValenceScore, emotionValenceScore。情绪高涨程度（越大越优先展示）。
- `stday/lib/core/utils/moment_tags.dart` — momentPrimaryCategory, momentSecondaryTags, momentAllTagLabels。日常一级分类（优先 AI 字段，兼容旧 event_tags）。
- `stday/lib/core/utils/mood_face_paths.dart` — moodFaceAssetCandidates, moodFaceAssetPath。已有性别分图的感受（仅旧五档 + 后续补齐的拼音图）。
- `stday/lib/core/utils/mood_period.dart` — MoodStatusPeriod, MoodStatusPeriodX。成长轨迹页独立的心情周期筛选（与今日记录日期筛选解耦）。
- `stday/lib/core/utils/mood_stats.dart` — EventTagCount。五档心情在 [0, 1] 上的取值：生气=0，超开心=1。
- `stday/lib/core/utils/soft_text_trim.dart` — softTrimText。在标点或自然边界处截断，避免句中硬切；超出 [maxChars] 才省略。
- `stday/lib/core/utils/story_island_names.dart` — defaultStoryIslandName, storyIslandNameStem, storyIslandFullName。各分类默认岛屿全名（含「岛」）。
- `stday/lib/core/utils/story_island_visual.dart` — momentBelongsToStoryIsland, storyIslandCategoryForMoment, storyIslandCategoryIcon。日常是否归属指定故事岛。
- `stday/lib/core/utils/tag_stats.dart` — TagStatItem
- `stday/lib/core/utils/week_check_in_days.dart` — parseCalendarDate, sameCalendarDay, defaultWeekCheckInDays

<a id="kb-stday-lib-core-voice"></a>

### `stday/lib/core/voice`

语音日常的录音文件和 URL。

- `stday/lib/core/voice/story_voice_recorder.dart` — StoryVoiceRecorder。日常语音录制（m4a / AAC）。
- `stday/lib/core/voice/voice_file_io.dart` — readVoiceFileBytes, deleteVoiceFile, voiceFileExists
- `stday/lib/core/voice/voice_file_io_export.dart` — 再导出 voice_file_io_stub.dart
- `stday/lib/core/voice/voice_file_io_stub.dart` — readVoiceFileBytes, deleteVoiceFile, voiceFileExists
- `stday/lib/core/voice/voice_url.dart` — momentVoiceFullUrl, formatVoiceDuration

<a id="kb-stday-lib-core-weather"></a>

### `stday/lib/core/weather`

天气快照。首页默认先不请求。

- `stday/lib/core/weather/island_weather_service.dart` — IslandWeatherService。通过 Open-Meteo 获取用户所在地当日天气（无需 API Key）。
- `stday/lib/core/weather/real_weather_snapshot.dart` — RealWeatherSnapshot。来自 Open-Meteo 的当日实况天气快照。
- `stday/lib/core/weather/weather_display.dart` — islandWeatherKind, weatherDisplayLabel, weatherDisplayLabelFromSnapshot。将 Open-Meteo 快照转为展示用语义。

<a id="kb-stday-lib-core-widgets"></a>

### `stday/lib/core/widgets`

core 内的少量通用控件。

- `stday/lib/core/widgets/island_widget_day_rollover_host.dart` — IslandWidgetDayRolloverHost。监听本地日历日切换：0 点或回到前台跨日后，刷新今日数据并同步桌面小组件。

<a id="kb-stday-lib-data-local"></a>

### `stday/lib/data/local`

成长标签本地缓存。

- `stday/lib/data/local/growth_tag_catalog_cache.dart` — GrowthTagCatalogCache。成长标签库本地缓存，供离线展示与 API 失败时回退。

<a id="kb-stday-lib-data-models"></a>

### `stday/lib/data/models`

接口模型。字段变更要同时看 datasource 和后端 schema。

- `stday/lib/data/models/building_unlock_models.dart` — BuildingUnlockModel
- `stday/lib/data/models/growth_observation_models.dart` — WeeklySummary
- `stday/lib/data/models/growth_tag_models.dart` — GrowthTagModel, GrowthTagCategoryModel
- `stday/lib/data/models/iap_models.dart` — IapVerifyResultModel
- `stday/lib/data/models/member_models.dart` — MemberMeModel
- `stday/lib/data/models/mood_check_in_models.dart` — WeekCheckInDay, MoodReportCheckIn, TodayMoodRecapAction
- `stday/lib/data/models/mood_report_models.dart` — MoodPeriodSummaryModel, DailyMoodReportModel
- `stday/lib/data/models/paginated_moments_model.dart` — PaginatedMomentsModel
- `stday/lib/data/models/profile_models.dart` — EmotionFragmentSummary, UserProfileModel, MomentPhotoModel
- `stday/lib/data/models/story_island_models.dart` — StoryIslandModel, StoryIslandTaskModel, StoryIslandProgressLevelModel

<a id="kb-stday-lib-data-repositories"></a>

### `stday/lib/data/repositories`

12 个 facade 和唯一的 HTTP 实现 StdayApiDatasource。

- `stday/lib/data/repositories/app_repository.dart` — StdayApiDatasource。客户端唯一的 HTTP 实现。
- `stday/lib/data/repositories/app_repository_facades.dart` — AuthRepository、ProfileRepository、MomentRepository、StoryIslandRepository、VoiceRepository、MoodRepository、GrowthRepository、IslandConfigRepository、AppLocalizationRepository、UserPreferencesRepository、MemberRepository、IapRepository。

<a id="kb-stday-lib-design-system"></a>

### `stday/lib/design_system`

纯 UI。禁止 ref.watch、ref.read 和 repository。

- `stday/lib/design_system/adaptive_viewport.dart` — AdaptiveViewport, PhoneViewportDesign。多端自适应外框：手机全屏、平板宽屏、桌面手机框预览。
- `stday/lib/design_system/app_feedback.dart` — AppFeedback。应用内反馈：弱提示（同步/更新）与强提示（成长里程碑）。
- `stday/lib/design_system/app_startup_splash.dart` — AppStartupSplash。与原生启动页、应用暖色基调一致，覆盖首帧路由/资料未就绪时的空白。
- `stday/lib/design_system/auth_hero_card.dart` — AuthHeroCard。登录/注册页顶部英雄区：背景图 + 前景小人 + 标题。
- `stday/lib/design_system/companion_asset_avatar.dart` — CompanionAssetAvatar。图片化小人：本体和配饰都来自 assets，方便后续直接替换 PNG。
- `stday/lib/design_system/companion_avatar.dart` — CompanionAvatar, CompanionAvatarState
- `stday/lib/design_system/companion_base_asset_catalog.dart` — CompanionBaseAssetCatalog。从 manifest 同步解析 companion/base PNG，避免逐帧尝试多条路径导致加载慢。
- `stday/lib/design_system/companion_loading.dart` — CompanionLoadingMotion, CompanionLoadingView, CompanionLoadingScaffold。按当前心情映射小人的表情与加载时的循环动作。
- `stday/lib/design_system/companion_painter.dart` — CompanionPainter。半透明精神体：按 expression / prop / tint 绘制情绪、姿态与经历物件。
- `stday/lib/design_system/companion_prop_asset_catalog.dart` — CompanionPropAssetCatalog
- `stday/lib/design_system/companion_speech_bubble.dart` — CompanionSpeechBubble。小人头顶说话气泡。
- `stday/lib/design_system/companion_write_avatar.dart` — CompanionWriteAvatar。「记录今天的故事」卡片左侧角色图：按登岛角色展示 wright 立绘。
- `stday/lib/design_system/expandable_preview_text.dart` — ExpandablePreviewText。完整展示 [text]，不做字数截断；保留展开/收起参数以兼容旧调用。
- `stday/lib/design_system/growth_reward_dialog.dart` — GrowthRewardKind, GrowthRewardPayload, GrowthValueOverlay
- `stday/lib/design_system/healing_jelly_button.dart` — HealingJellyTone, HealingSparkleBackground, HealingJellyCircleButton。果冻按钮配色：保留质感，色相跟随 [MoodPalette]。
- `stday/lib/design_system/healing_record_pencil_icon.dart` — HealingRecordPencilIcon。线性铅笔 + 下方短横线（「开始记录」按钮专用，非图片资源）。
- `stday/lib/design_system/home_theme.dart` — HomeTheme。首页 Dreamy Island 局部色板（不替换全局 moodPalette）。
- `stday/lib/design_system/island_chip.dart` — IslandChip, IslandCompactAction, IslandPrimaryAction
- `stday/lib/design_system/island_decorations.dart` — IslandScaffold, IslandGlassCard, IslandPreviewWindow
- `stday/lib/design_system/island_pagination_bar.dart` — IslandPaginationBar。成长轨迹等列表底部分页，风格与岛屿玻璃卡片一致。
- `stday/lib/design_system/legal_agreement.dart` — LegalConsentRow。在系统浏览器打开正式法律文档；失败时回退到应用内完整页。
- `stday/lib/design_system/moment_tag_chips.dart` — MomentTagChipRow, MomentTagChip。日常卡片上的标签：一级单独一行，二级标签换行展示。
- `stday/lib/design_system/mood_face_icon.dart` — MoodFaceIcon。固定尺寸的心情表情；优先加载 [mood_faces] PNG，失败时用矢量绘制兜底。
- `stday/lib/design_system/mood_face_painter.dart` — MoodFacePainter
- `stday/lib/design_system/mood_face_selector.dart` — MoodFaceSelector。AI 感受心情选择器（8 种感受，4×2 网格）。
- `stday/lib/design_system/password_text_field.dart` — PasswordTextField。带可见性切换的密码输入框。
- `stday/lib/design_system/pressable_feedback.dart` — PressFeedbackType, PressableFeedback
- `stday/lib/design_system/reminder_icon_asset_catalog.dart` — ReminderIconAssetCatalog
- `stday/lib/design_system/user_companion_view.dart` — UserCompanionView, UserCompanionViewState。全应用统一的小人展示入口：基础样貌来自 [UserCompanion]，日常配饰来自 [CompanionStoryContext]。

<a id="kb-stday-lib-features-achievement"></a>

### `stday/lib/features/achievement`

升级庆祝和种子动画的编排，不是独立页面。

- `stday/lib/features/achievement/growth_reward_actions.dart` — fetchCurrentGrowthSummary, showGrowthRewardsAfterAction, refreshGrowthSummary

<a id="kb-stday-lib-features-auth"></a>

### `stday/lib/features/auth`

登录和注册页。

- `stday/lib/features/auth/auth_page.dart` — AuthPage
- `stday/lib/features/auth/register_page.dart` — RegisterPage

<a id="kb-stday-lib-features-home"></a>

### `stday/lib/features/home`

滚动首页，由岛屿页嵌入，不是独立路由。

- `stday/lib/features/home/home_page.dart` — HomePage

<a id="kb-stday-lib-features-home-providers"></a>

### `stday/lib/features/home/providers`

首页槽位和问候语。

- `stday/lib/features/home/providers/home_greeting_provider.dart` — HomeGreeting；homeGreetingProvider
- `stday/lib/features/home/providers/home_island_slots_provider.dart` — HomeIslandSlot；homeIslandSlotsProvider

<a id="kb-stday-lib-features-home-widgets"></a>

### `stday/lib/features/home/widgets`

首页世界预览、故事列表、问候。主岛预览和副岛预览是不同文件。

- `stday/lib/features/home/widgets/all_islands_sheet.dart` — showAllIslandsSheet, onIslandSelected, onCreateIsland
- `stday/lib/features/home/widgets/floating_island_label.dart` — FloatingIslandLabel。群岛地图岛屿标签：主岛白胶囊治愈风；副岛左圆标 + 半透明胶囊。
- `stday/lib/features/home/widgets/greeting_section.dart` — GreetingSection
- `stday/lib/features/home/widgets/home_growth_level_card.dart` — HomeGrowthLevelCard。首页顶部成长等级卡片（原 Island 目录页标签）。
- `stday/lib/features/home/widgets/island_bubble_label.dart` — IslandBubbleLabel
- `stday/lib/features/home/widgets/island_slot_icon.dart` — IslandSlotIcon。世界地图中的分岛建筑精灵（最高等级建筑或分类默认岛体）。
- `stday/lib/features/home/widgets/story_entry_card.dart` — StoryEntryCard
- `stday/lib/features/home/widgets/today_story_item.dart` — TodayStoryItem
- `stday/lib/features/home/widgets/today_story_list.dart` — TodayStoryList。首页故事流：今日小确幸 / 昨日回响 / 旧日拾光。
- `stday/lib/features/home/widgets/world_preview.dart` — WorldPreview。沉浸式世界预览：海面 + 中心主岛 Flame + 四周副岛静态图（无底部卡片）。
- `stday/lib/features/home/widgets/world_preview_backdrop.dart` — WorldPreviewBackdrop。仅包含海域/航线/生命层；与 Flame 岛屿分离，避免每帧 rebuild 视口。
- `stday/lib/features/home/widgets/world_preview_float.dart` — WorldPreviewFloat, IslandWaterShadow。岛屿轻微上下浮动。
- `stday/lib/features/home/widgets/world_preview_island_pedestal.dart` — WorldPreviewIslandPedestal。岛屿底座：平面旋转 + 岛底治愈风同心水波纹。
- `stday/lib/features/home/widgets/world_preview_main_island.dart` — WorldPreviewMainIsland。中央主岛视口（38° 俯视）：Lv3 及以下装饰 + 角色，不展示建筑。
- `stday/lib/features/home/widgets/world_preview_main_island_deferred.dart` — WorldPreviewMainIslandDeferred。主岛 Flame 视口：首屏延迟 [delay] 再挂载，避免与 UI 同帧争抢。
- `stday/lib/features/home/widgets/world_preview_main_island_static.dart` — WorldPreviewMainIslandStatic。首页主岛纯 Canvas 静态预览（无 Flame），优先流畅。
- `stday/lib/features/home/widgets/world_preview_story_card.dart` — WorldPreviewStoryCard, WorldPreviewStoryCardStrip。首页「我的世界」副岛轻量卡片（无 Flame）。
- `stday/lib/features/home/widgets/world_preview_story_island.dart` — WorldPreviewStoryIsland。故事岛首页预览（Flame，仅 high 档部分副岛使用）。
- `stday/lib/features/home/widgets/world_preview_story_island_static.dart` — WorldPreviewStoryIslandStatic。副岛静态预览：岛体 + 顶部最高等级建筑 PNG（无 Flame）。
- `stday/lib/features/home/widgets/world_section.dart` — WorldSection

<a id="kb-stday-lib-features-island"></a>

### `stday/lib/features/island`

岛屿 Tab 总编排。island_home_page.dart 很长，先搜函数名。

- `stday/lib/features/island/growth_island_visual_debug_page.dart` — GrowthIslandVisualDebugPage
- `stday/lib/features/island/island_home_page.dart` — IslandHomePage。岛屿 Tab 总编排，四千行以上。建岛、完成任务、种子动画、深链消费都在这个文件里，先搜函数名。
- `stday/lib/features/island/story_island_progress.dart` — StoryIslandLevelProgress

<a id="kb-stday-lib-features-island-widgets"></a>

### `stday/lib/features/island/widgets`

副岛详情、任务坞、日常弹层、陪伴气泡。

- `stday/lib/features/island/widgets/island_companion_speech_overlay.dart` — IslandCompanionSpeechOverlay。岛屿小人对话气泡（点击岛上小人后展示，紧贴小人头顶、无三角）。
- `stday/lib/features/island/widgets/story_island_collapsible_task_dock.dart` — StoryIslandCollapsibleTaskDock。详情页右侧待办面板：默认展开，用户仍可点击圆钮收起。
- `stday/lib/features/island/widgets/story_island_moments_dialog.dart` — showStoryIslandMomentsDialog, showVipRequiredDialog, createState
- `stday/lib/features/island/widgets/story_island_sea_task_dock.dart` — StoryIslandSeaTaskDock。副岛详情底部「海面待办」浮层：玻璃质感 + 今日任务增删改查。
- `stday/lib/features/island/widgets/story_island_static_detail_viewport.dart` — StoryIslandStaticDetailViewport。Lightweight story-island detail renderer. The full Flame scene is unnecessarily…

<a id="kb-stday-lib-features-landing"></a>

### `stday/lib/features/landing`

欢迎页区块。/welcome 实际画的是这里。

- `stday/lib/features/landing/landing_growth_header.dart` — LandingGrowthHeader
- `stday/lib/features/landing/landing_island_progress.dart` — LandingIslandProgress。岛屿下方的今日状态与升级进度（紧凑，避免挤出屏幕）。
- `stday/lib/features/landing/landing_page.dart` — LandingPage
- `stday/lib/features/landing/landing_warm_quote_box.dart` — LandingWarmQuoteBox。引导页下方带边框的温馨成长语句展示框。
- `stday/lib/features/landing/landing_warm_quotes.dart` — LandingWarmQuotes。引导页黑框展示的温馨成长语句（约 50 字，每次随机一条）。
- `stday/lib/features/landing/landing_welcome_section.dart` — LandingWelcomeSection。引导页卡片欢迎介绍（精简：标题 + 价值说明）。

<a id="kb-stday-lib-features-legal"></a>

### `stday/lib/features/legal`

协议页。

- `stday/lib/features/legal/legal_document_page.dart` — LegalDocumentPage。全屏法律文档页（用户协议 / 隐私政策）。 审核要求「可打开」的隐私政策与 Terms of Use 链接时，使用本页而非底部弹层。

<a id="kb-stday-lib-features-membership"></a>

### `stday/lib/features/membership`

会员中心页。

- `stday/lib/features/membership/membership_page.dart` — MembershipPage

<a id="kb-stday-lib-features-more"></a>

### `stday/lib/features/more`

更多 Tab 及其子页。

- `stday/lib/features/more/app_about_page.dart` — AppAboutPage
- `stday/lib/features/more/audio_settings_page.dart` — AudioSettingsPage
- `stday/lib/features/more/companion_prop_badge_detail.dart` — formatPropFirstEarnedAt, companionPropDisplayTitle, showCompanionPropBadgeDetail
- `stday/lib/features/more/companion_showcase_page.dart` — CollectedCompanionProp, CompanionShowcasePage；_collectedPropsProvider
- `stday/lib/features/more/more_page.dart` — MorePage
- `stday/lib/features/more/my_level_page.dart` — MyLevelPage；_momentDatesProvider
- `stday/lib/features/more/reminder_settings_page.dart` — ReminderSettingsPage；_reminderIconCatalogProvider

<a id="kb-stday-lib-features-more-widgets"></a>

### `stday/lib/features/more/widgets`

提醒编辑和更多页头。

- `stday/lib/features/more/widgets/more_subpage_header.dart` — MoreSubpageHeader。「更多」子页统一页眉，与「我的等级」等页保持一致。
- `stday/lib/features/more/widgets/reminder_editor_sheet.dart` — showReminderEditorSheet, createState, initState。添加 / 编辑提醒的底部表单。
- `stday/lib/features/more/widgets/reminder_icon_preview.dart` — ReminderIconPreview。提醒图标预览：支持 emoji: 前缀、PNG / WebP / SVG。

<a id="kb-stday-lib-features-onboarding"></a>

### `stday/lib/features/onboarding`

选陪伴角色和抵达页。

- `stday/lib/features/onboarding/companion_page.dart` — CompanionPage
- `stday/lib/features/onboarding/gender_page.dart` — GenderPage
- `stday/lib/features/onboarding/time_travel_page.dart` — TimeTravelArrivalPage。选中心情后的「时空穿梭」进入小岛。
- `stday/lib/features/onboarding/welcome_page.dart` — WelcomePage。应用启动页（成长小岛 Landing）。

<a id="kb-stday-lib-features-onboarding-widgets"></a>

### `stday/lib/features/onboarding/widgets`

角色选择控件。

- `stday/lib/features/onboarding/widgets/character_role_picker.dart` — CharacterRolePicker, CharacterRoleOptionCard。角色选择卡片：支持免费角色与会员专属角色左右滑动预览。

<a id="kb-stday-lib-features-records"></a>

### `stday/lib/features/records`

日常记录 Tab。

- `stday/lib/features/records/record_page.dart` — RecordPage。今日日常列表页（从原 TodayStoriesPage 拆分，不含岛屿）。

<a id="kb-stday-lib-features-records-widgets"></a>

### `stday/lib/features/records/widgets`

周观察卡片。

- `stday/lib/features/records/widgets/weekly_observation_card.dart` — WeeklyObservationCard

<a id="kb-stday-lib-features-shared-widgets"></a>

### `stday/lib/features/shared/widgets`

跨页面的加载态，可以读 provider。

- `stday/lib/features/shared/widgets/mood_companion_loading.dart` — MoodCompanionLoadingBody, MoodCompanionLoadingScaffold, MoodCompanionLoadingIndicator。主 Tab 内嵌加载（勿再包 Scaffold，避免与 Shell 双层 Scaffold 导致空白）。

<a id="kb-stday-lib-features-status"></a>

### `stday/lib/features/status`

心情洞察页。

- `stday/lib/features/status/mood_status_page.dart` — MoodStatusPage

<a id="kb-stday-lib-features-status-widgets"></a>

### `stday/lib/features/status/widgets`

心情、标签、周打卡。部分 Tab 要会员。

- `stday/lib/features/status/widgets/mood_check_in_week_card.dart` — MoodCheckInWeekCard。连续记录天数：本周打卡时间轴。
- `stday/lib/features/status/widgets/mood_overview_tab.dart` — MoodOverviewTab。心情概览 Tab：按当前周期 + 大标签筛选展示日常列表。
- `stday/lib/features/status/widgets/mood_period_filter_bar.dart` — MoodPeriodFilterBar。成长轨迹页：今天 / 本周 / 本月 / 本年度快捷筛选。
- `stday/lib/features/status/widgets/mood_stats_tab.dart` — MoodStatsTab。感受统计 Tab：按 AI 感受展示占比条。
- `stday/lib/features/status/widgets/mood_status_section_tabs.dart` — MoodStatusSectionTabDef, MoodStatusSectionTabs, MoodStatusSectionTabBar。心情状态页底部区块 Tab 定义（新增 Tab 时在此追加 [all]）。
- `stday/lib/features/status/widgets/mood_summary_section.dart` — MoodSummarySection。心情状态页：当前筛选周期下的总体 AI 心情总结（约 100 字，完整展示不截断）。
- `stday/lib/features/status/widgets/tag_stats_tab.dart` — TagStatsTab。标签统计 Tab：按标签库统计一级 / 二级标签触发次数。
- `stday/lib/features/status/widgets/week_streak_track.dart` — WeekStreakTrack。周打卡时间轴（与成长轨迹「连续记录天数」同款样式）。

<a id="kb-stday-lib-features-today"></a>

### `stday/lib/features/today`

写日常、编辑、照片、语音、安放。

- `stday/lib/features/today/add_moment_flow.dart` — showAddMomentFlow, showWriteStoryPage。成长记录：直接写日常，由 AI 自动分类打标。 [targetDay] 补录指定日期（缺省为今天）。
- `stday/lib/features/today/daily_entry_flow.dart` — runDailyEntryFlowIfNeeded, showAddMomentFlow, showGrowthRewardsAfterAction
- `stday/lib/features/today/edit_moment_sheet.dart` — showEditMomentSheet, showWriteStoryPage
- `stday/lib/features/today/edit_moment_tags_page.dart` — EditMomentTagsPage
- `stday/lib/features/today/moment_detail_page.dart` — MomentDetailPage
- `stday/lib/features/today/moment_form_widgets.dart` — MomentNoteField, MomentTagChoice, MomentTagSelector
- `stday/lib/features/today/moment_mood_picker.dart` — showMomentMoodPicker, showVipRequiredDialog, isMomentToday
- `stday/lib/features/today/moment_photo_gallery.dart` — MomentPhotoThumbnailStrip, MomentPhotoCollapsibleStrip。全屏查看日常照片，带关闭按钮。
- `stday/lib/features/today/moment_photo_section.dart` — MomentPhotoDraft, MomentNetworkImage, MomentPhotoSection。本地待上传或已保存的日常照片。
- `stday/lib/features/today/mood_today_card.dart` — MoodTodayCard
- `stday/lib/features/today/story_companion_floater.dart` — StoryCompanionFloater。日常页右侧小人：默认半透明不挡文字，点击后正常展示；可配置始终高亮或侧边改心情。
- `stday/lib/features/today/story_island_placement_sheet.dart` — showStoryIslandPlacementSheet, createState, build
- `stday/lib/features/today/today_story_card.dart` — TodayStoryCard
- `stday/lib/features/today/voice_analysis_poll.dart` — VoiceAnalysisPollHost。语音日常 AI 分析进行中时，定时刷新列表直至 `speech_status` 完成。
- `stday/lib/features/today/write_story_draft_store.dart` — WriteStoryDraftStore。记录页未提交时暂存草稿，再次打开「录入心情」时恢复。
- `stday/lib/features/today/write_story_page.dart` — StoryInputMode, WriteStoryPage

<a id="kb-stday-lib-features-today-widgets"></a>

### `stday/lib/features/today/widgets`

按住说话、日期筛选、安放预览。

- `stday/lib/features/today/widgets/island_placement_preview.dart` — IslandPlacementPreview。日常投放弹窗中的岛屿缩略预览：主岛显示装饰，副岛显示建筑。
- `stday/lib/features/today/widgets/speech_dictation_overlay.dart` — SpeechDictationOverlay。文字记录时长按麦克风的录音/转写浮层（与语音记录弹窗风格一致）。
- `stday/lib/features/today/widgets/story_day_filter_bar.dart` — StoryDayFilterBar。今日日常 / 心情状态页顶部：今天、昨天（有记录时）、更多日期。
- `stday/lib/features/today/widgets/story_day_picker_sheet.dart` — showStoryDayPickerSheet, createState, initState。日期选择：按月日历 + 心情表情（适合大量历史记录）。 [allowAnyPastDay] 为 true 时，可选任意过去日期（用于补录日常）。
- `stday/lib/features/today/widgets/story_voice_bubble.dart` — StoryVoiceBubble。微信风格语音播放气泡（支持远程 URL 或本地录音文件）。
- `stday/lib/features/today/widgets/story_voice_input_panel.dart` — VoiceRecordingResult, StoryVoiceInputPanel

<a id="kb-stday-lib-island-anchor"></a>

### `stday/lib/island/anchor`

世界锚点。

- `stday/lib/island/anchor/world_anchor_system.dart` — WorldAnchorSystem

<a id="kb-stday-lib-island-building"></a>

### `stday/lib/island/building`

主岛建筑绘制、占地和深度。副岛建筑不在这里。

- `stday/lib/island/building/building_asset_resolver.dart` — BuildingAssetSource, BuildingAsset, BuildingAssetResolver
- `stday/lib/island/building/building_depth_scale.dart` — BuildingDepthScale。主岛建筑纵深透视：Y 越小（越靠后）缩放越小。
- `stday/lib/island/building/building_factory.dart` — BuildingFactory
- `stday/lib/island/building/building_footprint.dart` — BuildingFootprint。建筑在岛面上的归一化占地（宽 × 高），随岛屿半径等比缩放。 宽度由 [BuildingSpriteMetrics] 统一宽高比推导，避免 PNG 独立拉伸变…
- `stday/lib/island/building/building_render_component.dart` — BuildingRenderComponent
- `stday/lib/island/building/building_sprite_metrics.dart` — BuildingSpriteMetrics。主岛建筑 PNG 内容度量：统一缩放与 footprint 宽高比。 素材为 800×800 画布，实际建筑内容仅占一部分；渲染与碰撞均用 **单一 scal…
- `stday/lib/island/building/plaza_terrace_renderer.dart` — PlazaTerraceRenderer。主岛广场台地：阶梯 + 立柱，解决扁平椭圆问题（#5）。
- `stday/lib/island/building/procedural_building_renderer.dart` — ProceduralBuildingRenderer

<a id="kb-stday-lib-island-config"></a>

### `stday/lib/island/config`

主岛地形和成长岛配置。

- `stday/lib/island/config/building_config.dart` — IslandBuildingDef, IslandBuildingConfig。Growth Island 2.0 固定三座建筑布局（位置不随 mood 变化）。
- `stday/lib/island/config/day_phase_lighting_config.dart` — 再导出 ../../world/systems/config/day_phase_lighting_config.dart
- `stday/lib/island/config/growth_island_config_models.dart` — RangeDouble, IslandLevelConfig, BuildingConfig
- `stday/lib/island/config/growth_island_configs.dart` — GrowthIslandConfigs, GrowthIslandConfigRepository
- `stday/lib/island/config/island_terrain_config.dart` — IslandTerrainLayer, GrowthTerraceDef, GrowthFloatingPadDef。成长岛地形分层：后景 / 中景 / 前景（用于建筑与平台纵深）。
- `stday/lib/island/config/island_visual_config.dart` — 再导出 ../../world/island/island_visual_config.dart
- `stday/lib/island/config/mood_atmosphere_config.dart` — 再导出 ../../world/systems/config/mood_atmosphere_config.dart
- `stday/lib/island/config/weather_atmosphere_config.dart` — 再导出 ../../world/systems/config/weather_atmosphere_config.dart

<a id="kb-stday-lib-island-debug"></a>

### `stday/lib/island/debug`

主岛调试叠层。

- `stday/lib/island/debug/main_island_debug_overlay.dart` — MainIslandDebugOverlay。主岛程序化布局调试叠层：禁放区、建筑 footprint、装饰 occupancy。

<a id="kb-stday-lib-island-decor"></a>

### `stday/lib/island/decor`

主岛装饰、草裙、天空轨迹、成长缩放。

- `stday/lib/island/decor/animated_decor_component.dart` — AnimatedDecorComponent, StaticDecorComponent。动态装饰组件：云朵漂浮、鸟类绕飞、蝴蝶 8 字、萤火虫游走。
- `stday/lib/island/decor/decor_config.dart` — DecorCategory, DecorConfig, DecorConfigs。岛屿装饰分类与配置。 新增装饰时仅需： 1. 在 [assets/images/decor/] 添加图片 2. 在 [DecorConfigs.all] 追加…
- `stday/lib/island/decor/decor_manager.dart` — DecorManager。岛屿装饰管理器：预加载、等级过滤、创建并挂载 Flame 组件。
- `stday/lib/island/decor/decor_placement_resolver.dart` — DecorPlacementResolver。装饰落点：避开主角占位、建筑 footprint 与已占用区域。
- `stday/lib/island/decor/decor_position_store.dart` — DecorPositionStore。装饰落点持久化：升级解锁时随机落点，之后固定不变。
- `stday/lib/island/decor/decor_scale_resolver.dart` — DecorScaleResolver。装饰最终尺寸：config.scale ÷ 素材内容占比 × 成长倍率 × 低等级填充 × randomScale。 所有 PNG 为 800×800，实际绘…
- `stday/lib/island/decor/grass_skirt_painter.dart` — GrassSkirtPainter。在装饰/建筑根部绘制前景草叶，略微遮挡底部，营造「长在土地上」的层次。
- `stday/lib/island/decor/island_growth_scale_service.dart` — IslandGrowthScaleService。岛屿成长等级 → 全局缩放曲线（Lv1 萌芽 → Lv20 成熟）。
- `stday/lib/island/decor/sky_trajectory.dart` — SkyMotionKind, SkyTrajectoryDefinition, SkyTrajectoryCatalog。天空装饰运动类型。

<a id="kb-stday-lib-island-generator"></a>

### `stday/lib/island/generator`

主岛生成。

- `stday/lib/island/generator/island_generator.dart` — IslandGenerator

<a id="kb-stday-lib-island-placement"></a>

### `stday/lib/island/placement`

只给主岛用。副岛锚点在 StoryIslandLayout。

- `stday/lib/island/placement/island_building_layout.dart` — IslandBuildingLayout, PlacedFootprint。成长岛建筑落点：关键建筑固定区域 + 其余稳定随机 + 防重叠。
- `stday/lib/island/placement/island_placement.dart` — 再导出 ../../world/island/island_placement.dart
- `stday/lib/island/placement/large_tree_shore_parcels.dart` — LargeTreeShoreParcels。主岛 7 棵大树岸线独占 parcel（建筑 / 草花 / 其它地面装饰不可占用）。 槽位在满半径下错开定义，再按 [IslandState.radius] …
- `stday/lib/island/placement/main_island_placement_zones.dart` — MainIslandPlacementZones。主岛程序化放置专用区域约束（不影响副岛 [StoryIslandWorldBuilder]）。

<a id="kb-stday-lib-island-providers"></a>

### `stday/lib/island/providers`

主岛世界、建筑解锁、成长摘要。

- `stday/lib/island/providers/building_unlocks_provider.dart` — buildingUnlocksProvider。用户已解锁建筑及获得时间（来自服务端数据库）。
- `stday/lib/island/providers/growth_summary_provider.dart` — growthSummaryProvider。用户成长摘要（等级、XP、连续打卡等）。
- `stday/lib/island/providers/island_world_provider.dart` — islandBuildServiceProvider, islandStyleResolverProvider, islandWorldPreviewProvider, islandWorldProvider

<a id="kb-stday-lib-island-service"></a>

### `stday/lib/island/service`

主岛拼装、风格和建筑显示名。

- `stday/lib/island/service/building_display_names.dart` — BuildingDisplayNames。成长岛建筑中文展示名。
- `stday/lib/island/service/building_resolver.dart` — BuildingResolver。根据繁荣度解锁固定三座成长建筑。
- `stday/lib/island/service/island_build_service.dart` — IslandBuildService。唯一组装 [GrowthWorldInput] 并构建 [WorldState] 的入口。
- `stday/lib/island/service/island_style_resolver.dart` — IslandStyleResolver。合并固定岛型地表色 + 心情/真实天气氛围色（仅天空/海/粒子）。

<a id="kb-stday-lib-island-viewport"></a>

### `stday/lib/island/viewport`

主岛 Flame 视口和相机。

- `stday/lib/island/viewport/growth_world_viewport.dart` — GrowthWorldViewport, GrowthWorldViewportState。Growth Island 2.0 唯一岛屿渲染入口（Flame 2D Canvas）。
- `stday/lib/island/viewport/island_view_camera.dart` — IslandViewCamera。主岛交互视口的等级相关缩放（Lv20 贴边建筑完整可见）。

<a id="kb-stday-lib-island-widgets"></a>

### `stday/lib/island/widgets`

主岛 HUD 和建筑气泡。

- `stday/lib/island/widgets/building_info_bubble.dart` — BuildingInfoBubble。建筑点击后的名称与获得时间（仅点击时展示）。
- `stday/lib/island/widgets/growth_progress_panel.dart` — GrowthProgressPanel, IslandRecordCTA。岛屿首页下方的成长进度区（合并 header + progress）。
- `stday/lib/island/widgets/island_hud_overlay.dart` — IslandHudOverlay。叠在岛景上的 HUD：等级、连续天、进度；顶部展示地理位置与天气。

<a id="kb-stday-lib-l10n"></a>

### `stday/lib/l10n`

生成物。改 arb 后重新生成，不要手改这三份。

- `stday/lib/l10n/app_localizations.dart` — AppLocalizations。Callers can lookup localized strings with an instance of AppLocalizations retur…
- `stday/lib/l10n/app_localizations_en.dart` — AppLocalizationsEn。The translations for English (`en`).
- `stday/lib/l10n/app_localizations_zh.dart` — AppLocalizationsZh, AppLocalizationsZhTw。The translations for Chinese (`zh`).

<a id="kb-stday-lib-providers"></a>

### `stday/lib/providers`

跨页面状态。只属于一个页面的状态放回该 feature。

- `stday/lib/providers/app_audio_provider.dart` — AppAudioSettingsNotifier；appAudioControllerProvider, appAudioSettingsProvider
- `stday/lib/providers/app_providers.dart` — MoodIslandRegistryNotifier, GrowthMainIslandNotifier, StorySeedAnimationRequest；userAppPreferencesSyncProvider, moodIslandRegistryProvider, profileProvider, todayMomentsProvider
- `stday/lib/providers/auth_provider.dart` — AuthState, AuthNotifier；authProvider
- `stday/lib/providers/bootstrap_provider.dart` — AppSplashHoldNotifier, StartupProfileTimeoutNotifier；appBootstrapProvider, appSplashHoldProvider, startupProfileTimeoutProvider, startupSettledProvider。必须在 [main] 里 override。
- `stday/lib/providers/current_island_provider.dart` — CurrentIslandSelection, CurrentIslandNotifier；currentIslandProvider
- `stday/lib/providers/growth_observation_provider.dart` — weeklySummaryProvider
- `stday/lib/providers/growth_tag_provider.dart` — growthTagCatalogProvider
- `stday/lib/providers/iap_provider.dart` — IapCatalogState, IapCatalogNotifier；iapCatalogProvider
- `stday/lib/providers/island_weather_provider.dart` — islandWeatherServiceProvider, islandWeatherFetchEnabledProvider, islandWeatherProvider
- `stday/lib/providers/island_widget_sync_provider.dart` — islandWidgetSyncProvider。将当前岛屿上下文同步到 iOS / Android 桌面小组件（严格单岛隔离）。
- `stday/lib/providers/main_shell_tab_provider.dart` — mainShellTabIndexProvider。底部导航当前 Tab（0=岛屿），用于离屏时暂停 Flame 引擎。
- `stday/lib/providers/member_provider.dart` — MemberNotifier；memberProvider, isVipProvider。会员状态缓存有效期。
- `stday/lib/providers/membership_feature_provider.dart` — isFirstMomentOfDay, canUseFreeCompanionDialogue, isFirstMomentOfDay。非 VIP 仅可对当日首个日常（按创建时间最早）使用小人对话。
- `stday/lib/providers/mood_report_check_in_provider.dart` — moodReportCheckInProvider
- `stday/lib/providers/mood_status_provider.dart` — MoodSummaryKey, MoodStatusViewState, MoodStatusViewNotifier；moodStatusPeriodProvider, moodStatusCategoryFilterProvider, moodStatusEmotionFilterProvider, moodStatusPageProvider。成长轨迹页当前周期（独立于今日记录 [selectedStoryDayProvider]）。
- `stday/lib/providers/story_day_provider.dart` — StoryDayViewState, StoryDayViewNotifier；selectedStoryDayProvider, storyDayViewProvider
- `stday/lib/providers/widget_navigation_provider.dart` — pendingTaskDockIslandIdProvider。从桌面小组件进入岛屿详情后，自动展开待办面板。
- `stday/lib/providers/world_state_provider.dart` — growthWorldEngineProvider

<a id="kb-stday-lib-router"></a>

### `stday/lib/router`

GoRouter 与小组件深链解析。

- `stday/lib/router/app_router.dart` — appRouterProvider
- `stday/lib/router/widget_deep_link_handler.dart` — WidgetDeepLinkAction, WidgetDeepLinkIntent, WidgetDeepLinkHost；pendingWidgetDeepLinkProvider, pendingIslandWidgetNavigationProvider

<a id="kb-stday-lib-services"></a>

### `stday/lib/services`

桌面小组件快照。页面不写这里。

- `stday/lib/services/island_widget_models.dart` — IslandWidgetPayload, IslandWidgetTaskItem。App Group / SharedPreferences 共享给桌面小组件的快照（当前岛屿上下文）。
- `stday/lib/services/island_widget_service.dart` — IslandWidgetService

<a id="kb-stday-lib-world-behaviors"></a>

### `stday/lib/world/behaviors`

角色走动、点击、靠近建筑。

- `stday/lib/world/behaviors/character_motion_behavior.dart` — CharacterMotionFrame, CharacterMotionBehavior
- `stday/lib/world/behaviors/companion_hit_test.dart` — CompanionHitTest。与 [CharacterLayer] 主角命中区域一致，供 Flutter 叠层手势复用。
- `stday/lib/world/behaviors/nearby_building_behavior.dart` — NearbyBuildingRenderState, NearbyBuildingBehavior
- `stday/lib/world/behaviors/protagonist_behavior.dart` — ProtagonistBehaviorSample, ProtagonistBehavior。首页主角行为：固定站在成长树前，只保留轻微呼吸。

<a id="kb-stday-lib-world-engine"></a>

### `stday/lib/world/engine`

引擎、WorldState、缓存。

- `stday/lib/world/engine/growth_event.dart` — GrowthEventType, GrowthEvent, UserGrowthProfile
- `stday/lib/world/engine/growth_world_engine.dart` — GrowthWorldEngine
- `stday/lib/world/engine/growth_world_input.dart` — GrowthWorldInput
- `stday/lib/world/engine/world_state.dart` — WorldState, IslandState, CharacterSnapshot
- `stday/lib/world/engine/world_state_v2.dart` — WorldStateV2

<a id="kb-stday-lib-world-island"></a>

### `stday/lib/world/island`

主岛几何和草坪。

- `stday/lib/world/island/growth_world_ground_painter.dart` — GrowthWorldGroundPainter。Growth Island 2.0 平地草坪：程序化写实草簇渲染，严格限制在石质边缘以内。
- `stday/lib/world/island/island_placement.dart` — IslandPlacement。成长岛表面可放置区域的归一化约束（与 [IslandShapeProfile._growthWorldPath] 对齐）。
- `stday/lib/world/island/island_renderer.dart` — IslandRenderer
- `stday/lib/world/island/island_shape_profile.dart` — IslandShapeProfile。岛屿形状配置：顶面 Path 与侧壁挤出。
- `stday/lib/world/island/island_visual_config.dart` — IslandVisualConfig。Growth Island 2.0 固定视觉基准：岛型与地表色不随心情变化。
- `stday/lib/world/island/lawn_obstacle_mask.dart` — LawnObstacleMask, LawnObstacleRegion, LawnRenderPass。草坪生成需避开的障碍区域（建筑、装饰、主角站位）。
- `stday/lib/world/island/realistic_lawn_renderer.dart` — RealisticLawnRenderer

<a id="kb-stday-lib-world-preview"></a>

### `stday/lib/world/preview`

副岛和首页用的静态预览，不是 Flame 主岛。

- `stday/lib/world/preview/story_island_building_icon.dart` — StoryIslandBuildingIcon。故事岛预览图标：取当前分类已解锁的最高等级建筑，否则用该分类默认岛体。
- `stday/lib/world/preview/story_island_world_builder.dart` — StoryIslandWorldBuilder
- `stday/lib/world/preview/world_island_layout.dart` — WorldIslandLayout, WorldIslandSlotLayout。首页群岛布局：副岛环绕主岛，间距足够避免遮挡。
- `stday/lib/world/preview/world_island_visual.dart` — WorldIslandVisualProfile。首页群岛视觉参数：按分类与远近区分缩放/旋转，不改变业务数据。
- `stday/lib/world/preview/world_preview_camera.dart` — WorldPreviewCamera, WorldPreviewCameraController。首页世界地图相机：轻俯视 + 可选平面旋转。
- `stday/lib/world/preview/world_preview_environment.dart` — WorldPreviewHorizonSkyLayer, WorldPreviewSeabedLayer, WorldPreviewOceanLayer。顶部 15% 极淡天空，其余全是海。
- `stday/lib/world/preview/world_preview_performance.dart` — WorldPreviewQuality, WorldPreviewPerformance, WorldPreviewPhaseTicker。首页群岛预览渲染档位（影响 Flame 数量、动画帧率、海面细节）。

<a id="kb-stday-lib-world-rendering"></a>

### `stday/lib/world/rendering`

远山等绘制。

- `stday/lib/world/rendering/companion_asset_resolver.dart` — CompanionImageAsset, CompanionAssetResolver
- `stday/lib/world/rendering/companion_picture_cache.dart` — CompanionPicturePainter, CompanionPictureCache
- `stday/lib/world/rendering/cozy_hero_renderer.dart` — CozyHeroRenderer
- `stday/lib/world/rendering/stylized_mountain_painter.dart` — StylizedMountainPainter
- `stday/lib/world/rendering/world_state_cache.dart` — WorldStateBuilder, WorldStateCache

<a id="kb-stday-lib-world-scene"></a>

### `stday/lib/world/scene`

WorldScene 与深度。

- `stday/lib/world/scene/island_gesture_surface.dart` — IslandGestureSurface。岛屿视口手势：双指缩放与旋转；透传单击给下层 Flame。
- `stday/lib/world/scene/scene_depth_priority.dart` — SceneDepthPriority。主岛纵深绘制优先级：Y 越大（越靠屏幕下方）越靠前，应遮挡更靠后的元素。
- `stday/lib/world/scene/world_scene.dart` — WorldScene, WorldSceneWidget, WorldSceneWidgetState。成长世界主场景：按 Layer 分层渲染，禁止单 Stack 堆叠所有元素。

<a id="kb-stday-lib-world-scene-layers"></a>

### `stday/lib/world/scene/layers`

主岛层。顺序以 WorldScene.onLoad 为准。

- `stday/lib/world/scene/layers/building_layer.dart` — BuildingLayer
- `stday/lib/world/scene/layers/character_layer.dart` — CharacterLayer
- `stday/lib/world/scene/layers/decor_layer.dart` — DecorLayer。装饰层：通过 [DecorManager] 数据驱动加载 PNG 装饰。
- `stday/lib/world/scene/layers/effect_layer.dart` — EffectLayer
- `stday/lib/world/scene/layers/grass_foreground_layer.dart` — GrassForegroundLayer。前景草层：画在地面装饰与建筑之上、角色之下，根部草叶略微遮挡装饰底部。
- `stday/lib/world/scene/layers/island_layer.dart` — IslandLayer
- `stday/lib/world/scene/layers/main_island_debug_overlay_layer.dart` — MainIslandDebugOverlayLayer。主岛布局调试层（仅 debug 模式启用）。
- `stday/lib/world/scene/layers/ocean_layer.dart` — OceanLayer
- `stday/lib/world/scene/layers/sky_layers.dart` — SkyLayer, CloudLayer, DistantLayer
- `stday/lib/world/scene/layers/ui_overlay_layer.dart` — UIOverlayLayer
- `stday/lib/world/scene/layers/world_layer.dart` — WorldLayer。世界渲染层基类；通过 priority 控制 z 序。

<a id="kb-stday-lib-world-systems"></a>

### `stday/lib/world/systems`

建筑系统和心情环境。

- `stday/lib/world/systems/building_system.dart` — BuildingDefinition, BuildingSystem
- `stday/lib/world/systems/mood_environment_controller.dart` — MoodEnvironmentController, MoodEnvironmentStateCopy
- `stday/lib/world/systems/prosperity_system.dart` — ProsperitySystem。根据成长等级生成「世界繁荣」植被与装饰，而非 mood 道具。

<a id="kb-stday-lib-world-systems-config"></a>

### `stday/lib/world/systems/config`

昼夜、心情、天气的画面参数。

- `stday/lib/world/systems/config/day_phase_lighting_config.dart` — DayPhase, DayPhaseLightingPreset。岛屿场景时段：早 / 中 / 晚。
- `stday/lib/world/systems/config/mood_atmosphere_config.dart` — MoodAtmospherePreset, MoodAtmosphereConfig。情绪仅影响氛围，不改变岛屿结构。
- `stday/lib/world/systems/config/weather_atmosphere_config.dart` — WeatherAtmosphereConfig。将真实天气映射为岛屿氛围预设。

<a id="kb-客户端测试-stday-test"></a>

## 客户端测试 `stday/test`

改对应行为后跑同名测试。命令在 `stday/` 下：`flutter test test/<文件>`。

- `stday/test/api_datetime_test.dart`
- `stday/test/app_config_test.dart`
- `stday/test/building_footprint_test.dart`
- `stday/test/companion_base_asset_test.dart`
- `stday/test/companion_dialogue_test.dart`
- `stday/test/companion_prop_collection_test.dart`
- `stday/test/companion_prop_labels_test.dart`
- `stday/test/companion_write_asset_test.dart`
- `stday/test/daily_level_unlock_test.dart`
- `stday/test/day_phase_lighting_test.dart`
- `stday/test/decor_config_test.dart`
- `stday/test/decor_placement_resolver_test.dart`
- `stday/test/growth_island_visual_snapshot_test.dart`
- `stday/test/growth_system_test.dart`
- `stday/test/home_island_slots_provider_test.dart`
- `stday/test/island_building_layout_test.dart`
- `stday/test/island_growth_scale_service_test.dart`
- `stday/test/island_unlock_catalog_test.dart`
- `stday/test/island_view_camera_test.dart`
- `stday/test/island_widget_models_test.dart`
- `stday/test/large_tree_placement_test.dart`
- `stday/test/large_tree_shore_parcels_test.dart`
- `stday/test/legal_documents_test.dart`
- `stday/test/legal_urls_test.dart`
- `stday/test/level_title_assets_test.dart`
- `stday/test/level_unlock_preview_test.dart`
- `stday/test/main_island_depth_debug_test.dart`
- `stday/test/main_island_placement_zones_test.dart`
- `stday/test/moment_date_parse_test.dart`
- `stday/test/moment_highlight_test.dart`
- `stday/test/mood_face_paths_test.dart`
- `stday/test/mood_stats_test.dart`
- `stday/test/plaza_terrace_renderer_test.dart`
- `stday/test/realistic_lawn_renderer_test.dart`
- `stday/test/sky_trajectory_test.dart`
- `stday/test/small_tree_placement_test.dart`
- `stday/test/soft_text_trim_test.dart`
- `stday/test/speech_note_merge_test.dart`
- `stday/test/story_island_building_catalog_test.dart`
- `stday/test/story_island_building_icon_test.dart`
- `stday/test/story_island_category_order_test.dart`
- `stday/test/story_island_layout_test.dart`
- `stday/test/story_island_names_test.dart`
- `stday/test/story_island_progress_test.dart`
- `stday/test/today_mood_display_test.dart`
- `stday/test/weather_display_test.dart`
- `stday/test/week_activity_test.dart`
- `stday/test/week_check_in_days_test.dart`
- `stday/test/widget_test.dart`

<a id="kb-原生"></a>

## 原生

业务在 Flutter。原生只保留启动和桌面小组件。

- `stday/android/app/src/main/kotlin/com/stday/stday/IslandWidgetCycleReceiver.kt` — IslandWidgetCycleReceiver
- `stday/android/app/src/main/kotlin/com/stday/stday/IslandWidgetDayChangeReceiver.kt` — IslandWidgetDayChangeReceiver
- `stday/android/app/src/main/kotlin/com/stday/stday/IslandWidgetProvider.kt` — IslandWidgetProvider
- `stday/android/app/src/main/kotlin/com/stday/stday/MainActivity.kt` — MainActivity
- `stday/ios/IslandWidget/IslandQuickTaskWidget.swift` — IslandProvider
- `stday/ios/IslandWidget/IslandWidgetBundle.swift` — IslandWidgetBundle
- `stday/ios/IslandWidget/IslandWidgetShared.swift` — IslandWidgetConstants
- `stday/ios/IslandWidget/IslandWidgetTodoStyle.swift` — WidgetTodoProgressRing
- `stday/ios/Runner/AppDelegate.swift` — AppDelegate
- `stday/ios/Runner/SceneDelegate.swift` — SceneDelegate

`stday/macos/` 与 `stday/ios/Runner/` 里其余文件是 Flutter 壳，不放业务。

<a id="kb-后端-backend"></a>

## 后端 `backend`

入口是 `backend/app/main.py`。路由装配在 `backend/app/api/v1/api.py`。`agents/`、`prompts/` 没有现行业务流程。`story_engine/` 目录是空的。早期 Alembic 迁移里有学校和教师表，现行客户端不调用那些接口。

<a id="kb-backend-app"></a>

### `backend/app`

进程入口、静态法律页、健康检查。

- `backend/app/main.py` — lifespan, legal_index_redirect, legal_terms_alias, legal_privacy_alias

<a id="kb-backend-app-agents"></a>

### `backend/app/agents`

抽象基类，没有具体 Agent。

- `backend/app/agents/base.py` — BaseAgent

<a id="kb-backend-app-api"></a>

### `backend/app/api`

依赖注入和限流依赖。

- `backend/app/api/deps.py` — get_current_user, get_current_admin
- `backend/app/api/deps_rate_limit.py` — enforce_login_rate_limit, enforce_register_rate_limit, enforce_auth_entry_rate_limit, enforce_token_rate_limit

<a id="kb-backend-app-api-v1"></a>

### `backend/app/api/v1`

把 endpoints 挂到 /api/v1。

- `backend/app/api/v1/api.py` — 挂载 auth, profile, island_styles, growth_tags, i18n, iap, member

<a id="kb-backend-app-api-v1-endpoints"></a>

### `backend/app/api/v1/endpoints`

HTTP。一个文件一类资源。

- `backend/app/api/v1/endpoints/auth.py` — auth_entry, user_register, login, login_for_access_token
- `backend/app/api/v1/endpoints/growth_tags.py` — list_growth_tags, admin_list_growth_tags, create_category, update_category
- `backend/app/api/v1/endpoints/i18n.py` — get_i18n_config, get_i18n_bundle, admin_list_strings, admin_create_string
- `backend/app/api/v1/endpoints/iap.py` — get_member_service, get_iap_service, verify_purchase, restore_purchases
- `backend/app/api/v1/endpoints/island_styles.py` — list_island_styles, get_island_style, update_island_style
- `backend/app/api/v1/endpoints/member.py` — get_member_service, get_activation_code_service, get_permission_service, get_member_me
- `backend/app/api/v1/endpoints/profile.py` — 资料、陪伴角色、故事岛、任务完成、日常、语音、照片、心情周期、周观察。具体路径以 `knowledge/BACKEND_API.md` 为准。

<a id="kb-backend-app-config"></a>

### `backend/app/config`

和客户端必须对齐的目录：建筑名、情绪、标签种子。

- `backend/app/config/emotion_catalog.py` — EffectiveEmotion；normalize_emotion_id, effective_emotion_for_moment, dominant_emotion_by_count, legacy_mood_from_emotion_id。AI 感受心情目录（用户唯一可见的心情体系）。
- `backend/app/config/growth_island_buildings.py` — IslandLevelDef；resolve_island_level, buildings_for_growth_value, required_score_for_level。成长岛建筑解锁配置（与 Flutter GrowthIslandConfigs 对齐）。
- `backend/app/config/growth_tag_seed.py` — GROWTH_TAG_SEED。默认成长标签种子（与产品文档一致）。
- `backend/app/config/story_island_buildings.py` — story_island_building_type。副岛各标签 Lv1–Lv10 建筑名称（Lv1 外圈起步 → Lv10 中心地标）。

<a id="kb-backend-app-core"></a>

### `backend/app/core`

配置、JWT、Redis、陪伴角色、会员常量。

- `backend/app/core/client_ip.py` — get_client_ip
- `backend/app/core/companion_dialogue.py` — normalize_dialogue_template, normalize_dialogue_templates, apply_nickname_to_template。小人对话台词：昵称占位符，展示时按当前昵称替换。
- `backend/app/core/companion_prop_labels.py` — companion_prop_label, ensure_visual_prop_label。配饰 id / 资源文件名 → 中文展示名。
- `backend/app/core/companion_roles.py` — is_valid_companion_role_id, is_premium_companion_role_id, migrate_gender_to_role_id, render_key_for_role。登岛伙伴角色 id 与历史 gender 字段的映射。
- `backend/app/core/config.py` — Settings；get_settings
- `backend/app/core/logging.py` — setup_logging
- `backend/app/core/member_constants.py` — MemberSource, MembershipType, MemberRecordStatus。会员系统常量。
- `backend/app/core/moment_content.py` — get_story_content, is_voice_moment。故事正文读取：文字故事用 note，语音故事用 speech_text（供 AI 分析）。
- `backend/app/core/redis.py` — init_redis, close_redis, get_redis_client, redis_lifespan
- `backend/app/core/security.py` — verify_password, get_password_hash, create_access_token, decode_access_token
- `backend/app/core/text_utils.py` — soft_truncate。文本软截断：尽量在标点处截断，避免句中硬切。

<a id="kb-backend-app-database"></a>

### `backend/app/database`

异步 SQLAlchemy 会话。

- `backend/app/database/database.py` — Base；get_db

<a id="kb-backend-app-exceptions"></a>

### `backend/app/exceptions`

业务异常和全局处理。

- `backend/app/exceptions/business.py` — BusinessException
- `backend/app/exceptions/handlers.py` — register_exception_handlers

<a id="kb-backend-app-middleware"></a>

### `backend/app/middleware`

请求日志。

- `backend/app/middleware/logging.py` — RequestLoggingMiddleware

<a id="kb-backend-app-models"></a>

### `backend/app/models`

表模型。

- `backend/app/models/companion_role.py` — CompanionRole
- `backend/app/models/daily_mood_report.py` — DailyMoodReport
- `backend/app/models/growth_tag.py` — GrowthTagCategory, GrowthTag
- `backend/app/models/i18n_string.py` — I18nString
- `backend/app/models/member.py` — MemberProduct, MemberRecord, ActivationCode
- `backend/app/models/mood_island.py` — MoodIslandStyle
- `backend/app/models/profile.py` — UserProfile, DailyMoment
- `backend/app/models/rbac.py` — Role, Permission, UserRole
- `backend/app/models/story_island.py` — StoryIsland, StoryIslandDecorUnlock, StoryIslandTask
- `backend/app/models/user.py` — User
- `backend/app/models/user_building_unlock.py` — UserBuildingUnlock
- `backend/app/models/user_growth_state.py` — UserGrowthState
- `backend/app/models/user_xp_grant.py` — UserXpGrant

<a id="kb-backend-app-prompts"></a>

### `backend/app/prompts`

旧学校场景提示词。现行陪伴台词不走这里。

- `backend/app/prompts/system_prompts.py` — GROWTH_OBSERVATION_ANALYSIS_PROMPT

<a id="kb-backend-app-rag"></a>

### `backend/app/rag`

千问调用。可选，没配密钥时相关能力会失败或跳过。

- `backend/app/rag/dashscope_client.py` — DashScopeClient；extract_task_brief
- `backend/app/rag/providers.py` — BaseLLMProvider, BaseEmbeddingProvider
- `backend/app/rag/qwen_provider.py` — QwenLLMProvider, QwenEmbeddingProvider

<a id="kb-backend-app-repositories"></a>

### `backend/app/repositories`

查询。

- `backend/app/repositories/activation_code_repository.py` — ActivationCodeRepository
- `backend/app/repositories/daily_mood_report_repository.py` — DailyMoodReportRepository
- `backend/app/repositories/growth_tag_repository.py` — GrowthTagRepository
- `backend/app/repositories/i18n_string_repository.py` — I18nStringRepository。多语言文案仓储。
- `backend/app/repositories/member_product_repository.py` — MemberProductRepository
- `backend/app/repositories/member_record_repository.py` — MemberRecordRepository
- `backend/app/repositories/mood_island_repository.py` — MoodIslandRepository
- `backend/app/repositories/profile_repository.py` — ProfileRepository, DailyMomentRepository
- `backend/app/repositories/role_repository.py` — RoleRepository
- `backend/app/repositories/rule_repository.py` — RuleRepository, StoryTemplateRepository
- `backend/app/repositories/story_island_repository.py` — StoryIslandRepository
- `backend/app/repositories/user_building_unlock_repository.py` — UserBuildingUnlockRepository
- `backend/app/repositories/user_growth_state_repository.py` — UserGrowthStateRepository
- `backend/app/repositories/user_membership_repository.py` — UserMembershipRepository
- `backend/app/repositories/user_repository.py` — UserRepository
- `backend/app/repositories/user_xp_grant_repository.py` — UserXpGrantRepository

<a id="kb-backend-app-schemas"></a>

### `backend/app/schemas`

请求和响应。

- `backend/app/schemas/ai.py` — AIChatRequest, AIChatResponse, TextToImageRequest
- `backend/app/schemas/auth_entry.py` — AuthEntryRequest, AuthEntryResponse, UserRegisterRequest
- `backend/app/schemas/common.py` — ResponseModel, Pagination
- `backend/app/schemas/growth.py` — EmotionFragmentSummaryRead, GrowthSummaryRead, BuildingUnlockRead
- `backend/app/schemas/growth_observation.py` — WeeklySummaryRead
- `backend/app/schemas/growth_tag.py` — GrowthTagRead, GrowthTagCategoryRead, GrowthTagCategoryCreate
- `backend/app/schemas/i18n.py` — I18nConfigRead, I18nStringRead, I18nStringCreate
- `backend/app/schemas/iap.py` — IapVerifyRequest, IapRestoreRequest, IapVerifyResponse
- `backend/app/schemas/member.py` — MemberMeResponse, MemberRedeemRequest, ActivationCodeCreateRequest
- `backend/app/schemas/mood_island.py` — MoodIslandStyleRead, MoodIslandStyleUpdate
- `backend/app/schemas/profile.py` — ProfileRead, ProfileAppPreferencesUpdate, ProfileNicknameUpdate
- `backend/app/schemas/user.py` — UserCreate, UserLogin, Token

<a id="kb-backend-app-services"></a>

### `backend/app/services`

业务。接口不要把规则写在 endpoint 里。

- `backend/app/services/activation_code_service.py` — ActivationCodeCreateResult, ActivationCodeService。激活码生成与兑换。
- `backend/app/services/ai_service.py` — AIService
- `backend/app/services/apple_service.py` — AppleTransactionInfo, AppleNotificationInfo, AppleTransactionError。Apple StoreKit 2 交易验签与解析（无数据库依赖）。
- `backend/app/services/auth_service.py` — AuthService
- `backend/app/services/building_unlock_service.py` — BuildingUnlockService。用户建筑解锁：写入数据库并在成长刷新时同步。
- `backend/app/services/companion_action_ai_service.py` — CompanionActionAIService
- `backend/app/services/companion_scene_service.py` — CompanionSceneService。Rule-based companion scene for MVP; replace with LLM/image …
- `backend/app/services/daily_mood_report_service.py` — DailyMoodReportService
- `backend/app/services/growth_observation_analysis_service.py` — GrowthObservationAnalysisService。个人成长周期小结：基于心情趋势与记录的轻量 / AI 提示。
- `backend/app/services/growth_points_service.py` — DayActivity, GrowthSummary, GrowthPointsService；aggregate_emotion_fragments。成长值与等级：按日汇总，防止刷次数，奖励坚持与认真记录。
- `backend/app/services/i18n_service.py` — I18nService。多语言文案服务。
- `backend/app/services/iap_service.py` — IapVerifiedPurchase, IapVerifyResult, IapEntitlementSnapshot。iOS 内购接入层：验签后写入 member_records，统一走 MemberService。
- `backend/app/services/member_service.py` — MemberMeSnapshot, MemberRecordInput, MemberService。会员中心核心服务：流水写入与 user_membership 统一刷新。
- `backend/app/services/moment_analysis_service.py` — _TagCatalog, MomentAnalysisService。AI 分析用户故事内容，自动打一级/二级标签与情绪。
- `backend/app/services/moment_photo_service.py` — MomentPhotoService。用户故事照片：按用户/故事分目录存储，不参与 AI 分析。
- `backend/app/services/moment_transcription_service.py` — MomentTranscriptionService。语音转文字：DashScope Paraformer ASR，转写结果供 AI 打标。
- `backend/app/services/moment_voice_pipeline.py` — schedule_voice_transcription。语音故事上传后的异步转写与 AI 打标。
- `backend/app/services/moment_voice_service.py` — MomentVoiceService。用户故事语音：按 voices/年/月 分目录存储，数据库仅存 URL 元数据。
- `backend/app/services/mood_period_summary_service.py` — MoodPeriodSummaryService。周期心情总体总结：仅传聚合统计给 AI，节省 token。
- `backend/app/services/permission_service.py` — PermissionService。会员权限判断。
- `backend/app/services/profile_service.py` — ProfileService；default_story_island_name
- `backend/app/services/rate_limit_service.py` — RateLimitService

<a id="kb-backend-app-tests"></a>

### `backend/app/tests`

后端测试。在 `backend/` 下运行 pytest。

- `backend/app/tests/conftest.py` — fixture：_reset_settings_cache
- `backend/app/tests/test_auth.py` — pytest：test_register_payload_validation_example
- `backend/app/tests/test_client_ip.py` — pytest：test_get_client_ip_prefers_x_real_ip, test_get_client_ip_uses_first_x_forwarded_for, test_get_client_ip_falls_back_to_socket_client
- `backend/app/tests/test_companion_dialogue.py` — pytest：test_story_summary_lines_use_nickname_placeholder, test_story_summary_lines_apply_nickname, test_normalize_dialogue_template_replaces_legacy_nickname 等 5 个
- `backend/app/tests/test_companion_prop_labels.py` — pytest：test_game_prop_label, test_stored_label_has_priority, test_ensure_visual_prop_label_writes_label
- `backend/app/tests/test_companion_roles.py` — pytest：test_migrate_gender_to_role_id, test_resolve_companion_role_id_prefers_role_column, test_render_key_for_role 等 4 个
- `backend/app/tests/test_companion_scene.py` — pytest：test_scene_from_event_tags, test_scene_from_note_overrides
- `backend/app/tests/test_delete_account.py` — pytest：test_remove_user_media_deletes_directory, test_remove_user_media_missing_directory_is_ok
- `backend/app/tests/test_growth_observation.py` — pytest：test_weekly_hint_uses_companion_name, test_weekly_hint_empty_when_no_moments
- `backend/app/tests/test_growth_points_service.py` — pytest：test_story_with_detail_grants_detail_and_story_xp, test_story_without_report_still_grants_story_xp, test_ninety_day_full_attendance_reaches_level_twenty
- `backend/app/tests/test_growth_state.py` — pytest：test_aggregate_emotion_fragments
- `backend/app/tests/test_historical_moment_edit.py` — pytest：test_update_moment_allows_past_date, test_update_moment_rejects_future_date, test_delete_moment_allows_past_date 等 4 个
- `backend/app/tests/test_i18n_service.py` — pytest：test_fallback_tags_prefers_primary_then_zh_cn, test_fallback_chain_has_expected_locales, test_i18n_service_config_default_language
- `backend/app/tests/test_legal_pages.py` — pytest：test_legal_static_files_exist, test_legal_pages_are_publicly_reachable
- `backend/app/tests/test_moment_content.py` — pytest：test_get_story_content_text, test_get_story_content_voice
- `backend/app/tests/test_moment_note_length.py` — pytest：test_moment_note_accepts_long_content, test_moment_note_rejects_over_limit
- `backend/app/tests/test_moment_transcription_service.py` — pytest：test_parse_transcription_payload_from_transcripts, test_parse_transcription_payload_joins_multiple_transcripts, test_extract_transcription_text_from_output_with_url
- `backend/app/tests/test_mood_period_summary.py` — pytest：test_rule_summary_empty, test_clean_summary_trims_at_sentence_boundary, test_incomplete_summary_detected 等 8 个
- `backend/app/tests/test_profile_service_finalize.py` — pytest：test_finalize_moment_scene_import_available
- `backend/app/tests/test_rate_limit_service.py` — pytest：test_rate_limit_hit_allows_under_limit, test_rate_limit_hit_blocks_over_limit, test_ensure_login_not_locked_raises_when_locked 等 5 个
- `backend/app/tests/test_speech_transcription.py` — pytest：test_transcribe_speech_note_returns_text
- `backend/app/tests/test_story_island_buildings.py` — pytest：test_each_category_has_ten_buildings, test_work_island_level_progression, test_unknown_category_uses_fallback
- `backend/app/tests/test_story_island_growth_caps.py` — pytest：test_daily_task_cap_constants, test_clamp_story_island_total_growth_allows_overflow_after_max, test_clamp_story_island_total_growth_zero_for_non_positive 等 11 个
- `backend/app/tests/test_text_utils.py` — pytest：test_soft_truncate_keeps_short_text, test_soft_truncate_breaks_at_punctuation, test_soft_truncate_uses_ellipsis_without_break
- `backend/app/tests/test_update_moment_mood.py` — pytest：test_update_moment_ai_emotion_sets_label_and_keeps_ai_field
- `backend/app/tests/test_update_moment_tags.py` — pytest：test_update_moment_tags_for_voice_without_note

<a id="kb-backend-app-utils"></a>

### `backend/app/utils`

空包。

（只有包标记，没有实现文件。）

<a id="kb-backend-alembic-versions"></a>

### `backend/alembic/versions`

按文件名时间排序。`202606150001_consumer_only_schema.py` 之后才是现在的消费者模型。更早的学校、教师、班级迁移不要当成现行接口。

- `backend/alembic/versions/202606010001_initial_schema.py`
- `backend/alembic/versions/202606010002_story_engine_v11.py`
- `backend/alembic/versions/202606010003_student_mvp.py`
- `backend/alembic/versions/202606010004_mood_island_styles.py`
- `backend/alembic/versions/202606010005_mood_island_biomes.py`
- `backend/alembic/versions/202606010006_daily_mood_reports.py`
- `backend/alembic/versions/202606010007_teacher_alerts.py`
- `backend/alembic/versions/202606010008_teacher_class_name.py`
- `backend/alembic/versions/202606010009_unify_class_family_test.py`
- `backend/alembic/versions/202606010010_growth_observation.py`
- `backend/alembic/versions/202606010011_growth_insight_on_reports.py`
- `backend/alembic/versions/202606010012_dismissed_risk_moments.py`
- `backend/alembic/versions/202606010013_teacher_risk_moment_follows.py`
- `backend/alembic/versions/202606010014_user_nickname.py`
- `backend/alembic/versions/202606090001_user_growth_state.py`
- `backend/alembic/versions/202606090002_daily_moment_client_event_id.py`
- `backend/alembic/versions/202606100001_growth_observation_report.py`
- `backend/alembic/versions/202606110001_user_app_preferences.py`
- `backend/alembic/versions/202606120001_school_classes.py`
- `backend/alembic/versions/202606130001_companion_roles.py`
- `backend/alembic/versions/202606150001_consumer_only_schema.py`
- `backend/alembic/versions/202606150002_rename_insight_summary.py`
- `backend/alembic/versions/202606150003_user_building_unlocks.py`
- `backend/alembic/versions/202606150004_growth_tags_and_moment_ai.py`
- `backend/alembic/versions/202606150005_growth_tag_labels_extra.py`
- `backend/alembic/versions/202606160001_moment_photos.py`
- `backend/alembic/versions/202606210001_moment_voice.py`
- `backend/alembic/versions/202606210002_i18n_strings.py`
- `backend/alembic/versions/202606290001_story_islands.py`
- `backend/alembic/versions/202606290002_story_island_tasks_growth.py`
- `backend/alembic/versions/202606300001_drop_story_island_target_days.py`
- `backend/alembic/versions/202607010002_user_xp_grants.py`
- `backend/alembic/versions/202607070001_iap_storekit.py`
- `backend/alembic/versions/202607070002_member_center.py`
- `backend/alembic/versions/202607080001_member_products_and_default_code.py`
- `backend/alembic/versions/202607090001_update_member_product_prices.py`
- `backend/alembic/versions/202607130001_add_premium_companion_roles.py`
- `backend/alembic/versions/202607140001_fix_premium_companion_role_names.py`

<a id="kb-backend-scripts"></a>

### `backend/scripts`

- `backend/scripts/check_qwen.py` — 检查千问配置是否加载（不打印密钥）。
