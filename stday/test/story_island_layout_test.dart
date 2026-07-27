import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/story_island_layout.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/world/island/island_placement.dart';

void main() {
  test('center building smaller than previous defaults', () {
    const level = StoryIslandProgressLevelModel(
      level: 10,
      thresholdDay: 100,
      buildingType: '公司总部',
      ring: 'center',
    );
    final size = StoryIslandLayout.buildingSize(level);
    expect(size.dx, lessThan(0.20));
    expect(size.dy, lessThan(0.20));
  });

  test('building anchors stay on growth island ellipse', () {
    final anchors = List.generate(
      10,
      (index) => StoryIslandLayout.buildingAnchor(index + 1),
    );
    final unique = anchors.map((o) => '${o.dx.toStringAsFixed(3)},${o.dy.toStringAsFixed(3)}').toSet();
    expect(unique.length, 10);
    expect(StoryIslandLayout.buildingAnchor(10), IslandPlacement.center);
    for (final anchor in anchors) {
      expect(
        IslandPlacement.isOnGrowthIsland(
          anchor,
          inset: 0.86,
          islandRadius: StoryIslandLayout.detailIslandRadius,
        ),
        isTrue,
        reason: 'anchor $anchor should stay on story island',
      );
    }
  });
}
