import 'package:shared_preferences/shared_preferences.dart';

/// 记录用户上次在应用内选择「今日心情」的日历日（yyyy-MM-dd）。
class DailyMoodPromptStore {
  static const _key = 'last_daily_mood_pick_date';

  Future<bool> shouldPromptToday() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_key);
    final today = _todayIso();
    return last != today;
  }

  Future<void> markPickedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _todayIso());
  }

  static String _todayIso() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
