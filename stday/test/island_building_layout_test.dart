import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/placement/island_building_layout.dart';
import 'package:stday/island/service/building_resolver.dart';

void main() {
  test('starter stone anchor is on lower-left island area', () {
    expect(IslandBuildingLayout.starterStoneAnchor.dx, lessThan(0.35));
    expect(IslandBuildingLayout.starterStoneAnchor.dy, greaterThan(0.58));
  });

  test('key buildings use fixed regional anchors', () {
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('library_seed')!,
        islandRadius: 1.0,
      ).dx,
      lessThan(0.35),
    );
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('lighthouse')!,
        islandRadius: 1.0,
      ).dx,
      greaterThan(0.70),
    );
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('growth_academy')!,
        islandRadius: 1.0,
      ).dy,
      lessThan(0.45),
    );
  });

  test('resolved buildings do not overlap footprints', () {
    const resolver = BuildingResolver();
    final snapshots = resolver.resolveConfigured(
      configs: GrowthIslandConfigs.buildings,
      islandRadius: 1.0,
    );

    for (var i = 0; i < snapshots.length; i++) {
      for (var j = i + 1; j < snapshots.length; j++) {
        final a = snapshots[i];
        final b = snapshots[j];
        final rectA =
            IslandBuildingLayout.occupancyRect(a.anchor, a.size, margin: 0);
        final rectB =
            IslandBuildingLayout.occupancyRect(b.anchor, b.size, margin: 0);
        expect(
          rectA.overlaps(rectB),
          isFalse,
          reason: '${a.definitionId} overlaps ${b.definitionId}',
        );
      }
    }
  });
}
