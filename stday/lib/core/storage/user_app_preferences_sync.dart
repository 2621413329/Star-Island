import '../../data/repositories/app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 将用户轻量偏好同步到后端 [user_profiles.app_preferences]。
class UserAppPreferencesSync {
  UserAppPreferencesSync({AppRepository? repository}) : _repository = repository;

  final AppRepository? _repository;

  static const growthIslandRulesKey = 'growth_island_rules_acknowledged';
  static const lastMoodPickKey = 'last_daily_mood_pick_date';
  static const lastStoryPromptKey = 'last_daily_story_prompt_date';

  Future<void> hydrateFromServer(Map<String, dynamic>? prefs) async {
    if (prefs == null || prefs.isEmpty) return;
    final sp = await SharedPreferences.getInstance();

    final rules = prefs[growthIslandRulesKey];
    if (rules is bool && rules) {
      await sp.setBool('growth_island_rules_acknowledged', true);
    }

    final moodDate = prefs[lastMoodPickKey];
    if (moodDate is String && moodDate.isNotEmpty) {
      await sp.setString('last_daily_mood_pick_date', moodDate);
    }

    final storyDate = prefs[lastStoryPromptKey];
    if (storyDate is String && storyDate.isNotEmpty) {
      await sp.setString('last_daily_story_prompt_date', storyDate);
    }
  }

  Future<void> markGrowthIslandRulesAcknowledged() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('growth_island_rules_acknowledged', true);
    await _patch({growthIslandRulesKey: true});
  }

  Future<void> markMoodPickedToday() async {
    final today = _todayIso();
    final sp = await SharedPreferences.getInstance();
    await sp.setString('last_daily_mood_pick_date', today);
    await _patch({lastMoodPickKey: today});
  }

  Future<void> markStoryPromptedToday() async {
    final today = _todayIso();
    final sp = await SharedPreferences.getInstance();
    await sp.setString('last_daily_story_prompt_date', today);
    await _patch({lastStoryPromptKey: today});
  }

  Future<void> _patch(Map<String, dynamic> payload) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.patchAppPreferences(payload);
    } catch (_) {
      // 离线时保留本地缓存，下次登录 hydrate 会与服务端合并。
    }
  }

  static String _todayIso() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
