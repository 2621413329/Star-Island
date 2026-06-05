import 'dart:ui';

import '../../core/models/character_mood.dart';
import '../../core/models/mood_island_config.dart';
import '../systems/building_system.dart';
import '../systems/mood_environment_controller.dart';
import 'growth_event.dart';
import 'growth_world_input.dart';
import 'world_state.dart';

class GrowthWorldEngine {
  GrowthWorldEngine({
    BuildingSystem? buildingSystem,
    MoodEnvironmentController? environmentController,
  })  : _buildingSystem = buildingSystem ?? BuildingSystem(),
        _environmentController =
            environmentController ?? MoodEnvironmentController();

  final BuildingSystem _buildingSystem;
  final MoodEnvironmentController _environmentController;

  WorldState build(GrowthWorldInput input) {
    final style = input.islandStyle;
    final environment = _environmentController.compute(input.mood, style);
    final buildings = _buildingSystem.resolveForIsland(
      moodId: style.moodId,
      storyCount: input.events.length,
    );
    final flora = _buildFlora(style, input.mood, buildings.length);
    final characters = _buildCharacters(input);

    return WorldState(
      island: IslandState(
        shapeKey: style.islandShape,
        style: style,
        elevation: input.compact ? 0.11 : 0.14,
      ),
      characters: characters,
      buildings: buildings,
      flora: flora,
      environment: environment,
      companionGender: input.companionGender,
    );
  }

  List<CharacterSnapshot> _buildCharacters(GrowthWorldInput input) {
    // 今日故事会直接长成岛上的居民：记录越多，岛上居民越多。
    // compact 场景保留上限，避免缩小时拥挤。
    final maxResidents = input.compact ? 8 : 15;
    final events = input.events.take(maxResidents).toList();
    if (events.isEmpty) {
      return [
        CharacterSnapshot(
          id: 'resident-calm-a',
          mood: input.mood,
          level: input.profile.worldLevel,
          accessoryIds: const [],
          animationKey: 'float',
          normalizedPos: const Offset(0.38, 0.6),
          expression: input.mood == CharacterMood.happy ? 'happy' : 'calm',
          prop: 'none',
          motion: _motionForMood(input.mood, compact: input.compact),
          scale: input.compact ? 0.78 : 0.86,
        ),
        CharacterSnapshot(
          id: 'resident-calm-b',
          mood: input.mood,
          level: input.profile.worldLevel,
          accessoryIds: const [],
          animationKey: 'wave',
          normalizedPos: const Offset(0.62, 0.58),
          expression: 'calm',
          prop: 'none',
          motion: _motionForMood(input.mood, compact: input.compact),
          scale: input.compact ? 0.72 : 0.82,
        ),
      ];
    }

    final slots = _characterSlots(events.length);
    return List.generate(events.length, (i) {
      final e = events[i];
      return CharacterSnapshot(
        id: 'resident-${e.id}',
        mood: e.mood,
        level: 1,
        accessoryIds: const [],
        animationKey: e.animationKey,
        normalizedPos: slots[i],
        expression: e.expression,
        prop: e.prop,
        companionScene: e.companionScene,
        companionPose: e.companionPose,
        linkedEventId: e.id,
        tintHex: e.tintHex,
        motion: _motionForMood(e.mood, compact: input.compact),
        scale: _scaleForEvent(e,
            index: i, total: events.length, compact: input.compact),
      );
    });
  }

  double _scaleForEvent(
    GrowthEvent event, {
    required int index,
    required int total,
    required bool compact,
  }) {
    final noteLength = event.note?.trim().length ?? 0;
    final richness = (noteLength / 80).clamp(0.0, 1.0);
    final tagBoost = (event.eventTags.length - 1).clamp(0, 3) * 0.03;
    final recencyBoost = index == 0 ? 0.06 : 0.0;
    final crowd = _crowdScaleFactor(total, compact);
    final base = (compact ? 0.74 : 0.86) * crowd;
    return (base + richness * 0.12 + tagBoost + recencyBoost)
        .clamp(compact ? 0.48 : 0.52, compact ? 0.92 : 1.0)
        .toDouble();
  }

  double _crowdScaleFactor(int total, bool compact) {
    if (total <= 1) return 1.0;
    if (total <= 4) return compact ? 0.92 : 0.96;
    if (total <= 8) return compact ? 0.84 : 0.88;
    if (total <= 12) return compact ? 0.74 : 0.78;
    return compact ? 0.66 : 0.70;
  }

  List<FloraSnapshot> _buildFlora(
      MoodIslandConfig style, CharacterMood mood, int buildingCount) {
    // 先取消散落小配饰，避免树/草在不同岛型上悬空或破坏简洁高级感。
    return const [];
  }

  List<Offset> _characterSlots(int n) {
    if (n <= 0) return [];
    const residentSlots = [
      Offset(0.50, 0.68),
      Offset(0.40, 0.66),
      Offset(0.60, 0.66),
      Offset(0.32, 0.64),
      Offset(0.68, 0.64),
      Offset(0.24, 0.60),
      Offset(0.76, 0.60),
      Offset(0.44, 0.58),
      Offset(0.56, 0.58),
      Offset(0.36, 0.54),
      Offset(0.64, 0.54),
      Offset(0.28, 0.52),
      Offset(0.72, 0.52),
      Offset(0.48, 0.50),
      Offset(0.58, 0.50),
    ];
    return residentSlots.take(n).toList();
  }

  CharacterMotion _motionForMood(CharacterMood mood, {required bool compact}) {
    final baseWander = compact ? 2.8 : 4.6;
    return switch (mood) {
      CharacterMood.happy => CharacterMotion(
          bobAmplitude: compact ? 1.8 : 2.6,
          wanderRadius: baseWander + 0.9,
          wanderSpeed: 0.42,
        ),
      CharacterMood.anxious => CharacterMotion(
          bobAmplitude: compact ? 1.4 : 2.0,
          wanderRadius: baseWander + 1.2,
          wanderSpeed: 0.5,
        ),
      CharacterMood.angry => CharacterMotion(
          bobAmplitude: compact ? 1.5 : 2.1,
          wanderRadius: baseWander + 1.0,
          wanderSpeed: 0.48,
        ),
      CharacterMood.proud => CharacterMotion(
          bobAmplitude: compact ? 1.6 : 2.2,
          wanderRadius: baseWander + 0.4,
          wanderSpeed: 0.36,
        ),
      CharacterMood.calm => CharacterMotion(
          bobAmplitude: compact ? 1.2 : 1.8,
          wanderRadius: baseWander,
          wanderSpeed: 0.32,
        ),
    };
  }
}
