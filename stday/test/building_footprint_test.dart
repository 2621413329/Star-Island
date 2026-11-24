import 'dart:ui';

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
    expect(light.height, lessThan(plate.height * 0.36));
    expect(academy.height, lessThan(plate.height * 0.36));
    expect(house.height, greaterThan(plate.height * 0.12));
  });

  test('landmarks, shore trees, and the companion keep separate feet', () {
    const landmarks = [
      'dream_observatory',
      'growth_clocktower',
      'growth_academy',
      'lighthouse',
      'memory_gallery',
      'growth_tree',
      'library_seed',
      'growth_house',
    ];
    const trees = [
      'tree_small_01',
      'tree_small_02',
      'tree_small_03',
      'tree_small_04',
      'tree_large_01',
      'tree_large_01b',
      'tree_large_01c',
      'tree_large_02',
      'tree_large_02b',
      'tree_large_02c',
      'life_tree_01',
    ];
    final named = <String, Offset>{
      for (final id in landmarks) id: PaintedIslandPits.building(id)!,
      for (final id in trees) id: PaintedIslandPits.decor(id),
      'character': PaintedIslandPits.character,
    };
    final ids = named.keys.toList();
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        expect(
          (named[ids[i]]! - named[ids[j]]!).distance,
          greaterThan(0.10),
          reason: '${ids[i]} overlaps ${ids[j]}',
        );
      }
    }
    expect(
      PaintedIslandPits.building('lighthouse'),
      PaintedIslandPits.building('lighthouse_base'),
    );
    expect(
      PaintedIslandPits.building('growth_house'),
      PaintedIslandPits.building('growth_house_lv2'),
    );
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

  test('detail tap rect sits on the opaque sprite, not the canvas padding', () {
    const scene = Size(390, 844);
    const plateScale = PaintedIslandAsset.detailScale;

    void expectFeet(String id, Offset pit) {
      final foot = PaintedIslandAsset.plateToCanvas(pit, scene, scale: plateScale);
      final tap = mainIslandBuildingTapRect(
        definitionId: id,
        plateAnchor: pit,
        sceneSize: scene,
        plateScale: plateScale,
      );
      expect(tap.bottom, closeTo(foot.dy, 0.6), reason: id);
      expect(tap.center.dx, closeTo(foot.dx, 1.5), reason: id);
      expect(tap.contains(Offset(foot.dx, foot.dy - 2)), isTrue, reason: id);
      expect(tap.contains(Offset(foot.dx, foot.dy + 6)), isFalse, reason: id);
    }

    expectFeet('growth_house', const Offset(0.74, 0.60));
    expectFeet('lighthouse', const Offset(0.68, 0.34));
    expectFeet('habit_flowerbed', const Offset(0.82, 0.56));
    expectFeet('story_plaza', const Offset(0.50, 0.72));

    final light = mainIslandBuildingTapRect(
      definitionId: 'lighthouse',
      plateAnchor: const Offset(0.68, 0.34),
      sceneSize: scene,
      plateScale: plateScale,
    );
    expect(light.width / light.height, closeTo(0.95, 0.03));

    final plaza = mainIslandBuildingTapRect(
      definitionId: 'story_plaza',
      plateAnchor: const Offset(0.50, 0.72),
      sceneSize: scene,
      plateScale: plateScale,
    );
    expect(plaza.width / plaza.height, greaterThan(1.6));
  });
}
