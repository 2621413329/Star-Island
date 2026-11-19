import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/placement/island_building_layout.dart';
import 'package:stday/island/placement/main_island_placement_zones.dart';
import 'package:stday/world/island/island_placement.dart';
import 'package:stday/world/island/painted_island_pits.dart';
import 'package:stday/island/service/building_resolver.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';
import 'package:stday/world/engine/world_state_v2.dart';
import 'package:stday/world/scene/scene_depth_priority.dart';

GrowthSummary _summary(int level) {
  return GrowthSummary(
    growthValue: level * 100,
    level: level,
    levelTitle: 'Lv$level',
    streakDays: level,
    maxStreakDays: level,
    nextLevel: level < 20 ? level + 1 : null,
    nextLevelTitle: level < 20 ? 'Lv${level + 1}' : null,
    xpIntoLevel: 0,
    xpForNextLevel: level < 20 ? 100 : null,
    islandStage: level,
    unlockLabel: 'Visual Lv$level',
    todayMood: 'ping_jing',
    todayWeatherLabel: GrowthSystem.moodWeatherLabel('calm'),
    isGuest: true,
  );
}

WorldStateV2 _stateAtLevel(int level) {
  final generator = IslandGenerator();
  return generator.generate(
    GrowthWorldInput(
      mood: CharacterMood.calm,
      events: const [],
      islandStyle: const IslandStyleResolver().resolve(moodId: 'calm'),
      summary: _summary(level),
      companionStyle: 'cozy',
      companionGender: 'female',
    ),
  );
}

void main() {
  test('starter stone anchor is on lower-left island area', () {
    expect(IslandBuildingLayout.starterStoneAnchor.dx, lessThan(0.28));
    expect(IslandBuildingLayout.starterStoneAnchor.dy, greaterThan(0.54));
    expect(
      MainIslandPlacementZones.protagonistExclusion
          .contains(IslandBuildingLayout.starterStoneAnchor),
      isFalse,
    );
  });

  test('key buildings use semantic anchors', () {
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('library_seed')!,
        islandRadius: 1.0,
      ).dx,
      inInclusiveRange(0.18, 0.84),
    );
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('lighthouse')!,
        islandRadius: 1.0,
      ).dx,
      inInclusiveRange(0.18, 0.84),
    );
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('growth_academy')!,
        islandRadius: 1.0,
      ).dx,
      closeTo(0.5, 0.06),
    );
  });

  test('harbor pier uses bottom-center island edge anchor', () {
    final pier = GrowthIslandConfigs.buildingById('harbor_pier')!;
    final anchor =
        IslandBuildingLayout.preferredAnchor(pier, islandRadius: 1.0);
    final edge = IslandPlacement.harborPierAnchor(islandRadius: 1.0);
    expect(anchor.dx, closeTo(0.5, 0.02));
    expect(anchor.dy, closeTo(edge.dy, 0.001));
    expect(anchor.dy, greaterThan(IslandPlacement.center.dy));
  });

  test('building resolver keeps dream observatory anchor separated', () {
    final resolver = BuildingResolver();
    final dream = GrowthIslandConfigs.buildingById('dream_observatory')!;
    final academy = GrowthIslandConfigs.buildingById('growth_academy')!;
    final snapshots = resolver.resolveConfigured(
      configs: [academy, dream],
      islandRadius: 1.2,
    );
    final academySnap = snapshots.firstWhere(
      (b) => b.definitionId == 'growth_academy',
    );
    final dreamSnap = snapshots.firstWhere(
      (b) => b.definitionId == 'dream_observatory',
    );
    expect(
      (dreamSnap.anchor - academySnap.anchor).distance,
      greaterThan(0.075),
    );
  });

  test('generated buildings sit on painted plate pits', () {
    final state = _stateAtLevel(20);
    final ids = state.buildings.map((b) => b.definitionId).toSet();
    expect(ids, contains('growth_tree'));
    expect(ids.length, state.buildings.length);
    expect(ids.contains('growth_house') && ids.contains('growth_house_lv2'),
        isFalse);
    expect(
        ids.contains('lighthouse') && ids.contains('lighthouse_base'), isFalse);
    for (final building in state.buildings) {
      expect(
        PaintedIslandPits.building(building.definitionId),
        building.anchor,
        reason: building.definitionId,
      );
      expect(building.anchor.dx, inInclusiveRange(0.12, 0.86));
      expect(building.anchor.dy, inInclusiveRange(0.14, 0.90));
    }
  });

  test('record_shed keeps its plate pit from Lv5', () {
    for (final level in [5, 6, 7, 9, 12]) {
      final state = _stateAtLevel(level);
      final shed = state.buildings
          .where((b) => b.definitionId == 'record_shed')
          .toList();
      expect(shed, isNotEmpty, reason: 'Lv$level should unlock record_shed');
      expect(shed.first.anchor, PaintedIslandPits.building('record_shed'));
    }
  });

  test('Lv20 building depth order keeps front above rear', () {
    final state = _stateAtLevel(20);
    final buildings = state.buildings
        .where((b) =>
            b.definitionId != 'story_plaza' &&
            b.definitionId != 'companion_plaza')
        .toList();
    for (var i = 0; i < buildings.length; i++) {
      for (var j = i + 1; j < buildings.length; j++) {
        final a = buildings[i];
        final b = buildings[j];
        final pa = SceneDepthPriority.ground(a.anchor.dy);
        final pb = SceneDepthPriority.ground(b.anchor.dy);
        if (a.anchor.dy < b.anchor.dy - 1e-9) {
          expect(
            pa,
            lessThan(pb),
            reason: 'rear ${a.definitionId}@${a.anchor.dy.toStringAsFixed(3)} '
                'must not draw above front ${b.definitionId}',
          );
        } else if (b.anchor.dy < a.anchor.dy - 1e-9) {
          expect(
            pb,
            lessThan(pa),
            reason: 'rear ${b.definitionId}@${b.anchor.dy.toStringAsFixed(3)} '
                'must not draw above front ${a.definitionId}',
          );
        }
      }
    }
  });
}
