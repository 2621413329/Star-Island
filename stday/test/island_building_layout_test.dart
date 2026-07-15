import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/building/building_depth_scale.dart';
import 'package:stday/island/placement/island_building_layout.dart';
import 'package:stday/island/placement/main_island_placement_zones.dart';
import 'package:stday/island/service/building_resolver.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';
import 'package:stday/world/engine/world_state.dart';
import 'package:stday/world/engine/world_state_v2.dart';

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
  const generator = IslandGenerator();
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

Rect _buildingCollision(BuildingSnapshot building) {
  return IslandBuildingLayout.collisionRect(building.anchor, building.size);
}

Rect _buildingOccupancy(BuildingSnapshot building) {
  return IslandBuildingLayout.occupancyRect(building.anchor, building.size);
}

void main() {
  test('starter stone anchor is on lower-left island area', () {
    expect(IslandBuildingLayout.starterStoneAnchor.dx, lessThan(0.35));
    expect(IslandBuildingLayout.starterStoneAnchor.dy, greaterThan(0.58));
  });

  test('key buildings use semantic anchors', () {
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('library_seed')!,
        islandRadius: 1.0,
      ).dx,
      inInclusiveRange(0.24, 0.76),
    );
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('lighthouse')!,
        islandRadius: 1.0,
      ).dx,
      inInclusiveRange(0.24, 0.76),
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
    final anchor = IslandBuildingLayout.preferredAnchor(pier, islandRadius: 1.0);
    expect(anchor.dx, closeTo(0.5, 0.02));
    expect(anchor.dy, greaterThan(0.62));
  });

  test('building resolver keeps dream observatory anchor separated', () {
    const resolver = BuildingResolver();
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
      greaterThan(0.08),
    );
  });

  test('Lv5 generated buildings do not overlap footprints', () {
    final state = _stateAtLevel(5);
    final snapshots = state.buildings;
    expect(snapshots, isNotEmpty);

    for (var i = 0; i < snapshots.length; i++) {
      for (var j = i + 1; j < snapshots.length; j++) {
        final a = snapshots[i];
        final b = snapshots[j];
        final rectA = _buildingCollision(a);
        final rectB = _buildingCollision(b);
        expect(
          rectA.overlaps(rectB),
          isFalse,
          reason: '${a.definitionId} overlaps ${b.definitionId}',
        );
      }
    }
  });

  test('Lv20 academy sits in upper center band', () {
    final state = _stateAtLevel(20);
    final academy = state.buildings
        .firstWhere((b) => b.definitionId == 'growth_academy');
    expect(academy.anchor.dx, closeTo(0.5, 0.06));
    expect(academy.anchor.dy, lessThan(0.40));
    expect(
      BuildingDepthScale.forAnchorDy(academy.anchor.dy),
      lessThan(0.92),
    );
  });

  test('Lv20 observatory uses zone-valid anchor', () {
    final state = _stateAtLevel(20);
    final obs = state.buildings
        .firstWhere((b) => b.definitionId == 'dream_observatory');
    final academy = state.buildings
        .where((b) => b.definitionId == 'growth_academy')
        .firstOrNull;
    final config = GrowthIslandConfigs.buildingById('dream_observatory')!;
    expect(
      IslandBuildingLayout.isZoneValidForBuilding(
        config: config,
        anchor: obs.anchor,
        footprint: obs.size,
        academyAnchor: academy?.anchor,
      ),
      isTrue,
      reason: 'obs=${obs.anchor} academy=${academy?.anchor}',
    );
  });

  test('Lv20 buildings avoid protagonist and plaza zones', () {
    final state = _stateAtLevel(20);
    final academy = state.buildings
        .where((b) => b.definitionId == 'growth_academy')
        .firstOrNull;
    final academyAnchor = academy?.anchor;

    for (final building in state.buildings) {
      final zoneRect = _buildingOccupancy(building);
      if (building.definitionId != 'harbor_pier' &&
          building.definitionId != 'starter_stone') {
        expect(
          zoneRect.overlaps(MainIslandPlacementZones.protagonistExclusion),
          isFalse,
          reason: '${building.definitionId} overlaps protagonist zone',
        );
      }
      if (building.definitionId != 'story_plaza' &&
          building.definitionId != 'companion_plaza' &&
          building.definitionId != 'starter_stone') {
        for (final plaza in MainIslandPlacementZones.plazaExclusions) {
          expect(
            MainIslandPlacementZones.meaningfullyOverlaps(zoneRect, plaza),
            isFalse,
            reason: '${building.definitionId} overlaps plaza at $plaza',
          );
        }
      }
    }
  });
}
