import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/story_island_layout.dart';
import 'package:stday/data/models/story_island_models.dart';

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

  test('building anchors spread across island rings', () {
    final anchors = List.generate(
      10,
      (index) => StoryIslandLayout.buildingAnchor(index + 1),
    );
    final unique = anchors.map((o) => '${o.dx},${o.dy}').toSet();
    expect(unique.length, 10);
    expect(StoryIslandLayout.buildingAnchor(10), const Offset(0.50, 0.54));
  });
}
