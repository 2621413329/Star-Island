import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';
import '../../data/models/profile_models.dart';
import '../engine/growth_event.dart';
import '../engine/growth_world_engine.dart';
import '../engine/growth_world_input.dart';
import '../engine/world_state.dart';

/// 避免滚动/缩放时重复构建 WorldState。
class WorldStateCache {
  String? _key;
  WorldState? _state;

  WorldState resolve({
    required GrowthWorldEngine engine,
    required CharacterMood mood,
    required List<DailyMomentModel> moments,
    required MoodIslandConfig islandStyle,
    required String companionStyle,
    required String? companionGender,
    required bool compact,
    required String? highlightedEventId,
  }) {
    final nextKey = _fingerprint(
      mood: mood,
      moments: moments,
      islandStyle: islandStyle,
      companionStyle: companionStyle,
      companionGender: companionGender,
      compact: compact,
      highlightedEventId: highlightedEventId,
    );
    if (_state != null && _key == nextKey) {
      return _state!;
    }
    _key = nextKey;
    final events = moments.map(GrowthEvent.fromMoment).toList();
    final profile = UserGrowthProfile.fromEvents(mood, events);
    _state = engine.build(
      GrowthWorldInput(
        mood: mood,
        events: events,
        islandStyle: islandStyle,
        profile: profile,
        companionStyle: companionStyle,
        companionGender: companionGender,
        compact: compact,
        highlightedEventId: highlightedEventId,
      ),
    );
    return _state!;
  }

  void clear() {
    _key = null;
    _state = null;
  }

  static String _fingerprint({
    required CharacterMood mood,
    required List<DailyMomentModel> moments,
    required MoodIslandConfig islandStyle,
    required String companionStyle,
    required String? companionGender,
    required bool compact,
    required String? highlightedEventId,
  }) {
    final momentPart = moments.isEmpty
        ? 'none'
        : moments
            .map(
              (m) =>
                  '${m.id}:${m.emotionTag}:${m.eventTags.join(".")}:${m.companionScene}:${m.visualPayload["prop"]}:${m.visualPayload["expression"]}',
            )
            .join(';');
    return [
      mood.name,
      islandStyle.styleKey,
      islandStyle.islandShape,
      islandStyle.biome,
      companionStyle,
      companionGender ?? '',
      compact,
      highlightedEventId ?? '',
      momentPart,
    ].join('|');
  }
}
