import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_placement_resolver.dart';
import 'package:stday/world/engine/world_state.dart';

void main() {
  test('small trees resolve on island at typical radii', () {
    for (final radius in [1.0, 0.82]) {
      final resolver = DecorPlacementResolver(islandRadius: radius);
      final unlocked = DecorConfigs.unlockedMainIslandAt(7);
      final occupied = <Rect>[];
      final sorted = [...unlocked]..sort((a, b) {
          return DecorPlacementResolver.placementPriority(a)
              .compareTo(DecorPlacementResolver.placementPriority(b));
        });

      final positions = <String, Offset>{};
      for (final config in sorted) {
        if (resolver.isSkyDecor(config)) continue;
        final pos = resolver.resolveOneOrNull(
          config,
          occupied,
          randomSeed: config.id.hashCode,
          buildings: const <BuildingSnapshot>[],
        );
        if (pos == null) continue;
        positions[config.id] = pos;
        occupied.add(resolver.paddedOccupancyFor(config, pos));
      }

      final smallTrees =
          unlocked.where((d) => d.id.startsWith('tree_small_')).toList();
      expect(smallTrees, isNotEmpty);
      for (final tree in smallTrees) {
        expect(
          positions[tree.id],
          isNotNull,
          reason: '${tree.id} should place at radius=$radius',
        );
      }
    }
  });

  test('tree placement priority puts small trees before grass', () {
    final grass = DecorConfigs.all.firstWhere((d) => d.id == 'grass_01');
    final small = DecorConfigs.all.firstWhere((d) => d.id == 'tree_small_01');
    final large = DecorConfigs.all.firstWhere((d) => d.id == 'tree_large_01');
    expect(
      DecorPlacementResolver.placementPriority(large),
      lessThan(DecorPlacementResolver.placementPriority(small)),
    );
    expect(
      DecorPlacementResolver.placementPriority(small),
      lessThan(DecorPlacementResolver.placementPriority(grass)),
    );
  });

  test('batch resolve keeps small trees at Lv7', () {
    final resolver = const DecorPlacementResolver(islandRadius: 0.82);
    final positions = resolver.resolve(DecorConfigs.unlockedMainIslandAt(7));
    for (final id in [
      'tree_small_01',
      'tree_small_02',
      'tree_small_03',
      'tree_small_04',
    ]) {
      expect(positions.containsKey(id), isTrue, reason: '$id missing');
    }
  });
}
