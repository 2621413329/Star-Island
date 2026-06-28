import 'package:flutter/material.dart';

import '../../../core/models/character_mood.dart';

/// 情绪仅影响氛围，不改变岛屿结构。
class MoodAtmospherePreset {
  const MoodAtmospherePreset({
    required this.skyTop,
    required this.skyBottom,
    required this.sunIntensity,
    required this.cloudDensity,
    required this.windStrength,
    required this.waveIntensity,
    required this.particlePreset,
    required this.rain,
    required this.lifePreset,
    required this.fogOpacity,
  });

  final Color skyTop;
  final Color skyBottom;
  final double sunIntensity;
  final double cloudDensity;
  final double windStrength;
  final double waveIntensity;
  final String particlePreset;
  final bool rain;

  /// 环境生命感：seagulls | breeze | drizzle | wind | starglow
  final String lifePreset;
  final double fogOpacity;
}

class MoodAtmosphereConfig {
  MoodAtmosphereConfig._();

  static MoodAtmospherePreset resolve(String? moodId) {
    return switch (moodId) {
      'happy' => const MoodAtmospherePreset(
          skyTop: Color(0xFFFFE3A8),
          skyBottom: Color(0xFFFFF2C7),
          sunIntensity: 1.18,
          cloudDensity: 0.06,
          windStrength: 0.10,
          waveIntensity: 0.55,
          particlePreset: 'golden_sparkle',
          rain: false,
          lifePreset: 'seagulls',
          fogOpacity: 0,
        ),
      'sad' => const MoodAtmospherePreset(
          skyTop: Color(0xFF90A4AE),
          skyBottom: Color(0xFFCFD8DC),
          sunIntensity: 0.35,
          cloudDensity: 0.82,
          windStrength: 0.25,
          waveIntensity: 0.32,
          particlePreset: 'soft_rain',
          rain: true,
          lifePreset: 'drizzle',
          fogOpacity: 0.22,
        ),
      'thinking' || 'anxious' => const MoodAtmospherePreset(
          skyTop: Color(0xFFB0BEC5),
          skyBottom: Color(0xFFECEFF1),
          sunIntensity: 0.42,
          cloudDensity: 0.78,
          windStrength: 0.72,
          waveIntensity: 0.52,
          particlePreset: 'wind_leaves',
          rain: false,
          lifePreset: 'wind',
          fogOpacity: 0.14,
        ),
      'angry' => const MoodAtmospherePreset(
          skyTop: Color(0xFF9E9E9E),
          skyBottom: Color(0xFFBDBDBD),
          sunIntensity: 0.5,
          cloudDensity: 0.65,
          windStrength: 0.85,
          waveIntensity: 0.58,
          particlePreset: 'wind_leaves',
          rain: false,
          lifePreset: 'wind',
          fogOpacity: 0.1,
        ),
      _ => const MoodAtmospherePreset(
          skyTop: Color(0xFFEAF7FA),
          skyBottom: Color(0xFFD4EFF5),
          sunIntensity: 0.72,
          cloudDensity: 0.32,
          windStrength: 0.22,
          waveIntensity: 0.28,
          particlePreset: 'bloom',
          rain: false,
          lifePreset: 'breeze',
          fogOpacity: 0,
        ),
    };
  }

  static MoodAtmospherePreset fromCharacterMood(CharacterMood mood) =>
      resolve(switch (mood) {
        CharacterMood.happy => 'happy',
        CharacterMood.anxious => 'thinking',
        CharacterMood.angry => 'angry',
        CharacterMood.proud => 'happy',
        CharacterMood.calm => 'calm',
      });
}
