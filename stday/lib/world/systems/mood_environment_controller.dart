import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';
import '../engine/world_state.dart';

class MoodEnvironmentController {
  MoodEnvironmentState compute(CharacterMood mood, MoodIslandConfig style) {
    final base = MoodEnvironmentState.fallback(mood, style);
    return switch (mood) {
      CharacterMood.happy => base.copyWith(
            sunIntensity: 0.95,
            cloudDensity: 0.2,
            windStrength: 0.2,
            waveIntensity: style.waveIntensity.clamp(0.4, 1.0),
            particlePreset: 'bloom',
          ),
      CharacterMood.anxious => base.copyWith(
            sunIntensity: 0.4,
            cloudDensity: 0.82,
            windStrength: 0.65,
            waveIntensity: (style.waveIntensity + 0.15).clamp(0.0, 1.0),
            particlePreset: 'drizzle',
            rain: style.rain,
          ),
      CharacterMood.angry => base.copyWith(
            sunIntensity: 0.7,
            cloudDensity: 0.45,
            windStrength: 0.9,
            particlePreset: 'leaves',
          ),
      CharacterMood.proud => base.copyWith(
            sunIntensity: 0.88,
            cloudDensity: 0.25,
            particlePreset: 'golden_sparkle',
            colorGrade: ColorGrade.golden,
          ),
      CharacterMood.calm => base,
    };
  }
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
      ambientAudio: ambientAudio,
    );
  }
}
