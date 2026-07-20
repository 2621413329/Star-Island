import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';

void main() {
  group('DecorConfigs', () {
    test('all decor ids are unique', () {
      final ids = DecorConfigs.all.map((d) => d.id).toList();
      expect(ids.length, ids.toSet().length);
    });

    test('unlock levels are within 1-20', () {
      for (final decor in DecorConfigs.all) {
        expect(decor.unlockLevel, inInclusiveRange(1, 20));
      }
    });

    test('animated decor has animationType', () {
      for (final decor in DecorConfigs.all.where((d) => d.animated)) {
        expect(decor.animationType, isNotNull);
        expect(decor.animationType, isNotEmpty);
      }
    });

    test('layer priorities follow category order', () {
      expect(DecorCategory.grass.layerPriority,
          lessThan(DecorCategory.flower.layerPriority));
      expect(DecorCategory.flower.layerPriority,
          lessThan(DecorCategory.stone.layerPriority));
      expect(DecorCategory.tree.layerPriority,
          lessThan(DecorCategory.bird.layerPriority));
      expect(DecorCategory.bird.layerPriority,
          lessThan(DecorCategory.cloud.layerPriority));
    });

    test('LV1 unlocks only grass', () {
      final lv1 = DecorConfigs.unlockedNatureAt(1);
      expect(lv1.every((d) => d.category == DecorCategory.grass), isTrue);
      expect(lv1.length, 6);
    });

    test('unlocked nature count grows with level', () {
      var previous = 0;
      for (var level = 1; level <= 20; level++) {
        final count = DecorConfigs.unlockedNatureAt(level).length;
        expect(count, greaterThanOrEqualTo(previous));
        previous = count;
      }
    });

    test('main island decor includes trees from Lv5', () {
      final lv5 = DecorConfigs.unlockedMainIslandAt(5);
      expect(lv5.any((d) => d.id == 'tree_small_01'), isTrue);
      expect(lv5.any((d) => d.id == 'stone_01'), isTrue);
    });

    test('main island hides pond/hotspring but keeps stone', () {
      final lv14 = DecorConfigs.unlockedMainIslandAt(14);
      expect(lv14.any((d) => d.id == 'stone_01'), isTrue);
      expect(lv14.any((d) => d.id == 'pond_01'), isFalse);
    });

    test('large trees use grass_sway animation', () {
      for (final id in [
        'tree_large_01',
        'tree_large_01b',
        'tree_large_01c',
        'tree_large_02',
        'tree_large_02b',
        'tree_large_02c',
        'life_tree_01',
      ]) {
        final tree = DecorConfigs.all.firstWhere((d) => d.id == id);
        expect(tree.animated, isTrue);
        expect(tree.animationType, 'grass_sway');
      }
    });
  });
}
