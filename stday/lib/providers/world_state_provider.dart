import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/character_mood.dart';
import '../core/models/mood_island_config.dart';
import '../data/models/profile_models.dart';
import '../providers/app_providers.dart';
import '../world/engine/growth_event.dart';
import '../world/engine/growth_world_engine.dart';
import '../world/engine/growth_world_input.dart';
import '../world/engine/world_state.dart';

final growthWorldEngineProvider = Provider<GrowthWorldEngine>((ref) => GrowthWorldEngine());

class WorldSceneParams {
  const WorldSceneParams({
    required this.worldState,
    this.companionStyle = 'chibi',
    this.compact = false,
    this.highlightedEventId,
  });

  final WorldState worldState;
  final String companionStyle;
  final bool compact;
  final String? highlightedEventId;
}

final worldSceneParamsProvider = Provider<WorldSceneParams>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final moments = ref.watch(todayMomentsProvider).valueOrNull ?? [];
  final islandRegistry = ref.watch(moodIslandRegistryProvider).valueOrNull ?? MoodIslandRegistry.defaults();
  final moodId = profile?.todayMood;
  final mood = CharacterMood.fromString(moodId);
  final islandStyle = islandRegistry.resolve(moodId);
  final events = moments.map(GrowthEvent.fromMoment).toList();
  final userProfile = UserGrowthProfile.fromEvents(mood, events);

  final engine = ref.watch(growthWorldEngineProvider);
  final worldState = engine.build(GrowthWorldInput(
    mood: mood,
    events: events,
    islandStyle: islandStyle,
    profile: userProfile,
    companionStyle: profile?.companionStyle ?? 'chibi',
    companionGender: profile?.gender,
  ));

  return WorldSceneParams(
    worldState: worldState,
    companionStyle: profile?.companionStyle ?? 'chibi',
  );
});

/// 带 compact / highlight 参数的 world state 构建。
WorldState buildWorldState({
  required CharacterMood mood,
  required List<DailyMomentModel> moments,
  required MoodIslandConfig islandStyle,
  required String companionStyle,
  String? companionGender,
  bool compact = false,
  String? highlightedEventId,
  GrowthWorldEngine? engine,
}) {
  final events = moments.map(GrowthEvent.fromMoment).toList();
  final profile = UserGrowthProfile.fromEvents(mood, events);
  return (engine ?? GrowthWorldEngine()).build(GrowthWorldInput(
    mood: mood,
    events: events,
    islandStyle: islandStyle,
    profile: profile,
    companionStyle: companionStyle,
    companionGender: companionGender,
    compact: compact,
    highlightedEventId: highlightedEventId,
  ));
}
