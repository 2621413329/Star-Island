import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/models/mood_island_config.dart';
import 'package:stday/world/engine/world_state.dart';
import 'package:stday/world/island/realistic_lawn_renderer.dart';

void main() {
  test('RealisticLawnRenderer paints without throwing', () {
    const style = MoodIslandConfig(
      moodId: 'calm',
      styleKey: 'growth_world',
      label: 'calm',
      biome: 'growth_world',
      islandShape: 'growth_world',
      grass: Color(0xFF7EC87A),
      sand: Color(0xFFE8E0D4),
      sea: Color(0xFF5BB5D5),
      accent: Color(0xFFE8B86D),
      flower: Color(0xFFF8BBD0),
      skyTop: Color(0xFFEAF7FA),
      skyBottom: Color(0xFFD4EFF5),
      wind: false,
      rain: false,
      waveIntensity: 0.3,
      ambientParticles: 'bloom',
    );
    const env = MoodEnvironmentState(
      skyTop: Color(0xFFE8F6FA),
      skyBottom: Color(0xFFD4EFF5),
      sea: Color(0xFF5BB5D5),
      sunIntensity: 1.0,
      cloudDensity: 0.2,
      windStrength: 0.2,
      waveIntensity: 0.3,
      particlePreset: 'bloom',
      rain: false,
      colorGrade: ColorGrade.neutral,
      shadowDx: 0.22,
      shadowDy: 0.06,
      shadowStretch: 1.4,
      shadowAlpha: 0.2,
      lightWarmth: 0.7,
      ambientShadeStrength: 0.14,
    );

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    RealisticLawnRenderer(
      compact: false,
      time: 1.2,
      environment: env,
      sceneSize: const Size(400, 800),
      clipPath: Path()
        ..addOval(
          Rect.fromCenter(
              center: const Offset(200, 220), width: 300, height: 160),
        ),
    ).paint(
      canvas,
      style: style,
      cx: 200,
      cy: 220,
      rx: 150,
      ry: 80,
    );
    final picture = recorder.endRecording();
    expect(picture, isNotNull);
  });
}
