import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/island_unlock_catalog.dart';
import 'package:stday/island/config/growth_island_configs.dart';

void main() {
  group('IslandUnlockCatalog display names', () {
    test('every decor and building has a display name', () {
      for (final group in IslandUnlockCatalog.allLevelGroups()) {
        for (final item in group.items) {
          expect(item.name, isNot(equals('')));
          expect(item.name.contains('_'), isFalse);
          expect(item.assetPath.startsWith('assets/images/'), isTrue);
        }
      }
    });

    test('every building asset path resolves to configured sprite', () {
      for (final building in GrowthIslandConfigs.buildings) {
        final item = IslandUnlockCatalog.itemsAtLevel(building.unlockLevel)
            .firstWhere(
          (entry) =>
              entry.kind == IslandUnlockKind.building &&
              entry.name == IslandUnlockCatalog.buildingName(building.id),
        );
        expect(item.assetPath, 'assets/images/${building.sprite}');
      }
    });
  });
}
