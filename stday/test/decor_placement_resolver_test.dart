import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_placement_resolver.dart';

void main() {
  test('DecorPlacementResolver moves decor out of protagonist rear zone', () {
    const resolver = DecorPlacementResolver();
    final positions = resolver.resolve(DecorConfigs.unlockedAt(5));

    for (final entry in positions.entries) {
      final p = entry.value;
      expect(
        DecorPlacementResolver.protagonistRearZone.contains(p),
        isFalse,
        reason: '${entry.key} should not sit behind protagonist at $p',
      );
    }

    final tree = positions['tree_small_01'];
    expect(tree, isNotNull);
    expect((tree!.dx - 0.5).abs(), greaterThan(0.08));
  });

  test('DecorPlacementResolver keeps ground decor from overlapping', () {
    const resolver = DecorPlacementResolver();
    final configs = DecorConfigs.unlockedAt(12);
    final positions = resolver.resolve(configs);

    Rect occupancy(String id) {
      final config = configs.firstWhere((c) => c.id == id);
      final pos = positions[id]!;
      final scaleBoost = (config.scale * 1.12).clamp(0.55, 1.85);
      final w = switch (config.category) {
        DecorCategory.tree => 0.12,
        DecorCategory.bush => 0.10,
        DecorCategory.stone => 0.09,
        DecorCategory.flower => 0.08,
        DecorCategory.pond => 0.14,
        DecorCategory.special => 0.08,
        _ => 0.07,
      } *
          scaleBoost;
      final h = w * 1.15;
      return Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - h * 0.35),
        width: w,
        height: h,
      ).inflate(DecorPlacementResolver.decorGap);
    }

    final groundIds = positions.keys.where((id) {
      final config = configs.firstWhere((c) => c.id == id);
      return config.category != DecorCategory.cloud &&
          config.category != DecorCategory.bird &&
          config.category != DecorCategory.butterfly &&
          config.category != DecorCategory.firefly;
    }).toList();

    for (var i = 0; i < groundIds.length; i++) {
      for (var j = i + 1; j < groundIds.length; j++) {
        final a = occupancy(groundIds[i]);
        final b = occupancy(groundIds[j]);
        expect(
          a.overlaps(b),
          isFalse,
          reason: '${groundIds[i]} at $a overlaps ${groundIds[j]} at $b',
        );
      }
    }
  });
}
