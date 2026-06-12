import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/building/building_footprint.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/placement/island_placement.dart';
import 'package:stday/island/config/island_visual_config.dart';

void main() {
  test('lighthouse is tallest building at same island radius', () {
    const radius = IslandVisualConfig.baseIslandRadius;
    final lighthouse = GrowthIslandConfigs.buildingById('lighthouse')!;
    final clocktower = GrowthIslandConfigs.buildingById('growth_clocktower')!;
    final house = GrowthIslandConfigs.buildingById('growth_house')!;
    final mailbox = GrowthIslandConfigs.buildingById('memory_mailbox')!;

    final lh = BuildingFootprint.resolve(lighthouse, islandRadius: radius);
    final ct = BuildingFootprint.resolve(clocktower, islandRadius: radius);
    final hs = BuildingFootprint.resolve(house, islandRadius: radius);
    final mb = BuildingFootprint.resolve(mailbox, islandRadius: radius);

    expect(lh.dy, greaterThan(ct.dy));
    expect(lh.dy, greaterThan(hs.dy));
    expect(lh.dy, greaterThan(mb.dy));
    expect(ct.dy, greaterThan(hs.dy));
  });

  test('footprint scales with island radius', () {
    final house = GrowthIslandConfigs.buildingById('growth_house')!;
    final small = BuildingFootprint.resolve(house, islandRadius: 0.62);
    final large = BuildingFootprint.resolve(house, islandRadius: 1.20);
    expect(large.dy, greaterThan(small.dy));
    expect(large.dx, greaterThan(small.dx));
  });

  test('harbor pier anchor sits on growth island edge', () {
    const radius = IslandVisualConfig.baseIslandRadius;
    final anchor = IslandPlacement.harborPierAnchor(islandRadius: radius);
    expect(anchor.dx, closeTo(0.20, 0.03));
    expect(anchor.dy, closeTo(0.61, 0.03));
    // 左下缘锚点应落在 growth_world 轮廓上，而非旧版保守椭圆内部。
    expect(anchor.dx, lessThan(IslandPlacement.center.dx));
    expect(anchor.dy, greaterThan(IslandPlacement.center.dy));
  });
}
