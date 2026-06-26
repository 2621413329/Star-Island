import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/emotion_catalog.dart';
import 'package:stday/core/growth/today_mood_display.dart';
import 'package:stday/core/storage/user_app_preferences_sync.dart';
import 'package:stday/data/models/profile_models.dart';

UserProfileModel _profile({
  String? todayMood,
  Map<String, dynamic> appPreferences = const {},
}) {
  return UserProfileModel(
    userId: 'u1',
    onboardingCompleted: true,
    todayMood: todayMood,
    appPreferences: appPreferences,
  );
}

void main() {
  test('未选今日感受时默认平静', () {
    final id = resolveTodayLandingMoodId(
      profile: _profile(todayMood: 'kai_xin'),
    );
    expect(id, defaultEmotionId);
  });

  test('今日已选感受时使用 profile 心情', () {
    final today = DailyMoodPromptStore.todayIso();
    final id = resolveTodayLandingMoodId(
      profile: _profile(
        todayMood: 'kai_xin',
        appPreferences: {UserAppPreferencesSync.lastMoodPickKey: today},
      ),
    );
    expect(id, 'kai_xin');
  });

  test('感受文案使用 emotion 标签', () {
    expect(
      companionWeatherLabelForEmotionId('ping_jing'),
      '☀ 平静',
    );
  });
}
