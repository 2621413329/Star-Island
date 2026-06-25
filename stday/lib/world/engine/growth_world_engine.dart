import 'dart:ui';

import '../../core/models/character_mood.dart';
import '../../core/utils/companion_base_expression.dart';
import '../../world/behaviors/protagonist_behavior.dart';
import '../../island/config/island_visual_config.dart';
import '../systems/building_system.dart';
import '../systems/mood_environment_controller.dart';
import '../systems/prosperity_system.dart';
import 'growth_world_input.dart';
import 'world_state.dart';

class GrowthWorldEngine {
  GrowthWorldEngine({
    BuildingSystem? buildingSystem,
    MoodEnvironmentController? environmentController,
    ProsperitySystem? prosperitySystem,
  })  : _buildingSystem = buildingSystem ?? BuildingSystem(),
        _environmentController =
            environmentController ?? const MoodEnvironmentController(),
        _prosperitySystem = prosperitySystem ?? const ProsperitySystem();

  final BuildingSystem _buildingSystem;
  final MoodEnvironmentController _environmentController;
  final ProsperitySystem _prosperitySystem;

  static const _legacyCharacterStages = [
    (
      minLevel: 1,
      compactScale: 0.74,
      regularScale: 0.84,
      expression: null,
      prop: 'none'
    ),
    (
      minLevel: 4,
      compactScale: 0.78,
      regularScale: 0.88,
      expression: null,
      prop: 'none'
    ),
    (
      minLevel: 7,
      compactScale: 0.82,
      regularScale: 0.92,
      expression: 'xing_fen',
      prop: 'none'
    ),
  ];

  WorldState build(GrowthWorldInput input) {
    final style = input.islandStyle;
    final prosperityTier = _prosperitySystem.tierFromSummaryLevel(
      input.protagonistLevel,
    );
    final environment = _environmentController.compute(
      input.mood,
      moodId: style.moodId,
      weather: input.weather,
    );
    // Visual Prototype 阶段暂停建筑系统：Growth World 只保留中心成长树。
    final buildings = style.biome == IslandVisualConfig.fixedBiome
        ? const <BuildingSnapshot>[]
        : _buildingSystem.resolveForIsland(
            moodId: style.moodId,
            storyCount: input.events.length,
          );
    final flora =
        _prosperitySystem.resolveFlora(prosperityTier: prosperityTier);
    final characters = _buildCharacters(input);

    return WorldState(
      island: IslandState(
        shapeKey: IslandVisualConfig.fixedShapeKey,
        style: style,
        elevation: style.biome == IslandVisualConfig.fixedBiome
            ? (input.compact ? 0.004 : 0.006)
            : input.compact
                ? 0.09 + prosperityTier * 0.004
                : 0.10 + prosperityTier * 0.006,
        prosperityTier: prosperityTier,
        radius: style.biome == IslandVisualConfig.fixedBiome ? 1.14 : 1,
      ),
      characters: characters,
      buildings: buildings,
      flora: flora,
      environment: environment,
      companionGender: input.companionGender,
    );
  }

  List<CharacterSnapshot> _buildCharacters(GrowthWorldInput input) {
    final level = input.protagonistLevel;
    final stage = _legacyCharacterStages.lastWhere(
      (stage) => level >= stage.minLevel,
      orElse: () => _legacyCharacterStages.first,
    );
    final expression = companionBaseExpressionFromMood(
      input.mood,
      moodId: input.moodId,
    );
    final scale = input.compact ? stage.compactScale : stage.regularScale;

    return [
      CharacterSnapshot(
        id: 'protagonist',
        mood: input.mood,
        level: level,
        accessoryIds: const [],
        animationKey: 'float',
        normalizedPos: ProtagonistBehavior.defaultBase,
        expression: expression,
        prop: 'none',
        motion: _motionForMood(input.mood, compact: input.compact),
        scale: scale,
      ),
    ];
  }

  CharacterMotion _motionForMood(CharacterMood mood, {required bool compact}) {
    final baseWander = compact ? 2.2 : 3.8;
    return switch (mood) {
      CharacterMood.happy => CharacterMotion(
          bobAmplitude: compact ? 1.8 : 2.4,
          wanderRadius: baseWander + 0.6,
          wanderSpeed: 0.28,
        ),
      CharacterMood.anxious => CharacterMotion(
          bobAmplitude: compact ? 1.2 : 1.6,
          wanderRadius: baseWander + 0.3,
          wanderSpeed: 0.22,
        ),
      CharacterMood.angry => CharacterMotion(
          bobAmplitude: compact ? 1.3 : 1.7,
          wanderRadius: baseWander + 0.4,
          wanderSpeed: 0.24,
        ),
      CharacterMood.proud => CharacterMotion(
          bobAmplitude: compact ? 1.5 : 2.0,
          wanderRadius: baseWander + 0.2,
          wanderSpeed: 0.2,
        ),
      CharacterMood.calm => CharacterMotion(
          bobAmplitude: compact ? 1.0 : 1.4,
          wanderRadius: baseWander,
          wanderSpeed: 0.18,
        ),
    };
  }
}
