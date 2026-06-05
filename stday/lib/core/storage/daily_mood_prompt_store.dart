import 'package:shared_preferences/shared_preferences.dart';

/// 记录用户每日首次「今日心情 / 今日故事」引导的日历日（yyyy-MM-dd）。
class DailyMoodPromptStore {
  static const _moodKey = 'last_daily_mood_pick_date';
  static const _storyKey = 'last_daily_story_prompt_date';

  Future<bool> shouldPromptMoodToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_moodKey) != _todayIso();
  }

  Future<bool> shouldPromptStoryToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storyKey) != _todayIso();
  }

  Future<void> markMoodPickedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_moodKey, _todayIso());
  }

  Future<void> markStoryPromptedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storyKey, _todayIso());
  }

  /// 兼容旧调用。
  Future<bool> shouldPromptToday() => shouldPromptMoodToday();

  Future<void> markPickedToday() => markMoodPickedToday();

  static String _todayIso() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
