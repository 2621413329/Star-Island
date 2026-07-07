import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/world/preview/story_island_building_icon.dart';

StoryIslandModel _island({required int currentLevel}) {
  return StoryIslandModel(
    id: 'test',
    categoryId: 'study',
    name: '学习岛',
    currentLevel: currentLevel,
    progressionPlan: List.generate(
      10,
      (index) => StoryIslandProgressLevelModel(
        level: index + 1,
        thresholdDay: (index + 1) * 30,
        buildingType: '建筑${index + 1}',
        ring: 'outer',
        unlockedAt: currentLevel >= index + 1
            ? DateTime(2026, 1, index + 1)
            : null,
      ),
    ),
  );
}

void main() {
  group('StoryIslandBuildingIcon.worldMapPreviewBuildingLevel', () {
    test('Lv0 展示 Lv1 建筑', () {
      expect(
        StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(_island(currentLevel: 0)),
        1,
      );
    });

    test('Lv1 不新增建筑，仍展示 Lv1', () {
      expect(
        StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(_island(currentLevel: 1)),
        1,
      );
    });

    test('Lv2 起展示对应等级建筑', () {
      expect(
        StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(_island(currentLevel: 2)),
        2,
      );
      expect(
        StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(_island(currentLevel: 5)),
        5,
      );
    });

    test('worldMapPreviewAsset 路径与等级一致', () {
      final asset = StoryIslandBuildingIcon.worldMapPreviewAsset(
        categoryId: 'study',
        island: _island(currentLevel: 3),
      );
      expect(asset, contains('study/buildings/lv03.png'));
    });
  });
}
