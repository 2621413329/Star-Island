import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/story_island_layout.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/world/island/island_placement.dart';

void main() {
  test('center building size stays within detail visual budget', () {
    const level = StoryIslandProgressLevelModel(
      level: 10,
      thresholdDay: 100,
      buildingType: '公司总部',
      ring: 'center',
    );
    final size = StoryIslandLayout.buildingSize(level);
    expect(size.dx, lessThanOrEqualTo(0.22));
    expect(size.dy, lessThanOrEqualTo(0.22));
    expect(size.dx, greaterThanOrEqualTo(0.18));
  });

  test('detail companion stands on growth island surface', () {
    expect(
      IslandPlacement.isOnGrowthIsland(
        StoryIslandLayout.companionStandPos,
        inset: 0.86,
        islandRadius: StoryIslandLayout.detailIslandRadius,
      ),
      isTrue,
    );
    // 明显比主岛前缘站位更靠岛心，避免脚点落出岛缘。
    expect(
      StoryIslandLayout.companionStandPos.dy,
      lessThan(0.60),
    );
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
          inset: 0.72,
          islandRadius: StoryIslandLayout.detailIslandRadius,
        ),
        isTrue,
        reason: 'anchor $anchor should stay on story island',
      );
      // 不贴最深后方，降低立面画出岛缘的风险。
      expect(anchor.dy, greaterThan(IslandPlacement.center.dy - 0.06));
    }
  });
}
