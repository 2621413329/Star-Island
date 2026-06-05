import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';
import 'growth_event.dart';

class GrowthWorldInput {
  const GrowthWorldInput({
    required this.mood,
    required this.events,
    required this.islandStyle,
    required this.profile,
    this.companionStyle = 'chibi',
    this.compact = false,
    this.highlightedEventId,
    this.companionGender,
  });

  final CharacterMood mood;
  final List<GrowthEvent> events;
  final MoodIslandConfig islandStyle;
  final UserGrowthProfile profile;
  final String companionStyle;
  final bool compact;
  final String? highlightedEventId;
  final String? companionGender;
}
