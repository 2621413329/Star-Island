import 'dart:ui';

import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';

class WorldState {
  const WorldState({
    required this.island,
    required this.characters,
    required this.buildings,
    required this.flora,
    required this.environment,
    this.companionGender,
    this.schemaVersion = 1,
  });

  final IslandState island;
  final List<CharacterSnapshot> characters;
  final List<BuildingSnapshot> buildings;
  final List<FloraSnapshot> flora;
  final MoodEnvironmentState environment;
  final String? companionGender;
  final int schemaVersion;

  static WorldState empty(MoodIslandConfig style) => WorldState(
        island: IslandState(shapeKey: style.islandShape, style: style, elevation: 0.045),
        characters: const [],
        buildings: const [],
        flora: const [],
        environment: MoodEnvironmentState.fallback(CharacterMood.calm, style),
        companionGender: null,
      );
}

class IslandState {
  const IslandState({
    required this.shapeKey,
    required this.style,
    required this.elevation,
  });

  final String shapeKey;
  final MoodIslandConfig style;
  final double elevation;
}

class CharacterSnapshot {
  const CharacterSnapshot({
    required this.id,
    required this.mood,
    required this.level,
    required this.accessoryIds,
    required this.animationKey,
    required this.normalizedPos,
    this.expression = 'calm',
    this.prop = 'none',
    this.companionScene = 'stargaze',
    this.companionPose = 'breathing',
    this.linkedEventId,
    this.tintHex,
    this.motion = const CharacterMotion(),
    this.scale = 1,
  });

  final String id;
  final CharacterMood mood;
  final int level;
  final List<String> accessoryIds;
  final String animationKey;
  final Offset normalizedPos;
  final String expression;
  final String prop;
  final String companionScene;
  final String companionPose;
  final String? linkedEventId;
  final String? tintHex;
  final CharacterMotion motion;
  final double scale;
}

class CharacterMotion {
  const CharacterMotion({
    this.bobAmplitude = 4,
    this.wanderRadius = 10,
    this.wanderSpeed = 0.5,
  });

  final double bobAmplitude;
  final double wanderRadius;
  final double wanderSpeed;
}

class BuildingSnapshot {
  const BuildingSnapshot({
    required this.definitionId,
    required this.level,
    required this.anchor,
    this.playUnlockFx = false,
  });

  final String definitionId;
  final int level;
  final Offset anchor;
  final bool playUnlockFx;
}

enum FloraKind { tree, flower, bush, grass }

class FloraSnapshot {
  const FloraSnapshot({
    required this.floraId,
    required this.kind,
    required this.position,
    required this.growth,
  });

  final String floraId;
  final FloraKind kind;
  final Offset position;
  final double growth;
}

class MoodEnvironmentState {
  const MoodEnvironmentState({
    required this.skyTop,
    required this.skyBottom,
    required this.sea,
    required this.sunIntensity,
    required this.cloudDensity,
    required this.windStrength,
    required this.waveIntensity,
    required this.particlePreset,
    required this.rain,
    required this.colorGrade,
    this.ambientAudio,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sea;
  final double sunIntensity;
  final double cloudDensity;
  final double windStrength;
  final double waveIntensity;
  final String particlePreset;
  final bool rain;
  final ColorGrade colorGrade;
  final String? ambientAudio;

  factory MoodEnvironmentState.fallback(CharacterMood mood, MoodIslandConfig style) {
    return MoodEnvironmentState(
      skyTop: style.skyTop,
      skyBottom: style.skyBottom,
      sea: style.sea,
      sunIntensity: mood == CharacterMood.happy ? 0.9 : 0.55,
      cloudDensity: mood == CharacterMood.anxious ? 0.75 : 0.35,
      windStrength: style.wind ? 0.8 : 0.25,
      waveIntensity: style.waveIntensity,
      particlePreset: style.ambientParticles,
      rain: style.rain,
      colorGrade: ColorGradeX.forMood(mood),
      ambientAudio: null,
    );
  }
}

enum ColorGrade { warm, cool, neutral, golden }

extension ColorGradeX on ColorGrade {
  static ColorGrade forMood(CharacterMood mood) => switch (mood) {
        CharacterMood.happy => ColorGrade.warm,
        CharacterMood.anxious => ColorGrade.cool,
        CharacterMood.proud => ColorGrade.golden,
        _ => ColorGrade.neutral,
      };
}
