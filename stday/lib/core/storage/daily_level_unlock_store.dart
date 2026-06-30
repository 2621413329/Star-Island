import '../growth/growth_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 记录用户已确认「等级解锁提示」的最高等级，避免重复弹窗。
class DailyLevelUnlockStore {
  DailyLevelUnlockStore();

  static const _keyPrefix = 'last_ack_growth_level';

  static String keyFor(String? userId) =>
      userId == null ? _keyPrefix : '${_keyPrefix}_$userId';

  Future<int> lastAckLevel(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyFor(userId)) ?? 1;
  }

  Future<void> markAckLevel(String? userId, int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyFor(userId), level.clamp(1, GrowthSystem.maxLevel));
  }
}
