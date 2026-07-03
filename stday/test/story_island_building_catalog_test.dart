import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/story_island_building_catalog.dart';

void main() {
  test('each category has 10 buildings', () {
    expect(StoryIslandBuildingCatalog.buildingsByCategory.length, 11);
    for (final entry in StoryIslandBuildingCatalog.buildingsByCategory.entries) {
      expect(entry.value.length, 10, reason: entry.key);
    }
  });

  test('work island Lv1 and Lv10 names', () {
    expect(StoryIslandBuildingCatalog.buildingName('work', 1), '工作角');
    expect(StoryIslandBuildingCatalog.buildingName('work', 10), '公司总部');
  });

  test('asset path format', () {
    expect(
      StoryIslandBuildingCatalog.assetPath('life', 3),
      'islands/life/buildings/lv03.png',
    );
  });
}
