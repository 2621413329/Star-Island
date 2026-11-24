import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/models/mood_island_config.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/world/engine/world_state.dart';
import 'package:stday/world/preview/story_island_building_icon.dart';
import 'package:stday/world/preview/story_island_world_builder.dart';

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

  test('详情页建筑跟着 currentLevel，不看解锁时间', () {
    final island = StoryIslandModel(
      id: 'study-1',
      categoryId: 'study',
      name: '学习岛',
      currentLevel: 6,
      progressionPlan: List.generate(
        10,
        (index) => StoryIslandProgressLevelModel(
          level: index + 1,
          thresholdDay: (index + 1) * 30,
          buildingType: '建筑${index + 1}',
          ring: 'middle',
        ),
      ),
    );
    const style = MoodIslandConfig(
      moodId: 'calm',
      styleKey: 'calm',
      label: '平静',
      skyTop: Color(0xFF87CEEB),
      skyBottom: Color(0xFFE0F7FA),
      sea: Color(0xFF4FC3F7),
      sand: Color(0xFFFFE0B2),
      accent: Color(0xFF8D6E63),
      grass: Color(0xFF81C784),
      flower: Color(0xFFF48FB1),
      waveIntensity: 0.2,
      rain: false,
      wind: false,
      islandShape: 'round',
      biome: 'meadow',
      ambientParticles: 'none',
    );
    final world = StoryIslandWorldBuilder.detail(
      base: WorldState.empty(style),
      island: island,
    );
    expect(world.buildings, hasLength(1));
    expect(world.buildings.single.level, 6);
    expect(world.buildings.single.sprite, contains('study/buildings/lv06.png'));
    expect(world.buildings.single.displayName, '建筑6');
  });
}
