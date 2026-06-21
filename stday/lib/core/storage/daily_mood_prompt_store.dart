import 'package:shared_preferences/shared_preferences.dart';

import 'user_app_preferences_sync.dart';

/// 记录每位用户每日首次「今日心情 / 今日日常」引导的日历日（yyyy-MM-dd）。
class DailyMoodPromptStore {
  DailyMoodPromptStore({UserAppPreferencesSync? sync, this.userId}) : _sync = sync;

  final UserAppPreferencesSync? _sync;
  final String? userId;

  static const _moodKeyPrefix = 'last_daily_mood_pick_date';
  static const _storyKeyPrefix = 'last_daily_story_prompt_date';

  static String moodKeyFor(String? userId) =>
      userId == null ? _moodKeyPrefix : '${_moodKeyPrefix}_$userId';

  static String storyKeyFor(String? userId) =>
      userId == null ? _storyKeyPrefix : '${_storyKeyPrefix}_$userId';

  static String todayIso() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static bool serverSaysMoodPickedToday(Map<String, dynamic> appPreferences) {
    final date = appPreferences[UserAppPreferencesSync.lastMoodPickKey];
    return date is String && date == todayIso();
  }

  static bool serverSaysStoryPromptedToday(Map<String, dynamic> appPreferences) {
    final date = appPreferences[UserAppPreferencesSync.lastStoryPromptKey];
    return date is String && date == todayIso();
  }

  /// 当前用户今日是否仍需选择心情。
  static Future<bool> needsMoodPrompt({
    required Map<String, dynamic> appPreferences,
    required String? userId,
    UserAppPreferencesSync? sync,
  }) async {
    if (serverSaysMoodPickedToday(appPreferences)) return false;
    final store = DailyMoodPromptStore(sync: sync, userId: userId);
    return store.shouldPromptMoodToday();
  }

  /// 当前用户今日是否仍需日常引导。
  static Future<bool> needsStoryPrompt({
    required Map<String, dynamic> appPreferences,
    required String? userId,
    UserAppPreferencesSync? sync,
  }) async {
    if (serverSaysStoryPromptedToday(appPreferences)) return false;
    final store = DailyMoodPromptStore(sync: sync, userId: userId);
    return store.shouldPromptStoryToday();
  }

  Future<bool> shouldPromptMoodToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(moodKeyFor(userId)) != todayIso();
  }

  Future<bool> shouldPromptStoryToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storyKeyFor(userId)) != todayIso();
  }

  Future<void> markMoodPickedToday() async {
    if (_sync != null) {
      await _sync.markMoodPickedToday(userId: userId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(moodKeyFor(userId), todayIso());
  }

  Future<void> markStoryPromptedToday() async {
    if (_sync != null) {
      await _sync.markStoryPromptedToday(userId: userId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storyKeyFor(userId), todayIso());
  }

  /// 兼容旧调用。
  Future<bool> shouldPromptToday() => shouldPromptMoodToday();

  Future<void> markPickedToday() => markMoodPickedToday();
}
