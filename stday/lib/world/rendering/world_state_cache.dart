import '../../core/growth/growth_system.dart';
import '../../core/models/mood_island_config.dart';
import '../../data/models/profile_models.dart';
import '../../island/service/island_build_service.dart';
import '../engine/growth_world_engine.dart';
import '../engine/world_state.dart';

/// 避免滚动/缩放时重复构建 WorldState。
class WorldStateCache {
  String? _key;
  WorldState? _state;

  WorldState resolve({
    required IslandBuildService buildService,
    required GrowthWorldEngine engine,
    required GrowthSummary summary,
    required String? todayMood,
    required List<DailyMomentModel> moments,
    required MoodIslandConfig islandStyle,
    required String companionStyle,
    required String? companionGender,
    required bool compact,
    required String? highlightedEventId,
  }) {
    final nextKey = _fingerprint(
      summary: summary,
      todayMood: todayMood,
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
    _state = buildService.build(
      engine: engine,
      summary: summary,
      todayMood: todayMood,
      moments: moments,
      islandStyle: islandStyle,
      companionStyle: companionStyle,
      companionGender: companionGender,
      compact: compact,
      highlightedEventId: highlightedEventId,
    );
    return _state!;
  }

  void clear() {
    _key = null;
    _state = null;
  }

  static String _fingerprint({
    required GrowthSummary summary,
    required String? todayMood,
    required List<DailyMomentModel> moments,
    required MoodIslandConfig islandStyle,
    required String companionStyle,
    required String? companionGender,
    required bool compact,
    required String? highlightedEventId,
  }) {
    final momentPart = moments.isEmpty
        ? 'none'
        : moments.map((m) => m.id).join(';');
    return [
      summary.level,
      summary.growthValue,
      todayMood ?? '',
      islandStyle.styleKey,
      companionStyle,
      companionGender ?? '',
      compact,
      highlightedEventId ?? '',
      momentPart,
    ].join('|');
  }
}
