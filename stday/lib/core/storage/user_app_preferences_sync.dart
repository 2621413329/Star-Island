import 'daily_mood_prompt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UserAppPreferencesPatcher {
  Future<void> patchAppPreferences(Map<String, dynamic> payload);
}

/// 将用户轻量偏好同步到后端 [user_profiles.app_preferences]。
class UserAppPreferencesSync {
  UserAppPreferencesSync({UserAppPreferencesPatcher? patcher})
      : _patcher = patcher;

  final UserAppPreferencesPatcher? _patcher;

  static const growthIslandRulesKey = 'growth_island_rules_acknowledged';
  static const lastMoodPickKey = 'last_daily_mood_pick_date';
  static const lastStoryPromptKey = 'last_daily_story_prompt_date';

  Future<void> hydrateFromServer(
    Map<String, dynamic>? prefs, {
    String? userId,
  }) async {
    if (prefs == null || prefs.isEmpty) return;
    final sp = await SharedPreferences.getInstance();

    final rules = prefs[growthIslandRulesKey];
    if (rules is bool && rules) {
      await sp.setBool('growth_island_rules_acknowledged', true);
    }

    final moodDate = prefs[lastMoodPickKey];
    if (moodDate is String && moodDate.isNotEmpty) {
      await sp.setString(DailyMoodPromptStore.moodKeyFor(userId), moodDate);
    }

    final storyDate = prefs[lastStoryPromptKey];
    if (storyDate is String && storyDate.isNotEmpty) {
      await sp.setString(DailyMoodPromptStore.storyKeyFor(userId), storyDate);
    }
  }

  Future<void> markGrowthIslandRulesAcknowledged() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('growth_island_rules_acknowledged', true);
    await _patch({growthIslandRulesKey: true});
  }

  Future<void> markMoodPickedToday({String? userId}) async {
    final today = DailyMoodPromptStore.todayIso();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(DailyMoodPromptStore.moodKeyFor(userId), today);
    await _patch({lastMoodPickKey: today});
  }

  Future<void> markStoryPromptedToday({String? userId}) async {
    final today = DailyMoodPromptStore.todayIso();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(DailyMoodPromptStore.storyKeyFor(userId), today);
    await _patch({lastStoryPromptKey: today});
  }

  Future<void> _patch(Map<String, dynamic> payload) async {
    final patcher = _patcher;
    if (patcher == null) return;
    try {
      await patcher.patchAppPreferences(payload);
    } catch (_) {
      // 离线时保留本地缓存，下次登录 hydrate 会与服务端合并。
    }
  }
}
