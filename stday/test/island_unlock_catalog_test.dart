import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/island_unlock_catalog.dart';

void main() {
  group('IslandUnlockCatalog decor names', () {
    test('every decor has a display name', () {
      for (final group in IslandUnlockCatalog.allLevelGroups()) {
        for (final item in group.items) {
          if (item.kind == IslandUnlockKind.decor) {
            expect(item.name, isNot(equals('')));
            expect(item.name.contains('_'), isFalse);
          }
        }
      }
    });
  });
}
