import '../../core/growth/growth_system.dart';
import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';
import 'growth_event.dart';

class GrowthWorldInput {
  const GrowthWorldInput({
    required this.mood,
    required this.events,
    required this.islandStyle,
    this.moodId,
    this.summary,
    this.companionStyle = 'cozy',
    this.compact = false,
    this.highlightedEventId,
    this.companionGender,
  });

  final CharacterMood mood;
  final List<GrowthEvent> events;
  final MoodIslandConfig islandStyle;
  final String? moodId;
  final GrowthSummary? summary;
  final String companionStyle;
  final bool compact;
  final String? highlightedEventId;
  final String? companionGender;

  int get protagonistLevel => summary?.level ?? 1;
}
