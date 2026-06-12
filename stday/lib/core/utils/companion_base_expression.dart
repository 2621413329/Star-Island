import '../models/character_mood.dart';

/// 将应用心情 id 映射到 `assets/images/companion/base/*_<expression>.png`。
String companionBaseExpressionFromMoodId(String? moodId) {
  return switch (moodId?.trim().toLowerCase()) {
    'happy' => 'happy',
    'calm' => 'calm',
    'thinking' => 'thinking',
    'sad' => 'sad',
    'angry' => 'angry',
    'proud' => 'proud',
    'hurt' => 'hurt',
    'hopeful' => 'hopeful',
    'expecting' => 'expecting',
    _ => 'calm',
  };
}

String companionBaseExpressionFromMood(CharacterMood mood, {String? moodId}) {
  if (moodId != null && moodId.trim().isNotEmpty) {
    return companionBaseExpressionFromMoodId(moodId);
  }
  return switch (mood) {
    CharacterMood.happy => 'happy',
    CharacterMood.proud => 'proud',
    CharacterMood.angry => 'angry',
    CharacterMood.anxious => 'sad',
    CharacterMood.calm => 'calm',
  };
}
