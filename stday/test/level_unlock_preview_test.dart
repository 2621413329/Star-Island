import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/island_unlock_catalog.dart';
import 'package:stday/core/growth/level_unlock_preview.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/decor/decor_config.dart';

void main() {
  group('IslandUnlockCatalog', () {
    test('LV1 includes grass decor and starter stone building', () {
      final items = IslandUnlockCatalog.itemsAtLevel(1);
      expect(items.length, 7);
      expect(items.where((item) => item.kind == IslandUnlockKind.decor).length,
          6);
      expect(items.where((item) => item.kind == IslandUnlockKind.building).length,
          1);
      expect(items.map((item) => item.name), contains('起始石碑'));
      expect(items.map((item) => item.name), contains('春日矮草'));
    });

    test('LV3 includes stones and late grass', () {
      final items = IslandUnlockCatalog.itemsAtLevel(3);
      expect(items.length, 4);
      expect(items.map((item) => item.name), containsAll(['圆润卧石', '滨海怪石']));
    });

    test('LV4 includes bushes and extra flowers', () {
      final items = IslandUnlockCatalog.itemsAtLevel(4);
      expect(items.length, 5);
      expect(items.map((item) => item.name),
          containsAll(['低垂灌木', '团簇绿篱', '丛生灌木']));
    });

    test('LV5 includes tree decor and record shed building', () {
      final items = IslandUnlockCatalog.itemsAtLevel(5);
      expect(items.length, 3);
      expect(items.map((item) => item.name),
          containsAll(['萌芽小树', '微风草叶', '记忆棚屋']));
    });

    test('LV11 includes flower field and harbor buildings', () {
      final items = IslandUnlockCatalog.itemsAtLevel(11);
      expect(items.length, 3);
      expect(items.map((item) => item.name),
          containsAll(['缤纷花田', '港口栈桥', '灯塔基座']));
    });

    test('LV12 includes bird decor and story plaza building', () {
      final items = IslandUnlockCatalog.itemsAtLevel(12);
      expect(items.length, 2);
      expect(items.map((item) => item.name),
          containsAll(['岛畔飞鸟', '故事广场']));
      expect(items.any((item) => item.name == '成长学院'), isFalse);
    });

    test('LV15 includes sky decor and emotion buildings', () {
      final items = IslandUnlockCatalog.itemsAtLevel(15);
      expect(items.length, 5);
      expect(items.map((item) => item.name), containsAll([
        '掠空轻鸟',
        '双鸟和鸣',
        '远空薄云',
        '习惯花园',
        '成长钟塔',
      ]));
    });

    test('LV20 includes life tree and academy buildings', () {
      final items = IslandUnlockCatalog.itemsAtLevel(20);
      expect(items.length, 3);
      expect(items.map((item) => item.name),
          containsAll(['生命之树', '成长小屋·扩建', '成长学院']));
    });

    test('all level groups cover L1-L20', () {
      final groups = IslandUnlockCatalog.allLevelGroups();
      expect(groups.length, 20);
      expect(groups.any((group) => group.items.isNotEmpty), isTrue);
    });

    test('every main island decor appears exactly once in catalog', () {
      final decorIds = <String>{};
      for (var level = 1; level <= 20; level++) {
        for (final item in IslandUnlockCatalog.itemsAtLevel(level)) {
          if (item.kind != IslandUnlockKind.decor) continue;
          final config = DecorConfigs.all.firstWhere(
            (decor) => IslandUnlockCatalog.decorName(decor) == item.name,
          );
          expect(decorIds.add(config.id), isTrue,
              reason: 'duplicate catalog entry for ${config.id}');
        }
      }
      final previewDecorCount = DecorConfigs.all
          .where(
            (decor) =>
                DecorConfigs.isMainIslandGroundDecor(decor) ||
                DecorConfigs.isMainIslandSkyDecor(decor),
          )
          .length;
      expect(decorIds.length, previewDecorCount);
    });

    test('every growth building appears exactly once in catalog', () {
      final buildingIds = <String>{};
      for (var level = 1; level <= 20; level++) {
        for (final item in IslandUnlockCatalog.itemsAtLevel(level)) {
          if (item.kind != IslandUnlockKind.building) continue;
          final config = GrowthIslandConfigs.buildings.firstWhere(
            (building) =>
                IslandUnlockCatalog.buildingName(building.id) == item.name,
          );
          expect(buildingIds.add(config.id), isTrue,
              reason: 'duplicate catalog entry for ${config.id}');
        }
      }
      expect(buildingIds.length, GrowthIslandConfigs.buildings.length);
    });

    test('catalog building levels match island level config unlocks', () {
      for (final levelConfig in GrowthIslandConfigs.levels) {
        final catalogBuildings = IslandUnlockCatalog.itemsAtLevel(
          levelConfig.level,
        ).where((item) => item.kind == IslandUnlockKind.building);
        expect(
          catalogBuildings.map((item) => item.name).toSet(),
          levelConfig.unlockBuildings
              .map((id) => IslandUnlockCatalog.buildingName(id))
              .toSet(),
        );
      }
    });

    test('catalog decor levels match decor config unlock levels', () {
      for (final decor in DecorConfigs.all) {
        if (!DecorConfigs.isMainIslandGroundDecor(decor) &&
            !DecorConfigs.isMainIslandSkyDecor(decor)) {
          continue;
        }
        final items = IslandUnlockCatalog.itemsAtLevel(decor.unlockLevel);
        expect(
          items.any(
            (item) =>
                item.kind == IslandUnlockKind.decor &&
                item.name == IslandUnlockCatalog.decorName(decor),
          ),
          isTrue,
          reason: '${decor.id} missing at Lv.${decor.unlockLevel}',
        );
      }
    });
  });

  group('LevelUnlockPreviewAssets', () {
    test('previewItemsForLevel returns all unlocks at level', () {
      final items = LevelUnlockPreviewAssets.previewItemsForLevel(5);
      expect(items.length, 3);
    });

    for (var level = 1; level <= 20; level++) {
      test('Lv.$level preview matches full island unlock catalog', () {
        final items = LevelUnlockPreviewAssets.previewItemsForLevel(level);
        final expected = IslandUnlockCatalog.itemsAtLevel(level);
        expect(items.length, expected.length);
        expect(
          items.map((item) => '${item.kind}:${item.name}').toList(),
          expected.map((item) => '${item.kind}:${item.name}').toList(),
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
