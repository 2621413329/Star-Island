import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/core/models/mood_island_config.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/features/home/providers/home_island_slots_provider.dart';
import 'package:stday/world/engine/world_state.dart';
import 'package:stday/world/island/island_body_image_cache.dart';
import 'package:stday/world/island/island_render_key.dart';

void main() {
  tearDown(IslandBodyImageCache.debugReset);

  test('different island sizes keep separate body images', () {
    final island = _island();
    final env = MoodEnvironmentState.fallback(CharacterMood.calm, island.style);
    final first = IslandBodyImageRequest(
      island: island,
      environment: env,
      logicalSize: const Size(80, 64),
      devicePixelRatio: 1,
    );
    final second = IslandBodyImageRequest(
      island: island,
      environment: env,
      logicalSize: const Size(120, 90),
      devicePixelRatio: 1,
    );

    IslandBodyImageCache.rasterSync(first);
    IslandBodyImageCache.rasterSync(second);
    IslandBodyImageCache.rasterSync(first);

    expect(IslandBodyImageCache.rasterCount, 2);
    expect(IslandBodyImageCache.hitCount, 1);
    expect(IslandBodyImageCache.peek(first.job.imageKey), isNotNull);
    expect(IslandBodyImageCache.peek(second.job.imageKey), isNotNull);
  });

  test('appearance key changes when prosperity or size changes', () {
    final island = _island();
    final env = MoodEnvironmentState.fallback(CharacterMood.calm, island.style);
    final base = IslandRenderKey.from(
      compact: true,
      size: const Size(80, 64),
      island: island,
      environment: env,
    );
    final same = IslandRenderKey.from(
      compact: true,
      size: const Size(80.2, 64.2),
      island: island,
      environment: env,
    );
    final larger = IslandRenderKey.from(
      compact: true,
      size: const Size(120, 90),
      island: IslandState(
        shapeKey: island.shapeKey,
        style: island.style,
        elevation: island.elevation,
        prosperityTier: island.prosperityTier + 1,
        radius: island.radius,
      ),
      environment: env,
    );

    expect(same, base);
    expect(larger == base, isFalse);
  });

  test('slot equality ignores a rebuilt model with the same visible fields', () {
    final island = StoryIslandModel(
      id: 'island-a',
      categoryId: 'study',
      name: '学习岛',
      currentLevel: 2,
      growthValue: 20,
    );
    final slot = HomeIslandSlot(
      slotId: 'rank_0',
      displayName: '学习岛',
      level: 2,
      island: island,
      categoryId: 'study',
      hasStories: false,
      isOpened: true,
    );
    final rebuilt = HomeIslandSlot(
      slotId: 'rank_0',
      displayName: '学习岛',
      level: 2,
      island: StoryIslandModel(
        id: 'island-a',
        categoryId: 'study',
        name: '学习岛',
        currentLevel: 2,
        growthValue: 20,
      ),
      categoryId: 'study',
      hasStories: false,
      isOpened: true,
    );
    final leveled = HomeIslandSlot(
      slotId: 'rank_0',
      displayName: '学习岛',
      level: 3,
      island: island,
      categoryId: 'study',
    );

    expect(rebuilt, slot);
    expect(leveled == slot, isFalse);
  });
}

IslandState _island() {
  const style = MoodIslandConfig(
    moodId: 'calm',
    styleKey: 'growth_world',
    label: '成长岛',
    skyTop: Color(0xFFE3F2FD),
    skyBottom: Color(0xFFB3E5FC),
    sea: Color(0xFF4FC3F7),
    sand: Color(0xFFECEFF1),
    accent: Color(0xFFFFCC80),
    grass: Color(0xFF81C784),
    flower: Color(0xFFF8BBD0),
    waveIntensity: 0.35,
    rain: false,
    wind: false,
    islandShape: 'growth_world',
    biome: 'growth_world',
    ambientParticles: 'sparkle',
  );
  return IslandState(
    shapeKey: style.islandShape,
    style: style,
    elevation: 0.048,
    prosperityTier: 1,
    radius: 0.78,
  );
}
