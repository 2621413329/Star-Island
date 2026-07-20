import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_placement_resolver.dart';
import 'package:stday/world/engine/world_state.dart';

void main() {
  test('large trees resolve without stacking or null-fallback crash', () {
    const resolver = DecorPlacementResolver();
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
      expect(pos, isNotNull, reason: '${tree.id} should find a shore slot');
      positions[tree.id] = pos!;
      occupied.add(resolver.paddedOccupancyFor(tree, pos));
    }

    final ids = positions.keys.toList();
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final a = resolver.paddedOccupancyFor(
          trees.firstWhere((t) => t.id == ids[i]),
          positions[ids[i]]!,
        );
        final b = resolver.paddedOccupancyFor(
          trees.firstWhere((t) => t.id == ids[j]),
          positions[ids[j]]!,
        );
        expect(
          a.overlaps(b),
          isFalse,
          reason: '${ids[i]} overlaps ${ids[j]}',
        );
      }
    }
  });

  test('resolveLargeTree returns null only when shore is fully blocked', () {
    const resolver = DecorPlacementResolver();
    final tree = DecorConfigs.all.firstWhere((d) => d.id == 'tree_large_01');
    // 用超大占用盖住整岛，逼出 null（证明不会硬回退）。
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
