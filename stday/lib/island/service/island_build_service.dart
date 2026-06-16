import '../../core/growth/growth_system.dart';
import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';
import '../../core/weather/real_weather_snapshot.dart';
import '../../data/models/profile_models.dart';
import '../../island/config/island_visual_config.dart';
import '../../island/generator/island_generator.dart';
import '../../world/engine/growth_event.dart';
import '../../world/engine/growth_world_engine.dart';
import '../../world/engine/growth_world_input.dart';
import '../../world/engine/world_state.dart';

/// 唯一组装 [GrowthWorldInput] 并构建 [WorldState] 的入口。
class IslandBuildService {
  const IslandBuildService({
    this.islandGenerator = const IslandGenerator(),
  });

  final IslandGenerator islandGenerator;

  WorldState build({
    required GrowthWorldEngine engine,
    required GrowthSummary summary,
    required String? todayMood,
    required List<DailyMomentModel> moments,
    required MoodIslandConfig islandStyle,
    required String companionStyle,
    required String? companionGender,
    required bool compact,
    String? highlightedEventId,
    RealWeatherSnapshot? weather,
  }) {
    final mood = CharacterMood.fromString(todayMood);
    final events = moments.map(GrowthEvent.fromMoment).toList();
    final input = GrowthWorldInput(
      mood: mood,
      moodId: todayMood,
      events: events,
      summary: summary,
      islandStyle: islandStyle,
      companionStyle: companionStyle,
      companionGender: companionGender,
      compact: compact,
      highlightedEventId: highlightedEventId,
      weather: weather,
    );
    if (islandStyle.biome == IslandVisualConfig.fixedBiome) {
      return islandGenerator.generate(input);
    }
    return engine.build(input);
  }
}
