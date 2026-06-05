import 'package:shared_preferences/shared_preferences.dart';

/// 成长小岛守则是否已确认（仅展示一次）。
class GrowthIslandRulesStore {
  static const _key = 'growth_island_rules_acknowledged';

  Future<bool> isAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> acknowledge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
