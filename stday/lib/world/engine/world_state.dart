import 'dart:ui';

import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';
import '../../island/config/day_phase_lighting_config.dart';

class WorldState {
  const WorldState({
    required this.island,
    required this.characters,
    required this.buildings,
    required this.flora,
    required this.environment,
    this.zones = const [],
    this.decorations = const [],
    this.paths = const [],
    this.effects = const [],
    this.anchors = const [],
    this.companionGender,
    this.schemaVersion = 1,
  });

  final IslandState island;
  final List<CharacterSnapshot> characters;
  final List<BuildingSnapshot> buildings;
  final List<FloraSnapshot> flora;
  final MoodEnvironmentState environment;
  final List<ZoneSnapshot> zones;
  final List<DecorationSnapshot> decorations;
  final List<PathSnapshot> paths;
  final List<EffectSnapshot> effects;
  final List<WorldAnchorSnapshot> anchors;
  final String? companionGender;
  final int schemaVersion;

  static WorldState empty(MoodIslandConfig style) => WorldState(
        island: IslandState(
            shapeKey: style.islandShape, style: style, elevation: 0.045),
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
    this.prosperityTier = 0,
    this.radius = 1,
  });

  final String shapeKey;
  final MoodIslandConfig style;
  final double elevation;

  /// 0–5：荒芜 → 完整成长世界（纵向繁荣，与 mood 无关）。
  final int prosperityTier;
  final double radius;
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
    this.extraProps = const [],
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
  final List<String> extraProps;
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
    this.zone,
    this.type = 'landmark',
    this.size = const Offset(0.12, 0.12),
    this.sprite,
    this.animation = 'idle',
    this.interactionType = 'inspect',
    this.playUnlockFx = false,
    this.displayName,
    this.unlockLevel,
    this.unlockedAt,
  });

  final String definitionId;
  final int level;
  final Offset anchor;
  final String? zone;
  final String type;
  final Offset size;
  final String? sprite;
  final String animation;
  final String interactionType;
  final bool playUnlockFx;
  final String? displayName;
  final int? unlockLevel;
  final DateTime? unlockedAt;
}

enum FloraKind { tree, flower, bush, grass }

class FloraSnapshot {
  const FloraSnapshot({
    required this.floraId,
    required this.kind,
    required this.position,
    required this.growth,
    this.zone,
    this.asset,
    this.animation = 'idle',
    this.rotation = 0,
  });

  final String floraId;
  final FloraKind kind;
  final Offset position;
  final double growth;
  final String? zone;
  final String? asset;
  final String animation;
  final double rotation;
}

class ZoneSnapshot {
  const ZoneSnapshot({
    required this.id,
    required this.name,
    required this.priority,
    required this.bounds,
  });

  final String id;
  final String name;
  final int priority;
  final Rect bounds;
}

class DecorationSnapshot {
  const DecorationSnapshot({
    required this.id,
    required this.configId,
    required this.type,
    required this.zone,
    required this.position,
    required this.asset,
    required this.animation,
    required this.scale,
    required this.rotation,
  });

  final String id;
  final String configId;
  final String type;
  final String zone;
  final Offset position;
  final String asset;
  final String animation;
  final double scale;
  final double rotation;
}

class PathSnapshot {
  const PathSnapshot({
    required this.id,
    required this.start,
    required this.end,
    required this.pathType,
    required this.width,
  });

  final String id;
  final Offset start;
  final Offset end;
  final String pathType;
  final double width;
}

class EffectSnapshot {
  const EffectSnapshot({
    required this.id,
    required this.type,
    required this.anchor,
    this.intensity = 1,
  });

  final String id;
  final String type;
  final Offset anchor;
  final double intensity;
}

class WorldAnchorSnapshot {
  const WorldAnchorSnapshot({
    required this.id,
    required this.type,
    required this.position,
    required this.visualWeight,
    required this.cameraFocus,
  });

  final String id;
  final String type;
  final Offset position;
  final double visualWeight;
  final bool cameraFocus;
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
    this.lifePreset = 'breeze',
    this.fogOpacity = 0,
    this.ambientAudio,
    this.dayPhase = DayPhase.noon,
    this.sunX = 0.5,
    this.sunY = 0.14,
    this.shadowDx = 0.02,
    this.shadowDy = 0.10,
    this.shadowStretch = 0.92,
    this.shadowAlpha = 0.16,
    this.lightWarmth = 0.35,
    this.ambientShadeStrength = 0.18,
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
  final String lifePreset;
  final double fogOpacity;
  final String? ambientAudio;

  /// 当前时段与光照参数（早 / 中 / 晚）。
  final DayPhase dayPhase;
  final double sunX;
  final double sunY;
  final double shadowDx;
  final double shadowDy;
  final double shadowStretch;
  final double shadowAlpha;
  final double lightWarmth;
  final double ambientShadeStrength;

  Offset get lightDirection {
    final len = (Offset(sunX - 0.5, sunY - 0.5)).distance;
    if (len < 0.001) return const Offset(0, -1);
    return Offset((sunX - 0.5) / len, (sunY - 0.5) / len);
  }

  factory MoodEnvironmentState.fallback(
      CharacterMood mood, MoodIslandConfig style) {
    final phase = resolveDayPhase();
    final lighting = DayPhaseLightingPreset.forPhase(phase);
    return MoodEnvironmentState(
      skyTop: lighting.skyTop,
      skyBottom: lighting.skyBottom,
      sea: style.sea,
      sunIntensity: mood == CharacterMood.happy
          ? lighting.sunIntensity
          : lighting.sunIntensity * 0.72,
      cloudDensity: mood == CharacterMood.anxious ? 0.75 : 0.35,
      windStrength: style.wind ? 0.8 : 0.25,
      waveIntensity: style.waveIntensity,
      particlePreset: style.ambientParticles,
      rain: style.rain,
      colorGrade: ColorGradeX.forMood(mood),
      lifePreset: 'breeze',
      fogOpacity: 0,
      ambientAudio: null,
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
