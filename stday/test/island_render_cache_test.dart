import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/core/models/mood_island_config.dart';
import 'package:stday/world/engine/world_state.dart';
import 'package:stday/world/island/island_renderer.dart';
import 'package:stday/world/rendering/retained_picture.dart';

void main() {
  test('retained picture rasterizes once for the same token', () {
    final retained = RetainedPicture();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    var paints = 0;
    retained.draw(canvas, 1, (_) => paints++);
    retained.draw(canvas, 1, (_) => paints++);
    retained.draw(canvas, 2, (_) => paints++);
    expect(paints, 2);
    expect(retained.rasterCount, 2);
    retained.dispose();
    recorder.endRecording().dispose();
  });

  test('growth island body is reused while shore ripples keep moving', () {
    final renderer = IslandRenderer(compact: false);
    final style = _growthStyle();
    final island = IslandState(
      shapeKey: style.islandShape,
      style: style,
      elevation: 0.048,
      prosperityTier: 2,
      radius: 1,
    );
    final env = MoodEnvironmentState.fallback(CharacterMood.calm, style);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    renderer.render(canvas, const Size(390, 720), island, env);
    renderer.update(0.4);
    renderer.render(canvas, const Size(390, 720), island, env);
    expect(renderer.debugGrowthBodyRasterCount, 1);

    renderer.render(canvas, const Size(420, 760), island, env);
    expect(renderer.debugGrowthBodyRasterCount, 2);

    renderer.dispose();
    recorder.endRecording().dispose();
  });
}

MoodIslandConfig _growthStyle() {
  return const MoodIslandConfig(
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
}
