import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_placement_resolver.dart';
import 'package:stday/world/engine/world_state.dart';

void main() {
  test('large trees stay spread on typical island radii', () {
    for (final radius in [1.0, 0.82]) {
      final resolver = DecorPlacementResolver(islandRadius: radius);
      final trees = DecorConfigs.all
          .where(DecorPlacementResolver.isLargeTree)
          .toList();
      expect(trees, isNotEmpty);

      final occupied = <Rect>[];
      final positions = <String, Offset>{};
      for (final tree in trees) {
        final pos = resolver.resolveLargeTree(
          tree,
          occupied,
          randomSeed: tree.id.hashCode,
          buildings: const <BuildingSnapshot>[],
        );
        expect(
          pos,
          isNotNull,
          reason: '${tree.id} should find a shore slot at radius=$radius',
        );
        positions[tree.id] = pos!;
        occupied.add(resolver.paddedOccupancyFor(tree, pos));
      }

      final ids = positions.keys.toList();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = positions[ids[i]]!;
          final b = positions[ids[j]]!;
          expect(
            (a - b).distance,
            greaterThan(0.095),
            reason:
                '${ids[i]}@$a too close to ${ids[j]}@$b at radius=$radius',
          );
          final ra = resolver.paddedOccupancyFor(
            trees.firstWhere((t) => t.id == ids[i]),
            a,
          );
          final rb = resolver.paddedOccupancyFor(
            trees.firstWhere((t) => t.id == ids[j]),
            b,
          );
          expect(
            ra.overlaps(rb),
            isFalse,
            reason: '${ids[i]} overlaps ${ids[j]} at radius=$radius',
          );
        }
      }
    }
  });

  test('small islands skip trees instead of stacking', () {
    final resolver = const DecorPlacementResolver(islandRadius: 0.62);
    final trees = DecorConfigs.all
        .where(DecorPlacementResolver.isLargeTree)
        .toList();
    final occupied = <Rect>[];
    final positions = <Offset>[];
    for (final tree in trees) {
      final pos = resolver.resolveLargeTree(
        tree,
        occupied,
        randomSeed: tree.id.hashCode,
        buildings: const <BuildingSnapshot>[],
      );
      if (pos == null) continue;
      for (final other in positions) {
        expect((pos - other).distance, greaterThan(0.09));
      }
      positions.add(pos);
      occupied.add(resolver.paddedOccupancyFor(tree, pos));
    }
    expect(positions, isNotEmpty);
  });

  test('resolveLargeTree returns null only when shore is fully blocked', () {
    const resolver = DecorPlacementResolver(islandRadius: 0.82);
    final tree = DecorConfigs.all.firstWhere((d) => d.id == 'tree_large_01');
    final wall = <Rect>[
      const Rect.fromLTRB(0, 0, 1, 1),
    ];
    final pos = resolver.resolveLargeTree(
      tree,
      wall,
      randomSeed: 1,
      buildings: const <BuildingSnapshot>[],
    );
    expect(pos, isNull);
  });
}
