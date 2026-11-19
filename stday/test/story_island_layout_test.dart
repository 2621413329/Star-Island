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

  test('building anchors share one pit that walks toward the clearing', () {
    final anchors = List.generate(
      10,
      (index) => StoryIslandLayout.buildingAnchor(index + 1),
    );
    final unique = anchors
        .map((o) => '${o.dx.toStringAsFixed(3)},${o.dy.toStringAsFixed(3)}')
        .toSet();
    expect(unique.length, 10);
    final first = StoryIslandLayout.buildingAnchor(1);
    final last = StoryIslandLayout.buildingAnchor(10);
    expect(last.dx, greaterThan(first.dx));
    expect(last.dy, lessThan(first.dy));
    for (final anchor in anchors) {
      expect(anchor.dx, inInclusiveRange(0.28, 0.52));
      expect(anchor.dy, inInclusiveRange(0.46, 0.64));
    }
  });
}
