import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_placement_resolver.dart';
import 'package:stday/island/placement/island_building_layout.dart';
import 'package:stday/island/placement/large_tree_shore_parcels.dart';
import 'package:stday/island/placement/main_island_placement_zones.dart';

void main() {
  test('defines seven non-empty shore parcels', () {
    expect(LargeTreeShoreParcels.preferredSlotByTreeId, hasLength(7));
    expect(MainIslandPlacementZones.largeTreeShoreParcels, hasLength(7));
    for (final parcel in MainIslandPlacementZones.largeTreeShoreParcels) {
      expect(parcel.width, greaterThan(0));
      expect(parcel.height, greaterThan(0));
    }
  });

  test('grass and flowers avoid large tree shore parcels', () {
    const resolver = DecorPlacementResolver(islandRadius: 0.82);
    for (final category in [DecorCategory.grass, DecorCategory.flower]) {
      for (final slot in LargeTreeShoreParcels.preferredSlotByTreeId.values) {
        final decor = DecorConfig(
          id: 'test_${category.name}_${slot.dx}_${slot.dy}',
          image: 'grass_01.png',
          category: category,
          unlockLevel: 1,
          x: slot.dx,
          y: slot.dy,
          scale: 1.0,
        );
        final pos = resolver.resolveOne(
          decor,
          const [],
          randomSeed: decor.id.hashCode,
        );
        final occ = resolver.paddedOccupancyFor(decor, pos);
        expect(
          LargeTreeShoreParcels.overlapsAnyParcel(occ),
          isFalse,
          reason: '${decor.id} at $pos should leave parcel at $slot',
        );
      }
    }
  });

  test('large trees may occupy their shore parcels', () {
    const resolver = DecorPlacementResolver(islandRadius: 0.82);
    final occupied = <Rect>[];
    for (final tree
        in DecorConfigs.all.where(DecorPlacementResolver.isLargeTree)) {
      final pos = resolver.resolveLargeTree(
        tree,
        occupied,
        randomSeed: tree.id.hashCode,
      );
      expect(pos, isNotNull, reason: tree.id);
      occupied.add(resolver.paddedOccupancyFor(tree, pos!));
    }
  });

  test('building candidate inside parcel is rejected', () {
    final slot = LargeTreeShoreParcels.preferredSlotByTreeId['tree_large_01']!;
    final config = GrowthIslandConfigs.buildingById('habit_flowerbed')!;
    expect(
      IslandBuildingLayout.isZoneValidForBuilding(
        config: config,
        anchor: slot,
        footprint: config.size,
        academyAnchor: MainIslandPlacementZones.academyDefaultAnchor,
      ),
      isFalse,
    );
  });
}
