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
      final lv1 = DecorConfigs.unlockedAt(1);
      expect(lv1.every((d) => d.category == DecorCategory.grass), isTrue);
      expect(lv1.length, 3);
    });

    test('unlocked count grows with level', () {
      var previous = 0;
      for (var level = 1; level <= 20; level++) {
        final count = DecorConfigs.unlockedAt(level).length;
        expect(count, greaterThanOrEqualTo(previous));
        previous = count;
      }
    });
  });
}
