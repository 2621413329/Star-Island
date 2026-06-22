import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stday/core/growth/level_unlock_celebration.dart';
import 'package:stday/core/storage/daily_level_unlock_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyLevelUnlockStore', () {
    test('defaults to level 1 when never acknowledged', () async {
      final store = DailyLevelUnlockStore();
      expect(await store.lastAckLevel('user_a'), 1);
    });

    test('persists acknowledged level per user', () async {
      final store = DailyLevelUnlockStore();
      await store.markAckLevel('user_a', 8);
      expect(await store.lastAckLevel('user_a'), 8);
      expect(await store.lastAckLevel('user_b'), 1);
    });
  });

  group('level unlock celebration helpers', () {
    test('collectNewUnlockItems merges multi-level unlocks', () {
      final items = collectNewUnlockItems(fromLevel: 2, toLevel: 3);
      expect(items.length, greaterThan(2));
      expect(items.any((item) => item.name == '野趣小花'), isTrue);
      expect(items.any((item) => item.name == '起始石碑'), isTrue);
    });

    test('levelUnlockRangeSummary truncates long lists', () {
      final text = levelUnlockRangeSummary(fromLevel: 14, toLevel: 15);
      expect(text, contains('等'));
    });
  });
}
