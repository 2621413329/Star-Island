import 'package:flutter/material.dart';

import '../../core/models/character_mood.dart';
import '../../core/weather/real_weather_snapshot.dart';
import '../../island/config/mood_atmosphere_config.dart';
import '../../island/config/weather_atmosphere_config.dart';
import '../engine/world_state.dart';

class MoodEnvironmentController {
  const MoodEnvironmentController();

  MoodEnvironmentState compute(
    CharacterMood mood, {
    String? moodId,
    RealWeatherSnapshot? weather,
  }) {
    final moodPreset = MoodAtmosphereConfig.resolve(
      moodId ?? _moodIdFromCharacter(mood),
    );
    final preset = weather != null
        ? WeatherAtmosphereConfig.blendWithMood(weather, moodPreset)
        : moodPreset;
    final grade = switch (mood) {
      CharacterMood.happy => ColorGrade.warm,
      CharacterMood.anxious || CharacterMood.angry => ColorGrade.cool,
      CharacterMood.proud => ColorGrade.golden,
      _ => ColorGrade.neutral,
    };
    return MoodEnvironmentState(
      skyTop: preset.skyTop,
      skyBottom: preset.skyBottom,
      sea: preset.rain ? const Color(0xFF607D8B) : const Color(0xFF6EC4DC),
      sunIntensity: preset.sunIntensity,
      cloudDensity: preset.cloudDensity,
      windStrength: preset.windStrength,
      waveIntensity: preset.waveIntensity,
      particlePreset: preset.particlePreset,
      rain: preset.rain,
      colorGrade: grade,
      lifePreset: preset.lifePreset,
      fogOpacity: preset.fogOpacity,
    );
  }

  static String _moodIdFromCharacter(CharacterMood mood) => switch (mood) {
        CharacterMood.happy => 'happy',
        CharacterMood.anxious => 'thinking',
        CharacterMood.angry => 'angry',
        CharacterMood.proud => 'happy',
        CharacterMood.calm => 'calm',
      };
}

extension MoodEnvironmentStateCopy on MoodEnvironmentState {
  MoodEnvironmentState copyWith({
    double? sunIntensity,
    double? cloudDensity,
    double? windStrength,
    double? waveIntensity,
    String? particlePreset,
    bool? rain,
    ColorGrade? colorGrade,
    String? lifePreset,
    double? fogOpacity,
  }) {
    return MoodEnvironmentState(
      skyTop: skyTop,
      skyBottom: skyBottom,
      sea: sea,
      sunIntensity: sunIntensity ?? this.sunIntensity,
      cloudDensity: cloudDensity ?? this.cloudDensity,
      windStrength: windStrength ?? this.windStrength,
      waveIntensity: waveIntensity ?? this.waveIntensity,
      particlePreset: particlePreset ?? this.particlePreset,
      rain: rain ?? this.rain,
      colorGrade: colorGrade ?? this.colorGrade,
      lifePreset: lifePreset ?? this.lifePreset,
      fogOpacity: fogOpacity ?? this.fogOpacity,
      ambientAudio: ambientAudio,
    );
  }
}
