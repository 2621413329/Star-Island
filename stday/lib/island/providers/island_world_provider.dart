import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/companion_roles.dart';
import '../../core/constants/emotion_catalog.dart';
import '../../core/growth/growth_system.dart';
import '../../providers/app_providers.dart';
import '../../providers/island_weather_provider.dart';
import '../../providers/story_day_provider.dart';
import '../../providers/world_state_provider.dart';
import '../../world/engine/world_state.dart';
import '../service/island_build_service.dart';
import '../service/island_style_resolver.dart';
import 'growth_summary_provider.dart';

final islandBuildServiceProvider = Provider<IslandBuildService>(
  (_) => const IslandBuildService(),
);

final islandStyleResolverProvider = Provider<IslandStyleResolver>(
  (_) => const IslandStyleResolver(),
);

/// 岛屿首页使用的世界快照（固定岛型 + 繁荣度 + 仅氛围随 mood）。
final islandWorldProvider = Provider<WorldState>((ref) {
  final summary =
      ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();
  final profile = ref.watch(profileProvider).valueOrNull;
  final moments = ref.watch(todayMomentsProvider).valueOrNull ?? [];
  final weather = ref.watch(islandWeatherProvider).valueOrNull;
  final emotionId = resolveStoryDayMoodId(
        viewingToday: true,
        moments: moments,
        profileTodayMood: profile?.todayMood,
      ) ??
      profile?.todayMood ??
      defaultEmotionId;
  final legacyMoodId = emotionById(emotionId).legacyMoodId;
  final style = ref.read(islandStyleResolverProvider).resolve(
        moodId: legacyMoodId,
        weather: weather,
      );
  final companion = ref.watch(userCompanionProvider);

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
        compact: false,
        weather: weather,
      );
});
