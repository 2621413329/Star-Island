# Cursor Feature Map

产品取舍先读 `stday/THE_BOOK_OF_STAR_ISLAND.md`。行为说明在 `knowledge/review/CLIENT_SYSTEMS.md`。接口在 `knowledge/BACKEND_API.md`。每个源文件的目录索引在 `knowledge/ai/code_index.md`，本文件只写业务怎么串。

## Auth

```text
stday/lib/features/auth/auth_page.dart
stday/lib/features/auth/register_page.dart
stday/lib/providers/auth_provider.dart
stday/lib/providers/bootstrap_provider.dart
AuthRepository / authRepositoryProvider
```

```text
POST /api/v1/auth/entry
POST /api/v1/auth/login
POST /api/v1/auth/register
DELETE /api/v1/auth/me
```

## Onboarding / 欢迎

```text
stday/lib/features/onboarding/welcome_page.dart     build 返回 LandingPage
stday/lib/features/landing/                         欢迎页区块
stday/lib/features/onboarding/gender_page.dart      选陪伴角色，完成后去 /records
stday/lib/features/onboarding/companion_page.dart
stday/lib/features/onboarding/time_travel_page.dart /onboarding/arrival
stday/lib/features/onboarding/widgets/character_role_picker.dart
```

角色 id 在 `stday/lib/core/constants/companion_roles.dart`。`yuan`（小愿）、`meng`（小梦）是会员角色。

```text
ProfileRepository
profileProvider
```

## 首页与岛屿编排

```text
stday/lib/features/island/island_home_page.dart     /island，总编排，文件很长
stday/lib/features/home/home_page.dart              滚动首页，由岛屿页嵌入
stday/lib/features/home/widgets/world_section.dart
stday/lib/features/home/widgets/world_preview_*.dart
stday/lib/features/home/providers/home_island_slots_provider.dart
stday/lib/features/home/providers/home_greeting_provider.dart
stday/lib/features/island/widgets/story_island_static_detail_viewport.dart
stday/lib/features/island/widgets/story_island_collapsible_task_dock.dart
stday/lib/features/island/widgets/story_island_moments_dialog.dart
stday/lib/features/island/story_island_progress.dart
stday/lib/island/viewport/growth_world_viewport.dart
stday/lib/island/widgets/island_hud_overlay.dart
stday/lib/island/widgets/building_info_bubble.dart
stday/lib/features/island/widgets/island_companion_speech_overlay.dart
```

状态：

```text
stday/lib/island/providers/growth_summary_provider.dart
stday/lib/island/providers/building_unlocks_provider.dart
stday/lib/island/providers/island_world_provider.dart
stday/lib/providers/island_weather_provider.dart
stday/lib/providers/current_island_provider.dart
stday/lib/providers/app_providers.dart
  profileProvider
  todayMomentsProvider
  homeStoryFeedMomentsProvider          近 21 天，首页用
  recentStoryMomentsProvider            近 365 天，首页不要 watch
  storyIslandGroupsProvider
  growthMainIslandProvider
stday/lib/providers/main_shell_tab_provider.dart
stday/lib/providers/world_state_provider.dart
```

打开副岛详情、主岛详情、离开岛屿 Tab、App 不在前台时，主岛引擎暂停。

## 故事岛

```text
StoryIslandRepository / storyIslandRepositoryProvider
stday/lib/data/models/story_island_models.dart
stday/lib/core/constants/story_island_building_catalog.dart
stday/lib/core/constants/story_island_layout.dart
stday/lib/core/constants/story_island_size.dart          每级 30，满级 300
stday/lib/core/utils/story_island_names.dart
stday/lib/world/preview/story_island_world_builder.dart
stday/lib/features/today/story_island_placement_sheet.dart
backend/app/config/story_island_buildings.py
```

分类：`work study health social life finance milestone inspiration creation emotion achievement`。

非 VIP 每个分类 1 座未归档岛：`nonVipStoryIslandLimitPerCategory`。

接口：

```text
GET/POST /api/v1/profile/story-islands
PATCH    /api/v1/profile/story-islands/{id}
GET      /api/v1/profile/growth-main-island
任务 CRUD 与 complete / uncomplete
PATCH    /api/v1/profile/moments/{id}/story-island
```

## World / 主岛渲染

```text
stday/lib/world/engine/growth_world_engine.dart
stday/lib/world/engine/world_state.dart
stday/lib/world/engine/world_state_v2.dart
stday/lib/world/engine/growth_world_input.dart
stday/lib/world/rendering/world_state_cache.dart
stday/lib/world/scene/world_scene.dart
stday/lib/world/scene/scene_depth_priority.dart
stday/lib/world/scene/island_gesture_surface.dart
stday/lib/world/scene/layers/
stday/lib/world/island/
stday/lib/world/preview/
stday/lib/island/generator/island_generator.dart
```

改层序和字段先读 `knowledge/ai/game_system.md`。

## Today / 日常

```text
stday/lib/features/today/write_story_page.dart
stday/lib/features/today/add_moment_flow.dart
stday/lib/features/today/daily_entry_flow.dart
stday/lib/features/today/moment_form_widgets.dart
stday/lib/features/today/moment_photo_section.dart
stday/lib/features/today/moment_mood_picker.dart
stday/lib/features/today/edit_moment_sheet.dart
stday/lib/features/today/edit_moment_tags_page.dart
stday/lib/features/today/moment_detail_page.dart
stday/lib/features/today/voice_analysis_poll.dart
stday/lib/features/today/widgets/story_voice_input_panel.dart
stday/lib/features/today/widgets/speech_dictation_overlay.dart
stday/lib/features/today/write_story_draft_store.dart
stday/lib/core/voice/
stday/lib/core/speech/speech_note_merge.dart
stday/lib/providers/story_day_provider.dart
```

```text
MomentRepository
VoiceRepository
```

VIP：把录音保存成一条语音日常、加照片、改历史心情。当天第一条小人对话免费，其余要 VIP（`canUseFreeCompanionDialogue`）。

文字框里「按住说话」是另一条路：转写插进正文，不查 VIP。见 `knowledge/review/CLIENT_SYSTEMS.md` 第 14 节。照片在日常保存成功后按差量上传，第 15 节。升级庆祝和种子动画在第 17 节。

## Records

```text
stday/lib/features/records/record_page.dart
stday/lib/features/records/widgets/
stday/lib/features/today/today_story_card.dart
```

`storyDayViewProvider`、`todayMomentsProvider`。补写历史日期要 VIP。

## Status / 洞察

```text
stday/lib/features/status/mood_status_page.dart
stday/lib/features/status/widgets/
stday/lib/providers/mood_status_provider.dart
stday/lib/providers/mood_report_check_in_provider.dart
stday/lib/providers/growth_observation_provider.dart
stday/lib/providers/growth_tag_provider.dart
```

```text
MoodRepository
GrowthRepository
```

非 VIP：心情统计和标签统计用 `VipFeatureMask`；`moodPeriodSummaryProvider` 与 `weeklySummaryProvider` 返回空数据，不打那些接口。

## Growth / 用户等级

```text
stday/lib/core/growth/growth_system.dart
stday/lib/core/growth/island_unlock_catalog.dart
stday/lib/core/growth/level_unlock_preview.dart
stday/lib/core/growth/daily_level_unlock_prompt.dart
stday/lib/core/growth/level_title_assets.dart
stday/lib/features/achievement/growth_reward_actions.dart
stday/lib/design_system/growth_reward_dialog.dart
```

数值必须与 `backend/app/services/growth_points_service.py` 一致。这是用户 Lv1–Lv20，不是副岛的 10 级。

## 会员 / 内购

```text
stday/lib/features/membership/membership_page.dart          /more/membership
stday/lib/providers/member_provider.dart                    memberProvider、isVipProvider
stday/lib/providers/iap_provider.dart                       iapCatalogProvider
stday/lib/providers/membership_feature_provider.dart        免费额度判断
stday/lib/core/membership/vip_guard.dart
stday/lib/core/membership/iap_product_ids.dart
stday/lib/core/membership/iap_lifecycle_host.dart
stday/lib/core/membership/member_lifecycle_host.dart
MemberRepository
IapRepository
```

```text
GET/POST /api/v1/member/me|redeem
POST     /api/v1/iap/verify|restore
GET      /api/v1/iap/me
```

## More

```text
stday/lib/features/more/more_page.dart
stday/lib/features/more/my_level_page.dart
stday/lib/features/more/reminder_settings_page.dart
stday/lib/features/more/audio_settings_page.dart
stday/lib/features/more/companion_showcase_page.dart
stday/lib/features/more/app_about_page.dart
```

## 提醒

```text
stday/lib/core/notifications/story_reminder_service.dart
stday/lib/core/notifications/reminder_lifecycle_host.dart
UserPreferencesRepository          PATCH /profile/app-preferences
```

## 天气

```text
stday/lib/core/weather/island_weather_service.dart
stday/lib/core/weather/weather_display.dart
stday/lib/providers/island_weather_provider.dart
stday/lib/world/systems/mood_environment_controller.dart
stday/lib/world/systems/config/weather_atmosphere_config.dart
```

天气请求留在 core/provider。world 只接收已经取到的天气输入。

## 音频

```text
stday/lib/core/audio/app_audio_assets.dart       AppBgmContext、AppSfx、资源名
stday/lib/core/audio/app_audio_controller.dart
stday/lib/core/audio/app_audio_settings.dart
stday/lib/providers/app_audio_provider.dart
stday/lib/features/more/audio_settings_page.dart
```

路由上的 `_AudioRouteHost` 决定播哪条 BGM。岛和欢迎页 6:00–19:00 为白天曲。

## 法律

```text
stday/lib/core/legal/legal_documents.dart        正文在客户端
stday/lib/core/legal/legal_urls.dart
stday/lib/features/legal/legal_document_page.dart
/legal/terms
/legal/privacy
```

未登录可打开。

## 小组件

见 `knowledge/ai/widget_architecture.md`。

```text
stday/lib/services/island_widget_models.dart
stday/lib/services/island_widget_service.dart
stday/lib/providers/island_widget_sync_provider.dart
stday/lib/providers/widget_navigation_provider.dart
stday/lib/router/widget_deep_link_handler.dart
stday/lib/core/widgets/island_widget_day_rollover_host.dart
stday/ios/IslandWidget/
stday/android/app/src/main/kotlin/com/stday/IslandWidgetProvider.kt
```

## L10n

```text
stday/lib/l10n/                         生成物
stday/lib/core/l10n/locale_controller.dart
AppLocalizationRepository         /api/v1/i18n/config 与 /bundle
```

## Design System

`stday/lib/design_system/` 只放纯 UI。不读 provider，不调 repository。业务数据由 feature wrapper 以普通参数传入。现有例子：`features/shared/widgets/mood_companion_loading.dart` → `companion_loading.dart`。

## Assets

```text
assets/images/buildings/                 主岛
stday/assets/images/decor/
assets/images/islands/<分类>/buildings/  副岛 lv01–lv10
stday/assets/images/companion/
stday/assets/images/mood_faces/
stday/assets/images/titles/
stday/assets/images/story_categories/
stday/assets/images/story_tags/
stday/assets/images/moment_details/
stday/assets/images/auth/
stday/assets/audio/
```

删除前读 `stday/unused_assets.md` 和 `stday/cleanup_report.md`。副岛图按目录和 catalog 动态引用，静态搜索找不到引用不等于没用。
