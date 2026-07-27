import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/building/building_depth_scale.dart';
import 'package:stday/island/building/building_footprint.dart';
import 'package:stday/island/placement/island_building_layout.dart';
import 'package:stday/island/placement/main_island_placement_zones.dart';
import 'package:stday/world/island/island_placement.dart';
import 'package:stday/island/service/building_resolver.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';
import 'package:stday/world/engine/world_state.dart';
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

Rect _buildingCollision(BuildingSnapshot building) {
  return IslandBuildingLayout.collisionRect(
    building.anchor,
    building.size,
    buildingId: building.definitionId,
  );
}

bool _buildingsVisuallyOverlap(BuildingSnapshot a, BuildingSnapshot b) {
  if (IslandBuildingLayout.skipsVisualCollision(
    a.definitionId,
    b.definitionId,
  )) {
    return false;
  }
  final minDist = IslandBuildingLayout.visualSeparationRadius(
        a.definitionId,
        a.size,
      ) +
      IslandBuildingLayout.visualSeparationRadius(
        b.definitionId,
        b.size,
      ) +
      IslandBuildingLayout.overlapPadding;
  return (a.anchor - b.anchor).distance + 1e-9 < minDist;
}

Rect _buildingOccupancy(BuildingSnapshot building) {
  return IslandBuildingLayout.occupancyRect(
    building.anchor,
    building.size,
    buildingId: building.definitionId,
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
    final anchor = IslandBuildingLayout.preferredAnchor(pier, islandRadius: 1.0);
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

  test('Lv5 generated buildings do not overlap visual footprints', () {
    final state = _stateAtLevel(5);
    final snapshots = state.buildings;
    expect(snapshots, isNotEmpty);

    for (var i = 0; i < snapshots.length; i++) {
      for (var j = i + 1; j < snapshots.length; j++) {
        final a = snapshots[i];
        final b = snapshots[j];
        expect(
          _buildingsVisuallyOverlap(a, b),
          isFalse,
          reason: '${a.definitionId} overlaps ${b.definitionId}',
        );
      }
    }
  });

  test('Lv20 visual-scaled buildings do not overlap', () {
    final state = _stateAtLevel(20);
    final snapshots = state.buildings;
    expect(snapshots.length, greaterThan(3));

    for (var i = 0; i < snapshots.length; i++) {
      for (var j = i + 1; j < snapshots.length; j++) {
        final a = snapshots[i];
        final b = snapshots[j];
        expect(
          _buildingsVisuallyOverlap(a, b),
          isFalse,
          reason:
              '${a.definitionId}@${a.anchor} overlaps ${b.definitionId}@${b.anchor}',
        );
      }
    }
  });

  test('Lv20 academy sits in mid-rear center band', () {
    final state = _stateAtLevel(20);
    final academy = state.buildings
        .firstWhere((b) => b.definitionId == 'growth_academy');
    expect(academy.anchor.dx, closeTo(0.5, 0.06));
    expect(academy.anchor.dy, inInclusiveRange(0.32, 0.44));
    expect(
      BuildingDepthScale.forAnchorDy(academy.anchor.dy),
      lessThan(0.96),
    );
  });

  test('Lv20 observatory avoids large tree shore parcels', () {
    final state = _stateAtLevel(20);
    final obs = state.buildings
        .firstWhere((b) => b.definitionId == 'dream_observatory');
    final occupancy = IslandBuildingLayout.occupancyRect(
      obs.anchor,
      obs.size,
      buildingId: obs.definitionId,
    );
    expect(
      MainIslandPlacementZones.buildingOverlapsLargeTreeShoreParcel(occupancy),
      isFalse,
      reason: 'obs=${obs.anchor}',
    );
    expect(
      BuildingFootprint.isVisuallyOnGrowthIsland(
        obs.anchor,
        obs.size,
        buildingId: obs.definitionId,
      ),
      isTrue,
    );
  });

  test('Lv20 visual-scaled buildings stay on island edge', () {
    final state = _stateAtLevel(20);
    for (final building in state.buildings) {
      if (BuildingFootprint.skipsVisualEdgeCheck(building.definitionId)) {
        continue;
      }
      expect(
        BuildingFootprint.isVisuallyOnGrowthIsland(
          building.anchor,
          building.size,
          buildingId: building.definitionId,
          inset: 0.74,
        ),
        isTrue,
        reason: '${building.definitionId}@${building.anchor}',
      );
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
            reason:
                'rear ${a.definitionId}@${a.anchor.dy.toStringAsFixed(3)} '
                'must not draw above front ${b.definitionId}',
          );
        } else if (b.anchor.dy < a.anchor.dy - 1e-9) {
          expect(
            pb,
            lessThan(pa),
            reason:
                'rear ${b.definitionId}@${b.anchor.dy.toStringAsFixed(3)} '
                'must not draw above front ${a.definitionId}',
          );
        }
      }
    }
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
        final foot = IslandBuildingLayout.footPadRect(
          building.anchor,
          building.size,
        );
        expect(
          foot.overlaps(MainIslandPlacementZones.protagonistExclusion),
          isFalse,
          reason:
              '${building.definitionId} foot overlaps protagonist zone at ${building.anchor}',
        );
      }
      if (building.definitionId != 'story_plaza' &&
          building.definitionId != 'companion_plaza' &&
          building.definitionId != 'starter_stone' &&
          building.definitionId != 'harbor_pier') {
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
