import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/config/growth_island_configs.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/placement/island_building_layout.dart';
import 'package:stday/island/service/building_resolver.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';

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

void main() {
  test('starter stone anchor is on lower-left island area', () {
    expect(IslandBuildingLayout.starterStoneAnchor.dx, lessThan(0.35));
    expect(IslandBuildingLayout.starterStoneAnchor.dy, greaterThan(0.58));
  });

  test('key buildings use fixed regional anchors', () {
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('library_seed')!,
        islandRadius: 1.0,
      ).dx,
      lessThan(0.28),
    );
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('lighthouse')!,
        islandRadius: 1.0,
      ).dx,
      greaterThan(0.70),
    );
    expect(
      IslandBuildingLayout.preferredAnchor(
        GrowthIslandConfigs.buildingById('growth_academy')!,
        islandRadius: 1.0,
      ).dy,
      lessThan(0.45),
    );
  });

  test('dream observatory uses fixed upper-right anchor', () {
    final dream = GrowthIslandConfigs.buildingById('dream_observatory')!;
    expect(
      IslandBuildingLayout.preferredAnchor(dream, islandRadius: 1.2),
      const Offset(0.84, 0.18),
    );
  });

  test('building resolver keeps dream observatory anchor separated', () {
    const resolver = BuildingResolver();
    final dream = GrowthIslandConfigs.buildingById('dream_observatory')!;
    final academy = GrowthIslandConfigs.buildingById('growth_academy')!;
    final snapshots = resolver.resolveConfigured(
      configs: [academy, dream],
      islandRadius: 1.2,
    );
    final dreamSnap = snapshots.firstWhere(
      (b) => b.definitionId == 'dream_observatory',
    );
    expect(dreamSnap.anchor.dx, closeTo(0.84, 0.01));
    expect(dreamSnap.anchor.dy, closeTo(0.18, 0.01));
  });

  test('Lv5 generated buildings do not overlap footprints', () {
    const generator = IslandGenerator();
    final state = generator.generate(
      GrowthWorldInput(
        mood: CharacterMood.calm,
        events: const [],
        islandStyle: const IslandStyleResolver().resolve(moodId: 'calm'),
        summary: _summary(5),
        companionStyle: 'cozy',
        companionGender: 'female',
      ),
    );

    final snapshots = state.buildings;
    expect(snapshots, isNotEmpty);

    for (var i = 0; i < snapshots.length; i++) {
      for (var j = i + 1; j < snapshots.length; j++) {
        final a = snapshots[i];
        final b = snapshots[j];
        final rectA =
            IslandBuildingLayout.occupancyRect(a.anchor, a.size, margin: 0);
        final rectB =
            IslandBuildingLayout.occupancyRect(b.anchor, b.size, margin: 0);
        expect(
          rectA.overlaps(rectB),
          isFalse,
          reason: '${a.definitionId} overlaps ${b.definitionId}',
        );
      }
    }
  });
}
