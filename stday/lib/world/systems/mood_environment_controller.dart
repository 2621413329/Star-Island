import 'package:flutter/material.dart';

import '../../core/models/character_mood.dart';
import '../../core/weather/real_weather_snapshot.dart';
import '../engine/world_state.dart';
import 'config/day_phase_lighting_config.dart';
import 'config/mood_atmosphere_config.dart';
import 'config/weather_atmosphere_config.dart';

class MoodEnvironmentController {
  const MoodEnvironmentController();

  MoodEnvironmentState compute(
    CharacterMood mood, {
    String? moodId,
    RealWeatherSnapshot? weather,
    DateTime? atTime,
    DayPhase? dayPhaseOverride,
  }) {
    final moodPreset = MoodAtmosphereConfig.resolve(
      moodId ?? _moodIdFromCharacter(mood),
    );
    final preset = weather != null
        ? WeatherAtmosphereConfig.blendWithMood(weather, moodPreset)
        : moodPreset;
    final phase = dayPhaseOverride ?? resolveDayPhase(atTime);
    final lighting = DayPhaseLightingPreset.forPhase(phase).blendWithAtmosphere(
      moodSkyTop: preset.skyTop,
      moodSkyBottom: preset.skyBottom,
      moodSunIntensity: preset.sunIntensity,
    );
    final grade = switch (mood) {
      CharacterMood.happy => ColorGrade.warm,
      CharacterMood.anxious || CharacterMood.angry => ColorGrade.cool,
      CharacterMood.proud => ColorGrade.golden,
      _ => ColorGrade.neutral,
    };
    return MoodEnvironmentState(
      skyTop: lighting.skyTop,
      skyBottom: lighting.skyBottom,
      sea: preset.rain ? const Color(0xFF607D8B) : const Color(0xFF6EC4DC),
      sunIntensity: lighting.sunIntensity,
      cloudDensity: preset.cloudDensity,
      windStrength: preset.windStrength,
      waveIntensity: preset.waveIntensity,
      particlePreset: preset.particlePreset,
      rain: preset.rain,
      colorGrade: grade,
      lifePreset: preset.lifePreset,
      fogOpacity: preset.fogOpacity,
      dayPhase: phase,
      sunX: lighting.sunX,
      sunY: lighting.sunY,
      shadowDx: lighting.shadowDx,
      shadowDy: lighting.shadowDy,
      shadowStretch: lighting.shadowStretch,
      shadowAlpha: lighting.shadowAlpha,
      lightWarmth: lighting.lightWarmth,
      ambientShadeStrength: lighting.ambientShadeStrength,
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
    Color? skyTop,
    Color? skyBottom,
    Color? sea,
    double? sunIntensity,
    double? cloudDensity,
    double? windStrength,
    double? waveIntensity,
    String? particlePreset,
    bool? rain,
    ColorGrade? colorGrade,
    String? lifePreset,
    double? fogOpacity,
    DayPhase? dayPhase,
    double? sunX,
    double? sunY,
    double? shadowDx,
    double? shadowDy,
    double? shadowStretch,
    double? shadowAlpha,
    double? lightWarmth,
    double? ambientShadeStrength,
  }) {
    return MoodEnvironmentState(
      skyTop: skyTop ?? this.skyTop,
      skyBottom: skyBottom ?? this.skyBottom,
      sea: sea ?? this.sea,
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
      dayPhase: dayPhase ?? this.dayPhase,
      sunX: sunX ?? this.sunX,
      sunY: sunY ?? this.sunY,
      shadowDx: shadowDx ?? this.shadowDx,
      shadowDy: shadowDy ?? this.shadowDy,
      shadowStretch: shadowStretch ?? this.shadowStretch,
      shadowAlpha: shadowAlpha ?? this.shadowAlpha,
      lightWarmth: lightWarmth ?? this.lightWarmth,
      ambientShadeStrength: ambientShadeStrength ?? this.ambientShadeStrength,
    );
  }
}
