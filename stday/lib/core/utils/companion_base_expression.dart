import '../constants/companion_base_asset.dart';
import '../constants/emotion_catalog.dart';
import '../models/character_mood.dart';
import '../../data/models/profile_models.dart';

/// 将心情 id 映射到 `assets/images/companion/base/{gender}_{拼音 id}.png`。
String companionBaseExpressionFromMoodId(String? moodId) {
  return companionBaseAssetId(moodId);
}

String companionBaseExpressionFromMood(CharacterMood mood, {String? moodId}) {
  if (moodId != null && moodId.trim().isNotEmpty) {
    return companionBaseExpressionFromMoodId(moodId);
  }
  return switch (mood) {
    CharacterMood.happy => 'kai_xin',
    CharacterMood.proud => 'xing_fen',
    CharacterMood.angry => 'fen_nu',
    CharacterMood.anxious => 'shi_luo',
    CharacterMood.calm => 'ping_jing',
  };
}

String companionBaseExpressionForMoment(DailyMomentModel moment) {
  return companionBaseAssetId(effectiveEmotionIdForMoment(moment));
}
