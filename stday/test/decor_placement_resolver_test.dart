import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_placement_resolver.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';
import 'package:stday/world/engine/world_state.dart';

bool _meaningfullyOverlaps(Rect a, Rect b) {
  if (!a.overlaps(b)) return false;
  final hit = a.intersect(b);
  return hit.width > 0.001 && hit.height > 0.001;
}

void main() {
  test('DecorPlacementResolver moves decor out of protagonist rear zone', () {
    const resolver = DecorPlacementResolver();
    final positions = resolver.resolve(DecorConfigs.unlockedAt(5));

    for (final entry in positions.entries) {
      final p = entry.value;
      expect(
        DecorPlacementResolver.protagonistRearZone.contains(p),
        isFalse,
        reason: '${entry.key} should not sit behind protagonist at $p',
      );
    }

    final tree = positions['tree_small_01'];
    if (tree != null) {
      expect((tree.dx - 0.5).abs(), greaterThan(0.08));
    }
  });

  test('DecorPlacementResolver keeps ground decor from overlapping', () {
    const resolver = DecorPlacementResolver();
    final configs = DecorConfigs.unlockedAt(12);
    final positions = resolver.resolve(configs);

    Rect occupancy(String id) {
      final config = configs.firstWhere((c) => c.id == id);
      final pos = positions[id]!;
      return resolver.paddedOccupancyFor(config, pos);
    }

    final groundIds = positions.keys.where((id) {
      final config = configs.firstWhere((c) => c.id == id);
      return config.category != DecorCategory.cloud &&
          config.category != DecorCategory.bird &&
          config.category != DecorCategory.butterfly &&
          config.category != DecorCategory.firefly;
    }).toList();

    for (var i = 0; i < groundIds.length; i++) {
      for (var j = i + 1; j < groundIds.length; j++) {
        final a = occupancy(groundIds[i]);
        final b = occupancy(groundIds[j]);
        expect(
          _meaningfullyOverlaps(a, b),
          isFalse,
          reason: '${groundIds[i]} at $a overlaps ${groundIds[j]} at $b',
        );
      }
    }
  });

  test('DecorPlacementResolver avoids building footprints', () {
    const resolver = DecorPlacementResolver();
    final state = IslandGenerator().generate(
      GrowthWorldInput(
        mood: CharacterMood.calm,
        events: const [],
        islandStyle: const IslandStyleResolver().resolve(moodId: 'calm'),
        summary: GrowthSummary(
          growthValue: 1200,
          level: 12,
          levelTitle: 'Lv12',
          streakDays: 12,
          maxStreakDays: 12,
          nextLevel: 13,
          nextLevelTitle: 'Lv13',
          xpIntoLevel: 0,
          xpForNextLevel: 100,
          islandStage: 12,
          unlockLabel: 'Visual Lv12',
          todayMood: 'ping_jing',
          todayWeatherLabel: GrowthSystem.moodWeatherLabel('calm'),
          isGuest: true,
        ),
        companionStyle: 'cozy',
        companionGender: 'female',
      ),
    );
    final buildings = state.buildings;
    final positions = resolver.resolve(
      DecorConfigs.unlockedMainIslandAt(12),
      buildings: buildings,
    );

    final buildingRects = DecorPlacementResolver.buildingBlockedRegions(buildings);
    for (final entry in positions.entries) {
      final config = DecorConfigs.unlockedMainIslandAt(12)
          .firstWhere((c) => c.id == entry.key);
      if (resolver.isSkyDecor(config)) continue;
      final decorRect = resolver.paddedOccupancyFor(config, entry.value);
      for (final buildingRect in buildingRects) {
        expect(
          _meaningfullyOverlaps(decorRect, buildingRect),
          isFalse,
          reason: '${entry.key} overlaps building at $buildingRect',
        );
      }
    }
  });

  test('DecorPlacementResolver keeps grass away from buildings with extra clearance',
      () {
    const resolver = DecorPlacementResolver();
    const grass = DecorConfig(
      id: 'grass_test',
      image: 'grass_01.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.50,
      y: 0.48,
      scale: 1.0,
    );
    const building = BuildingSnapshot(
      definitionId: 'growth_academy',
      level: 12,
      anchor: Offset(0.50, 0.26),
      size: Offset(0.22, 0.30),
    );
    final positions = resolver.resolve(
      [grass],
      buildings: const [building],
    );
    final pos = positions['grass_test']!;
    final decorRect = resolver.paddedOccupancyFor(grass, pos);
    final grassBlocks =
        DecorPlacementResolver.buildingBlockedRegionsFor(grass, [building]);
    for (final block in grassBlocks) {
      expect(
        _meaningfullyOverlaps(decorRect, block),
        isFalse,
        reason: 'grass should respect expanded building clearance',
      );
    }
    expect(pos.dy, greaterThan(0.24), reason: 'grass should sit below building');
  });
}
