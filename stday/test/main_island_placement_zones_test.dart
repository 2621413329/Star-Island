import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/placement/main_island_placement_zones.dart';

void main() {
  test('protagonist exclusion blocks center foot area', () {
    const foot = MainIslandPlacementZones.protagonistFoot;
    expect(
      MainIslandPlacementZones.protagonistExclusion.contains(foot),
      isTrue,
    );
  });

  test('central void overlaps island center', () {
    expect(
      MainIslandPlacementZones.centralVoid.contains(const Offset(0.5, 0.50)),
      isTrue,
    );
  });

  test('academy rear exclusion sits above academy anchor', () {
    const anchor = MainIslandPlacementZones.academyDefaultAnchor;
    final rear = MainIslandPlacementZones.academyRearExclusion(
      academyAnchor: anchor,
    );
    expect(rear.bottom, lessThan(anchor.dy));
    expect(rear.center.dx, closeTo(anchor.dx, 0.02));
  });
}
