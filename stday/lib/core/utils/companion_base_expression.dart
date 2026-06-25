import '../constants/emotion_catalog.dart';
import '../models/character_mood.dart';

/// 将应用心情 id 映射到 `assets/images/companion/base/*_<expression>.png`。
String companionBaseExpressionFromMoodId(String? moodId) {
  final key = moodId?.trim();
  if (key == null || key.isEmpty) return 'calm';
  return emotionById(key).companionExpression;
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
