import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/companion_roles.dart';
import '../../core/constants/emotion_catalog.dart';
import '../../core/growth/growth_system.dart';
import '../../core/growth/today_mood_display.dart';
import '../../data/models/profile_models.dart';
import '../../core/weather/real_weather_snapshot.dart';
import '../../providers/app_providers.dart';
import '../../providers/island_weather_provider.dart';
import '../../providers/story_day_provider.dart';
import '../../providers/world_state_provider.dart';
import '../../world/engine/world_state.dart';
import '../service/island_build_service.dart';
import '../service/island_style_resolver.dart';
import 'growth_summary_provider.dart';

final islandBuildServiceProvider = Provider<IslandBuildService>(
  (_) => IslandBuildService(),
);

final islandStyleResolverProvider = Provider<IslandStyleResolver>(
  (_) => const IslandStyleResolver(),
);

WorldState _buildIslandWorldState({
  required Ref ref,
  required GrowthSummary summary,
  required String emotionId,
  required List<DailyMomentModel> moments,
  required bool compact,
  RealWeatherSnapshot? weather,
}) {
  final legacyMoodId = emotionById(emotionId).legacyMoodId;
  final profile = ref.read(profileProvider).valueOrNull;
  final style = ref.read(islandStyleResolverProvider).resolve(
        moodId: legacyMoodId,
        weather: weather,
      );
  final companion = ref.read(userCompanionProvider);

  return ref.read(islandBuildServiceProvider).build(
        engine: ref.read(growthWorldEngineProvider),
        summary: summary,
        todayMood: emotionId,
        moments: moments,
        islandStyle: style,
        companionStyle: companion.renderStyle,
        companionGender: CompanionRoles.resolveRenderKey(
          companionRoleId: profile?.companionRoleId,
          legacyGender: profile?.gender,
        ),
        compact: compact,
        weather: weather,
      );
}

/// 轻量预览：仅 summary + 今日 landing 心情，不绑日常列表与 GPS 天气。
final islandWorldPreviewProvider = Provider<WorldState>((ref) {
  final summary =
      ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();
  final profile = ref.watch(profileProvider).valueOrNull;
  final emotionId = resolveTodayLandingMoodId(profile: profile);

  return _buildIslandWorldState(
    ref: ref,
    summary: summary,
    emotionId: emotionId,
    moments: const [],
    compact: true,
    weather: null,
  );
});

/// 全屏详情 / 主岛交互：含今日日常统计心情与真实天气。
final islandWorldProvider = Provider<WorldState>((ref) {
  final summary =
      ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();
  final profile = ref.watch(profileProvider).valueOrNull;
  final moments = ref.watch(todayMomentsProvider).valueOrNull ?? [];
  final weather = ref.watch(islandWeatherProvider).valueOrNull;
  final emotionId = moments.isNotEmpty
      ? (resolveStoryDayMoodId(
            viewingToday: true,
            moments: moments,
            profileTodayMood: profile?.todayMood,
          ) ??
          defaultEmotionId)
      : resolveTodayLandingMoodId(profile: profile);

  return _buildIslandWorldState(
    ref: ref,
    summary: summary,
    emotionId: emotionId,
    moments: moments,
    compact: false,
    weather: weather,
  );
});
