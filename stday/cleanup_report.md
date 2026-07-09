# Cleanup Report

## 删除的 Dart 文件

- `lib/assets_pipeline/asset_registry.dart`
- `lib/core/growth/growth_level_progress_view.dart`
- `lib/core/speech/speech_input_bridge.dart`
- `lib/core/speech/speech_note_input.dart`
- `lib/core/storage/growth_island_rules_store.dart`
- `lib/core/utils/client_moment_factory.dart`
- `lib/design_system/confetti_paper.dart`
- `lib/design_system/gentle_buttons.dart`
- `lib/design_system/growth_island_widget.dart`
- `lib/design_system/mood_face_asset_catalog.dart`
- `lib/design_system/mood_pentagon.dart`
- `lib/design_system/mood_radar_chart.dart`
- `lib/design_system/phone_viewport.dart`
- `lib/design_system/serene_lagoon_island_painter.dart`
- `lib/design_system/slow_progress_bar.dart`
- `lib/design_system/warm_background.dart`
- `lib/features/landing/landing_growth_provider.dart`
- `lib/features/today/daily_mood_prompt.dart`
- `lib/features/today/daily_mood_report_action.dart`
- `lib/features/today/moment_generating_panel.dart`
- `lib/features/today/moment_story_card.dart`
- `lib/features/today/today_stories_page.dart`
- `lib/features/today/widgets/growth_world_viewport.dart`
- `lib/features/today/widgets/story_flow_capsule_progress.dart`
- `lib/features/today/widgets/today_mood_recap_bar.dart`
- `lib/island/path/path_material_painter.dart`
- `lib/island/path/path_projection.dart`
- `lib/island/service/building_unlock_resolver.dart`
- `lib/world/rendering/cozy_tree_renderer.dart`
- `lib/world/scene/layers/ambient_life_layer.dart`
- `lib/world/scene/layers/flora_layer.dart`
- `lib/world/scene/layers/foreground_grass_layer.dart`
- `lib/world/scene/layers/growth_ambient_layer.dart`
- `lib/world/scene/layers/landmark_layer.dart`
- `lib/world/scene/layers/path_layer.dart`

## 删除的资源

- 未删除资源。资源审计见 `unused_assets.md`。所有未直接文本引用的资源均处于 pubspec 声明目录或 `AssetManifest` runtime catalog 目录，当前不建议直接删除。

## 删除/整理的依赖

- 删除 `speech_to_text`，并由 `flutter pub get` 移除 `speech_to_text_platform_interface`、`speech_to_text_windows`。
- 新增直接依赖 `http_parser: ^4.1.2`，因为上传接口代码直接使用 `MediaType`。
- 保留其它依赖：扫描到 `flame`、`flutter_svg`、`image_picker`、`permission_handler`、`record`、`just_audio`、`audio_session`、`path_provider`、`flutter_local_notifications`、`flutter_timezone`、`timezone`、`geolocator`、`collection` 等仍有引用。

## 整理的代码

- 运行 `dart fix --apply` 清理 unused import、unnecessary import、无效 `show` 导出、无效 `!`、部分 const/collection lint。
- 删除 analyzer 确认的私有未引用方法：`CompanionSpec._exprFromMood`、`CompanionSpec._expressionMatchesMood`、`IslandRenderer._drawProsperityBridge`、`IslandRenderer._drawBuiltPaths`、`IslandRenderer._drawMicroStructures`、`CharacterLayer._starCoreColor`。
- 删除 `MomentDetailPage` 中未使用局部变量。
- 修复测试侧清理问题：移除错误 const `Vector2`，补齐 `DailyMoodPromptStore` 测试 import。
- 运行 `dart format lib test` 统一格式。

## 未删除/保留说明

- `debugPrint`/`assert` 中剩余项属于初始化、通知调度、图片生成失败等诊断或构造参数约束，不按临时代码删除。
- 大量图片未出现文本直接引用，但由目录声明、`AssetManifest` catalog、服务端字段或动态 token 映射使用，已列入 `unused_assets.md` 且建议不删除。
- `lib/core/constants/growth_tag_seed.dart` 曾被引用图误判，已恢复；它是 provider 的离线回退数据。

## 未来建议

- 逐个处理 analyzer 剩余的 `use_build_context_synchronously` info，需要结合页面生命周期验证，避免改变 async UI 行为。
- 为动态资源 catalog 建立机器可读白名单或 manifest test，后续资源清理就能更激进且更安全。
- 当前资源体积较大，建议后续单独做图片压缩/WebP 转换和重复图片哈希去重。

## Verification

- `flutter analyze` completed with 9 info-level `use_build_context_synchronously` diagnostics and no analyzer errors/warnings.
- `flutter test` ran 126 tests: 115 passed and 11 failed. Failures are in existing growth/decor expectation tests and `speech_note_merge` spacing expectations; they were not changed as part of cleanup to avoid altering business behavior.
- `flutter pub get` completed and refreshed dependency lock/plugin generated files after removing `speech_to_text`; the China pub mirror also emitted a non-fatal advisory decoding warning for `shared_preferences_android`.
