import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/building/building_depth_scale.dart';
import 'package:stday/island/debug/main_island_debug_overlay.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_scale_resolver.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';

void main() {
  group('DecorScaleResolver depth perspective', () {
    const resolver = DecorScaleResolver();
    const grass = DecorConfig(
      id: 'grass_01',
      image: 'grass_01.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.5,
      y: 0.65,
      scale: 1.0,
    );

    test('ground decor scales smaller toward island back', () {
      final front = resolver.computeSize(
        config: grass,
        userLevel: 10,
        spriteSrcSize: Vector2(800, 800),
        viewportHeight: 800,
        normalizedAnchorY: 0.66,
      );
      final back = resolver.computeSize(
        config: grass,
        userLevel: 10,
        spriteSrcSize: Vector2(800, 800),
        viewportHeight: 800,
        normalizedAnchorY: 0.24,
      );
      expect(back.y, lessThan(front.y));
      expect(
        back.y / front.y,
        closeTo(
          BuildingDepthScale.forAnchorDy(0.24) /
              BuildingDepthScale.forAnchorDy(0.66),
          0.001,
        ),
      );
    });

    test('sky decor ignores depth scale', () {
      const cloud = DecorConfig(
        id: 'cloud_01',
        image: 'cloud_01.png',
        category: DecorCategory.cloud,
        unlockLevel: 8,
        x: 0.2,
        y: 0.2,
        scale: 1.0,
      );
      final withDepth = resolver.computeSize(
        config: cloud,
        userLevel: 10,
        spriteSrcSize: Vector2(800, 800),
        viewportHeight: 800,
        normalizedAnchorY: 0.24,
      );
      final withoutDepth = resolver.computeSize(
        config: cloud,
        userLevel: 10,
        spriteSrcSize: Vector2(800, 800),
        viewportHeight: 800,
      );
      expect(withDepth, equals(withoutDepth));
    });
  });

  test('MainIslandDebugOverlay draws without throwing', () {
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
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    expect(
      () => MainIslandDebugOverlay.draw(
        canvas,
        const Size(390, 844),
        worldState: state,
        userLevel: 12,
      ),
      returnsNormally,
    );
  });
}
