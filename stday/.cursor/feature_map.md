# Cursor Feature Map

产品取舍先读 `THE_BOOK_OF_STAR_ISLAND.md`。行为说明在 `docs/CLIENT_SYSTEMS.md`。接口在 `docs/BACKEND_API.md`。

## Auth

```text
lib/features/auth/auth_page.dart
lib/features/auth/register_page.dart
lib/providers/auth_provider.dart
lib/providers/bootstrap_provider.dart
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
lib/features/onboarding/welcome_page.dart     build 返回 LandingPage
lib/features/landing/                         欢迎页区块
lib/features/onboarding/gender_page.dart      选陪伴角色，完成后去 /records
lib/features/onboarding/companion_page.dart
lib/features/onboarding/time_travel_page.dart /onboarding/arrival
lib/features/onboarding/widgets/character_role_picker.dart
```

角色 id 在 `lib/core/constants/companion_roles.dart`。`yuan`（小愿）、`meng`（小梦）是会员角色。

```text
ProfileRepository
profileProvider
```

## 首页与岛屿编排

```text
lib/features/island/island_home_page.dart     /island，总编排，文件很长
lib/features/home/home_page.dart              滚动首页，由岛屿页嵌入
lib/features/home/widgets/world_section.dart
lib/features/home/widgets/world_preview_*.dart
lib/features/home/providers/home_island_slots_provider.dart
lib/features/home/providers/home_greeting_provider.dart
lib/features/island/widgets/story_island_static_detail_viewport.dart
lib/features/island/widgets/story_island_collapsible_task_dock.dart
lib/features/island/widgets/story_island_moments_dialog.dart
lib/features/island/story_island_progress.dart
lib/island/viewport/growth_world_viewport.dart
lib/island/widgets/island_hud_overlay.dart
lib/island/widgets/building_info_bubble.dart
lib/features/island/widgets/island_companion_speech_overlay.dart
```

状态：

```text
lib/island/providers/growth_summary_provider.dart
lib/island/providers/building_unlocks_provider.dart
lib/island/providers/island_world_provider.dart
lib/providers/island_weather_provider.dart
lib/providers/current_island_provider.dart
lib/providers/app_providers.dart
  profileProvider
  todayMomentsProvider
  homeStoryFeedMomentsProvider          近 21 天，首页用
  recentStoryMomentsProvider            近 365 天，首页不要 watch
  storyIslandGroupsProvider
  growthMainIslandProvider
lib/providers/main_shell_tab_provider.dart
lib/providers/world_state_provider.dart
```

打开副岛详情、主岛详情、离开岛屿 Tab、App 不在前台时，主岛引擎暂停。

## 故事岛

```text
StoryIslandRepository / storyIslandRepositoryProvider
lib/data/models/story_island_models.dart
lib/core/constants/story_island_building_catalog.dart
lib/core/constants/story_island_layout.dart
lib/core/constants/story_island_size.dart          每级 30，满级 300
lib/core/utils/story_island_names.dart
lib/world/preview/story_island_world_builder.dart
lib/features/today/story_island_placement_sheet.dart
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
lib/world/engine/growth_world_engine.dart
lib/world/engine/world_state.dart
lib/world/engine/world_state_v2.dart
lib/world/engine/growth_world_input.dart
lib/world/rendering/world_state_cache.dart
lib/world/scene/world_scene.dart
lib/world/scene/scene_depth_priority.dart
lib/world/scene/island_gesture_surface.dart
lib/world/scene/layers/
lib/world/island/
lib/world/preview/
lib/island/generator/island_generator.dart
```

改层序和字段先读 `.cursor/game_system.md`。

## Today / 日常

```text
lib/features/today/write_story_page.dart
lib/features/today/add_moment_flow.dart
lib/features/today/daily_entry_flow.dart
lib/features/today/moment_form_widgets.dart
lib/features/today/moment_photo_section.dart
lib/features/today/moment_mood_picker.dart
lib/features/today/edit_moment_sheet.dart
lib/features/today/edit_moment_tags_page.dart
lib/features/today/moment_detail_page.dart
lib/features/today/voice_analysis_poll.dart
lib/features/today/widgets/story_voice_input_panel.dart
lib/features/today/widgets/speech_dictation_overlay.dart
lib/features/today/write_story_draft_store.dart
lib/core/voice/
lib/core/speech/speech_note_merge.dart
lib/providers/story_day_provider.dart
```

```text
MomentRepository
VoiceRepository
```

VIP：语音模式、加照片、改历史心情。当日第一条小人对话免费，其余要 VIP（`canUseFreeCompanionDialogue`）。

## Records

```text
lib/features/records/record_page.dart
lib/features/records/widgets/
lib/features/today/today_story_card.dart
```

`storyDayViewProvider`、`todayMomentsProvider`。补写历史日期要 VIP。

## Status / 洞察

```text
lib/features/status/mood_status_page.dart
lib/features/status/widgets/
lib/providers/mood_status_provider.dart
lib/providers/mood_report_check_in_provider.dart
lib/providers/growth_observation_provider.dart
lib/providers/growth_tag_provider.dart
```

```text
MoodRepository
GrowthRepository
```

非 VIP：心情统计和标签统计用 `VipFeatureMask`；`moodPeriodSummaryProvider` 与 `weeklySummaryProvider` 返回空数据，不打那些接口。

## Growth / 用户等级

```text
lib/core/growth/growth_system.dart
lib/core/growth/island_unlock_catalog.dart
lib/core/growth/level_unlock_preview.dart
lib/core/growth/daily_level_unlock_prompt.dart
lib/core/growth/level_title_assets.dart
lib/features/achievement/growth_reward_actions.dart
lib/design_system/growth_reward_dialog.dart
```

数值必须与 `backend/app/services/growth_points_service.py` 一致。这是用户 Lv1–Lv20，不是副岛的 10 级。

## 会员 / 内购

```text
lib/features/membership/membership_page.dart          /more/membership
lib/providers/member_provider.dart                    memberProvider、isVipProvider
lib/providers/iap_provider.dart                       iapCatalogProvider
lib/providers/membership_feature_provider.dart        免费额度判断
lib/core/membership/vip_guard.dart
lib/core/membership/iap_product_ids.dart
lib/core/membership/iap_lifecycle_host.dart
lib/core/membership/member_lifecycle_host.dart
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
lib/features/more/more_page.dart
lib/features/more/my_level_page.dart
lib/features/more/reminder_settings_page.dart
lib/features/more/audio_settings_page.dart
lib/features/more/companion_showcase_page.dart
lib/features/more/app_about_page.dart
```

## 提醒

```text
lib/core/notifications/story_reminder_service.dart
lib/core/notifications/reminder_lifecycle_host.dart
UserPreferencesRepository          PATCH /profile/app-preferences
```

## 天气

```text
lib/core/weather/island_weather_service.dart
lib/core/weather/weather_display.dart
lib/providers/island_weather_provider.dart
lib/world/systems/mood_environment_controller.dart
lib/world/systems/config/weather_atmosphere_config.dart
```

天气请求留在 core/provider。world 只接收已经取到的天气输入。

## 音频

```text
lib/core/audio/app_audio_assets.dart       AppBgmContext、AppSfx、资源名
lib/core/audio/app_audio_controller.dart
lib/core/audio/app_audio_settings.dart
lib/providers/app_audio_provider.dart
lib/features/more/audio_settings_page.dart
```

路由上的 `_AudioRouteHost` 决定播哪条 BGM。岛和欢迎页 6:00–19:00 为白天曲。

## 法律

```text
lib/core/legal/legal_documents.dart        正文在客户端
lib/core/legal/legal_urls.dart
lib/features/legal/legal_document_page.dart
/legal/terms
/legal/privacy
```

未登录可打开。

## 小组件

见 `.cursor/widget_architecture.md`。

```text
lib/services/island_widget_models.dart
lib/services/island_widget_service.dart
lib/providers/island_widget_sync_provider.dart
lib/providers/widget_navigation_provider.dart
lib/router/widget_deep_link_handler.dart
lib/core/widgets/island_widget_day_rollover_host.dart
ios/IslandWidget/
android/app/src/main/kotlin/com/stday/stday/IslandWidgetProvider.kt
```

## L10n

```text
lib/l10n/                         生成物
lib/core/l10n/locale_controller.dart
AppLocalizationRepository         /api/v1/i18n/config 与 /bundle
```

## Design System

`lib/design_system/` 只放纯 UI。不读 provider，不调 repository。业务数据由 feature wrapper 以普通参数传入。现有例子：`features/shared/widgets/mood_companion_loading.dart` → `companion_loading.dart`。

## Assets

```text
assets/images/buildings/                 主岛
assets/images/decor/
assets/images/islands/<分类>/buildings/  副岛 lv01–lv10
assets/images/companion/
assets/images/mood_faces/
assets/images/titles/
assets/images/story_categories/
assets/images/story_tags/
assets/images/moment_details/
assets/images/auth/
assets/audio/
```

删除前读 `unused_assets.md` 和 `cleanup_report.md`。副岛图按目录和 catalog 动态引用，静态搜索找不到引用不等于没用。
