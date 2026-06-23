import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_scale_resolver.dart';
import 'package:stday/island/decor/island_growth_scale_service.dart';

void main() {
  group('IslandGrowthScaleService', () {
    const service = IslandGrowthScaleService();

    test('anchor levels match spec', () {
      expect(service.getLevelScale(1), closeTo(0.8, 0.001));
      expect(service.getLevelScale(5), closeTo(1.0, 0.001));
      expect(service.getLevelScale(10), closeTo(1.15, 0.001));
      expect(service.getLevelScale(15), closeTo(1.30, 0.001));
      expect(service.getLevelScale(20), closeTo(1.45, 0.001));
    });

    test('curve is monotonic between anchors', () {
      var previous = service.getLevelScale(1);
      for (var level = 2; level <= 20; level++) {
        final next = service.getLevelScale(level);
        expect(next, greaterThanOrEqualTo(previous));
        previous = next;
      }
    });

    test('mid-level interpolation is smooth', () {
      final lv3 = service.getLevelScale(3);
      expect(lv3, greaterThan(0.8));
      expect(lv3, lessThan(1.0));

      final lv12 = service.getLevelScale(12);
      expect(lv12, greaterThan(1.15));
      expect(lv12, lessThan(1.30));
    });

    test('clamps outside 1-20', () {
      expect(service.getLevelScale(0), closeTo(0.8, 0.001));
      expect(service.getLevelScale(99), closeTo(1.45, 0.001));
    });
  });

  group('DecorScaleResolver', () {
    const resolver = DecorScaleResolver();

    test('category growth weights match spec', () {
      expect(DecorCategory.grass.growthWeight, 0.3);
      expect(DecorCategory.flower.growthWeight, 0.4);
      expect(DecorCategory.stone.growthWeight, 0.2);
      expect(DecorCategory.bush.growthWeight, 0.6);
      expect(DecorCategory.tree.growthWeight, 1.0);
      expect(DecorCategory.pond.growthWeight, 0.5);
      expect(DecorCategory.cloud.growthWeight, 0.5);
      expect(DecorCategory.bird.growthWeight, 0.3);
      expect(DecorCategory.butterfly.growthWeight, 0.3);
      expect(DecorCategory.firefly.growthWeight, 0.2);
      expect(DecorCategory.special.growthWeight, 0.8);
    });

    test('low level fill boost enlarges grass at Lv1', () {
      final boost = resolver.lowLevelFillBoost(DecorCategory.grass, 1);
      expect(boost, greaterThan(1.4));
      expect(resolver.lowLevelFillBoost(DecorCategory.grass, 8), 1.0);
      expect(resolver.lowLevelFillBoost(DecorCategory.tree, 1), 1.0);
    });

    test('growth scale formula at Lv1 and Lv20', () {
      final grassLv1 = resolver.growthScaleFor(DecorCategory.grass, 1);
      expect(grassLv1, closeTo(0.94, 0.001));

      final treeLv20 = resolver.growthScaleFor(DecorCategory.tree, 20);
      expect(treeLv20, closeTo(1.45, 0.001));
    });

    test('random scale stays within 0.92-1.08', () {
      for (final decor in DecorConfigs.all) {
        final value = DecorScaleResolver.randomScaleFor(decor.id);
        expect(value, inInclusiveRange(0.92, 1.08));
      }
    });

    test('random scale is stable per decor id', () {
      expect(
        DecorScaleResolver.randomScaleFor('grass_01'),
        DecorScaleResolver.randomScaleFor('grass_01'),
      );
    });

    test('sprite fill ratio compensates 800x800 canvas padding', () {
      const grass = DecorConfig(
        id: 'grass_01',
        image: 'grass_01.png',
        category: DecorCategory.grass,
        unlockLevel: 1,
        x: 0.3,
        y: 0.6,
        scale: 0.9,
        randomScale: 1.0,
      );
      const tree = DecorConfig(
        id: 'tree_small_01',
        image: 'tree_small_01.png',
        category: DecorCategory.tree,
        unlockLevel: 5,
        x: 0.4,
        y: 0.5,
        scale: 0.72,
        randomScale: 1.0,
      );

      final grassFill = DecorScaleResolver.spriteFillRatioFor('grass_01');
      expect(grassFill, lessThan(1.0));

      final grassScale = resolver.finalScale(grass, 1);
      final treeScale = resolver.finalScale(tree, 5);
      expect(grassScale, greaterThan(grass.scale));
      expect(treeScale, closeTo(tree.scale, 0.001));
    });

    test('visible height follows category base at unlock level', () {
      const viewportHeight = 800.0;
      final grass = DecorConfigs.all.firstWhere((d) => d.id == 'grass_01');
      final instance = grass.copyWith(randomScale: 1.0);
      final size = resolver.computeSize(
        config: instance,
        userLevel: 1,
        spriteSrcSize: const Vector2(800, 800),
        viewportHeight: viewportHeight,
      );
      final fill = DecorScaleResolver.spriteFillRatioFor(grass.id);
      final boost = resolver.lowLevelFillBoost(grass.category, 1);
      final growth = resolver.growthScaleFor(grass.category, 1);
      final expectedVisible =
          DecorScaleResolver.baseHeightFor(grass.category) *
              grass.scale *
              growth *
              boost;
      expect(size.y * fill, closeTo(expectedVisible, 0.5));
    });

    test('final scale grows with level for trees', () {
      final config = DecorConfigs.all.firstWhere((d) => d.id == 'life_tree_01');
      final instance = config.copyWith(
        randomScale: DecorScaleResolver.randomScaleFor(config.id),
      );
      final lv1 = resolver.finalScale(instance, 1);
      final lv20 = resolver.finalScale(instance, 20);
      expect(lv20, greaterThan(lv1));
    });

    test('decor height respects 25% viewport cap', () {
      final config = DecorConfigs.all.firstWhere((d) => d.id == 'life_tree_01');
      final instance = config.copyWith(
        randomScale: DecorScaleResolver.randomScaleFor(config.id),
      );
      const viewportHeight = 400.0;
      final size = resolver.computeSize(
        config: instance,
        userLevel: 20,
        spriteSrcSize: const Vector2(100, 200),
        viewportHeight: viewportHeight,
      );
      expect(size.y, lessThanOrEqualTo(viewportHeight * 0.25 + 0.01));
    });

    test('building height cap scales down oversized landmarks', () {
      const viewportHeight = 500.0;
      const rawHeight = 200.0;
      final cap = DecorScaleResolver.clampBuildingScale(
        height: rawHeight,
        viewportHeight: viewportHeight,
      );
      expect(rawHeight * cap, lessThanOrEqualTo(viewportHeight * 0.25));
      expect(cap, lessThan(1.0));
    });
  });
}
