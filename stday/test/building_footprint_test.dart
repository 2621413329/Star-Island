import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/building/building_footprint.dart';
import 'package:stday/island/building/building_sprite_metrics.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/placement/island_placement.dart';
import 'package:stday/island/config/island_visual_config.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';
import 'package:stday/world/island/painted_island_asset.dart';
import 'package:stday/world/island/painted_island_pits.dart';
import 'package:stday/world/scene/building_tap_geometry.dart';

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

  test('harbor pier anchor sits at bottom center of growth island', () {
    const radius = IslandVisualConfig.baseIslandRadius;
    final anchor = IslandPlacement.harborPierAnchor(islandRadius: radius);
    expect(anchor.dx, closeTo(IslandPlacement.center.dx, 0.02));
    expect(anchor.dy, closeTo(0.659, 0.03));
    expect(anchor.dy, greaterThan(IslandPlacement.center.dy));
  });

  test('footprint uses uniform aspect ratio from sprite metrics', () {
    const radius = IslandVisualConfig.baseIslandRadius;
    final clocktower = GrowthIslandConfigs.buildingById('growth_clocktower')!;
    final observatory = GrowthIslandConfigs.buildingById('dream_observatory')!;

    final ct = BuildingFootprint.resolve(clocktower, islandRadius: radius);
    final obs = BuildingFootprint.resolve(observatory, islandRadius: radius);

    expect(
      ct.dx / ct.dy,
      closeTo(
        BuildingSpriteMetrics.contentAspectRatio('growth_clocktower'),
        0.02,
      ),
    );
    expect(
      obs.dx / obs.dy,
      closeTo(
        BuildingSpriteMetrics.contentAspectRatio('dream_observatory'),
        0.02,
      ),
    );
    expect(obs.dx / obs.dy, greaterThan(ct.dx / ct.dy));
  });

  test('detail sprites keep landmark proportions on the plate', () {
    const scene = Size(390, 844);
    final plate = PaintedIslandAsset.layoutRect(scene);
    final light = mainIslandBuildingSpriteSize(
      definitionId: 'lighthouse',
      sceneSize: scene,
      imageAspect: 1,
    );
    final house = mainIslandBuildingSpriteSize(
      definitionId: 'growth_house',
      sceneSize: scene,
      imageAspect: 1,
    );
    final plaza = mainIslandBuildingSpriteSize(
      definitionId: 'story_plaza',
      sceneSize: scene,
      imageAspect: 1.5,
    );
    final pier = mainIslandBuildingSpriteSize(
      definitionId: 'harbor_pier',
      sceneSize: scene,
      imageAspect: 1.5,
      renderScale: BuildingFootprint.pierVisualRenderBoost,
    );
    final academy = mainIslandBuildingSpriteSize(
      definitionId: 'growth_academy',
      sceneSize: scene,
      imageAspect: 1,
      renderScale: BuildingFootprint.academyVisualRenderBoost,
    );

    expect(light.height, greaterThan(house.height));
    expect(academy.height, greaterThan(house.height));
    expect(plaza.height, lessThan(house.height * 0.7));
    expect(light.width / light.height, closeTo(1, 0.05));
    expect(pier.width / pier.height, closeTo(1.5, 0.05));
    expect(light.height, lessThan(plate.height * 0.52));
    expect(academy.height, lessThan(plate.height * 0.52));
    expect(house.height, greaterThan(plate.height * 0.22));
  });

  test('Lv20 buildings use painted plate pits', () {
    final state = IslandGenerator().generate(
      GrowthWorldInput(
        mood: CharacterMood.calm,
        events: const [],
        islandStyle: const IslandStyleResolver().resolve(moodId: 'calm'),
        summary: GrowthSummary(
          growthValue: 2000,
          level: 20,
          levelTitle: 'Lv20',
          streakDays: 20,
          maxStreakDays: 20,
          nextLevel: null,
          nextLevelTitle: null,
          xpIntoLevel: 0,
          xpForNextLevel: null,
          islandStage: 20,
          unlockLabel: 'Visual Lv20',
          todayMood: 'ping_jing',
          todayWeatherLabel: GrowthSystem.moodWeatherLabel('calm'),
          isGuest: true,
        ),
        companionStyle: 'cozy',
        companionGender: 'female',
      ),
    );

    for (final building in state.buildings) {
      expect(
        PaintedIslandPits.building(building.definitionId),
        building.anchor,
        reason: building.definitionId,
      );
    }
  });
}
