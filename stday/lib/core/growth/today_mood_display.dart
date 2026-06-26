import '../constants/emotion_catalog.dart';
import '../storage/daily_mood_prompt_store.dart';
import '../../data/models/profile_models.dart';

/// 引导页/小星仔：仅当今日已选择感受时返回 profile 心情，否则默认平静。
String resolveTodayLandingMoodId({UserProfileModel? profile}) {
  if (profile != null &&
      DailyMoodPromptStore.serverSaysMoodPickedToday(profile.appPreferences)) {
    return normalizeEmotionId(profile.todayMood);
  }
  return defaultEmotionId;
}

/// `{icon} {感受名}`，供「小星仔 ☀ 平静」类文案。
String companionWeatherLabelForEmotionId(String moodId) {
  final id = normalizeEmotionId(moodId);
  final emotion = emotionById(id);
  final icon = switch (id) {
    'shi_luo' => '🌫',
    'fen_nu' => '🌧',
    'jiao_lv' || 'ya_li' || 'zi_wo_jue_cha' => '✨',
    _ => '☀',
  };
  return '$icon ${emotion.label}';
}
