# Cursor Feature Map

本文件用于快速定位业务模块。

## Auth / 登录注册

页面：

```text
lib/features/auth/auth_page.dart
lib/features/auth/register_page.dart
```

状态：

```text
lib/providers/auth_provider.dart
lib/providers/bootstrap_provider.dart
```

Repository：

```text
AuthRepository
authRepositoryProvider
```

相关 API：

```text
/api/v1/auth/entry
/api/v1/auth/login
/api/v1/auth/register
```

## Onboarding / 新手流程

页面：

```text
lib/features/onboarding/welcome_page.dart
lib/features/onboarding/gender_page.dart
lib/features/onboarding/companion_page.dart
lib/features/onboarding/time_travel_page.dart
```

相关：

```text
ProfileRepository
profileProvider
```

## Island / 岛屿首页

页面：

```text
lib/features/island/island_home_page.dart
```

Viewport：

```text
lib/island/viewport/growth_world_viewport.dart
```

HUD：

```text
lib/island/widgets/island_hud_overlay.dart
lib/island/widgets/building_info_bubble.dart
lib/features/island/widgets/island_companion_speech_overlay.dart
```

Provider：

```text
lib/island/providers/growth_summary_provider.dart
lib/island/providers/building_unlocks_provider.dart
lib/island/providers/island_world_provider.dart
lib/providers/island_weather_provider.dart
```

## World / Game Rendering

Engine：

```text
lib/world/engine/growth_world_engine.dart
lib/world/engine/world_state.dart
lib/world/engine/growth_world_input.dart
```

Scene：

```text
lib/world/scene/world_scene.dart
lib/world/scene/island_gesture_surface.dart
lib/world/scene/layers/
```

Island renderer：

```text
lib/world/island/
```

Character renderer：

```text
lib/world/scene/layers/character_layer.dart
lib/world/rendering/cozy_hero_renderer.dart
lib/world/rendering/companion_picture_cache.dart
```

## Today / 日常记录

主要页面与流程：

```text
lib/features/today/write_story_page.dart
lib/features/today/add_moment_flow.dart
lib/features/today/daily_entry_flow.dart
lib/features/today/mood_today_card.dart
```

表单与输入：

```text
lib/features/today/moment_form_widgets.dart
lib/features/today/widgets/story_voice_input_panel.dart
lib/features/today/widgets/story_voice_bubble.dart
lib/features/today/moment_photo_section.dart
```

编辑：

```text
lib/features/today/edit_moment_sheet.dart
lib/features/today/edit_moment_tags_page.dart
lib/features/today/moment_mood_picker.dart
lib/features/today/moment_detail_page.dart
```

语音：

```text
lib/features/today/voice_analysis_poll.dart
lib/core/voice/
```

Provider：

```text
lib/providers/story_day_provider.dart
```

Repository：

```text
MomentRepository
VoiceRepository
MoodRepository
```

## Records / 记录列表

页面：

```text
lib/features/records/record_page.dart
```

Widget：

```text
lib/features/records/widgets/
lib/features/today/today_story_card.dart
```

相关：

```text
storyDayViewProvider
todayMomentsProvider
MomentRepository
```

## Status / 心情与洞察

页面：

```text
lib/features/status/mood_status_page.dart
```

Widget：

```text
lib/features/status/widgets/
```

Provider：

```text
lib/providers/mood_status_provider.dart
lib/providers/mood_report_check_in_provider.dart
lib/providers/growth_observation_provider.dart
```

Repository：

```text
MoodRepository
GrowthRepository
MomentRepository
```

## Growth / 成长系统

核心：

```text
lib/core/growth/growth_system.dart
lib/core/growth/island_unlock_catalog.dart
lib/core/growth/level_unlock_preview.dart
lib/core/growth/daily_level_unlock_prompt.dart
```

奖励业务编排：

```text
lib/features/achievement/growth_reward_actions.dart
```

纯 UI：

```text
lib/design_system/growth_reward_dialog.dart
```

Provider：

```text
lib/island/providers/growth_summary_provider.dart
lib/island/providers/building_unlocks_provider.dart
```

Repository：

```text
GrowthRepository
```

## More / 我的与设置

页面：

```text
lib/features/more/more_page.dart
lib/features/more/my_level_page.dart
lib/features/more/reminder_settings_page.dart
lib/features/more/companion_showcase_page.dart
lib/features/more/app_about_page.dart
```

Widget：

```text
lib/features/more/widgets/
```

相关：

```text
UserPreferencesRepository
MomentRepository
GrowthRepository
```

## Reminder / 提醒

Service：

```text
lib/core/notifications/story_reminder_service.dart
lib/core/notifications/reminder_lifecycle_host.dart
```

页面：

```text
lib/features/more/reminder_settings_page.dart
```

存储：

```text
SharedPreferences
UserPreferencesRepository
```

## Weather / 天气

Service：

```text
lib/core/weather/island_weather_service.dart
lib/core/weather/weather_display.dart
```

Provider：

```text
lib/providers/island_weather_provider.dart
```

World environment：

```text
lib/world/systems/mood_environment_controller.dart
lib/world/systems/config/weather_atmosphere_config.dart
```

## L10n / 本地化

生成文件：

```text
lib/l10n/
```

Controller：

```text
lib/core/l10n/locale_controller.dart
```

Repository：

```text
AppLocalizationRepository
```

## Design System / 纯 UI

目录：

```text
lib/design_system/
```

规则：

- 只放纯 UI。
- 不读 provider。
- 不调用 repository。

当前重要组件：

```text
companion_loading.dart
growth_reward_dialog.dart
moment_tag_chips.dart
island_chip.dart
island_decorations.dart
mood_face_icon.dart
user_companion_view.dart
```

## Data / API

Facade/provider：

```text
lib/data/repositories/app_repository_facades.dart
```

Datasource：

```text
lib/data/repositories/app_repository.dart
```

Models：

```text
lib/data/models/
```

## Assets

```text
assets/images/buildings/
assets/images/decor/
assets/images/story_categories/
assets/images/story_tags/
assets/images/moment_details/
assets/images/mood_faces/
assets/images/companion/
assets/images/auth/
assets/images/titles/
```

删除资源前必须读：

```text
unused_assets.md
cleanup_report.md
```
