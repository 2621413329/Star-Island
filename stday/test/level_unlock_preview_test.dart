import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/island_unlock_catalog.dart';
import 'package:stday/core/growth/level_unlock_preview.dart';
import 'package:stday/island/config/growth_island_configs.dart';

void main() {
  group('IslandUnlockCatalog', () {
    test('LV1 has grass decor only', () {
      final items = IslandUnlockCatalog.itemsAtLevel(1);
      expect(items.length, 6);
      expect(
          items.every((item) => item.kind == IslandUnlockKind.decor), isTrue);
      expect(items.any((item) => item.name == '起始石碑'), isFalse);
      expect(items.map((item) => item.name), contains('春日矮草'));
    });

    test('LV3 has no grass-flower-bird-cloud decor', () {
      final items = IslandUnlockCatalog.itemsAtLevel(3);
      expect(items, isEmpty);
    });

    test('LV12 includes birds', () {
      final items = IslandUnlockCatalog.itemsAtLevel(12);
      expect(items.any((item) => item.name == '岛畔飞鸟'), isTrue);
      expect(items.any((item) => item.name == '成长学院'), isFalse);
    });

    test('all level groups cover L1-L20', () {
      final groups = IslandUnlockCatalog.allLevelGroups();
      expect(groups.length, 20);
      expect(groups.any((group) => group.items.isNotEmpty), isTrue);
    });
  });

  group('LevelUnlockPreviewAssets', () {
    test('previewItemsForLevel returns all unlocks at level', () {
      final items = LevelUnlockPreviewAssets.previewItemsForLevel(1);
      expect(items.length, greaterThan(1));
    });

    for (var level = 1; level <= 20; level++) {
      test('Lv.$level preview matches nature decor catalog', () {
        final items = LevelUnlockPreviewAssets.previewItemsForLevel(level);
        final expected = IslandUnlockCatalog.itemsAtLevel(level);
        expect(items.length, expected.length);
        expect(
          items.map((item) => item.name).toList(),
          expected.map((item) => item.name).toList(),
        );
      });
    }
  });

  group('Building unlock remap', () {
    test('starter stone unlocks at L1', () {
      final building = GrowthIslandConfigs.buildingById('starter_stone');
      expect(building?.unlockLevel, 1);
    });

    test('growth house lv2 unlocks at L20', () {
      final building = GrowthIslandConfigs.buildingById('growth_house_lv2');
      expect(building?.unlockLevel, 20);
    });

    const expected = <String, int>{
      'starter_stone': 1,
      'record_shed': 5,
      'memory_mailbox': 7,
      'growth_house': 9,
      'harbor_pier': 11,
      'emotion_windchime': 13,
      'habit_flowerbed': 15,
      'quiet_tent': 17,
      'growth_house_lv2': 20,
    };

    for (final entry in expected.entries) {
      test('${entry.key} unlock level is ${entry.value}', () {
        expect(
          GrowthIslandConfigs.buildingById(entry.key)?.unlockLevel,
          entry.value,
        );
      });
    }
  });
}
