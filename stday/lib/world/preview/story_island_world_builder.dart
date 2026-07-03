import 'dart:math';
import 'dart:ui';

import '../../core/constants/emotion_catalog.dart'
    show defaultEmotionId, effectiveEmotionIdForMoment, emotionById;
import '../../core/models/character_mood.dart';
import '../../core/constants/story_island_layout.dart';
import '../../data/models/profile_models.dart';
import '../../data/models/story_island_models.dart';
import '../engine/world_state.dart';

/// 从 [WorldState] 基座构建故事岛预览/详情用快照。
class StoryIslandWorldBuilder {
  const StoryIslandWorldBuilder._();

  static WorldState cardPreview({
    required WorldState base,
    required StoryIslandModel island,
    String? moodId,
    required int userTitleLevel,
  }) {
    final mood = CharacterMood.fromString(
      emotionById(moodId ?? defaultEmotionId).legacyMoodId,
    );
    return WorldState(
      island: base.island,
      characters: [
        CharacterSnapshot(
          id: 'story_island_card_companion_${island.id}',
          mood: mood,
          level: max(1, island.currentLevel),
          accessoryIds: const [],
          animationKey: 'idle',
          normalizedPos: const Offset(0.52, 0.54),
          expression: mood.name,
          companionPose: 'breathing',
          scale: _companionScale(island.sizeKind),
        ),
      ],
      buildings: _cardBuildings(island),
      flora: const [],
      environment: base.environment,
      zones: const [],
      decorations: const [],
      paths: const [],
      effects: const [],
      anchors: [
        WorldAnchorSnapshot(
          id: 'story_island_card_${island.id}',
          type: 'story_island',
          position: const Offset(0.5, 0.5),
          visualWeight: 0,
          cameraFocus: false,
        ),
      ],
      companionGender: base.companionGender,
      schemaVersion: base.schemaVersion,
    );
  }

  /// 首页世界地图：仅最高等级建筑（缩小），无角色。
  static WorldState homeMapPreview({
    required WorldState base,
    required StoryIslandModel island,
  }) {
    final previewIsland = IslandState(
      shapeKey: base.island.shapeKey,
      style: base.island.style,
      elevation: base.island.elevation,
      prosperityTier: base.island.prosperityTier,
      radius: 0.78,
    );
    return WorldState(
      island: previewIsland,
      characters: const [],
      buildings: _homeMapBuildings(island),
      flora: const [],
      environment: base.environment,
      zones: const [],
      decorations: const [],
      paths: const [],
      effects: const [],
      anchors: [
        WorldAnchorSnapshot(
          id: 'story_island_map_${island.id}',
          type: 'story_island',
          position: const Offset(0.5, 0.5),
          visualWeight: 0,
          cameraFocus: false,
        ),
      ],
      companionGender: base.companionGender,
      schemaVersion: base.schemaVersion,
    );
  }

  static WorldState detail({
    required WorldState base,
    required StoryIslandModel island,
  }) {
    final env = base.environment.copyWith(
      sunY: (base.environment.sunY + 0.07).clamp(0.12, 0.32),
    );
    return WorldState(
      island: base.island,
      characters: base.characters,
      buildings: _detailBuildings(island),
      flora: const [],
      environment: env,
      zones: const [],
      decorations: const [],
      paths: const [],
      effects: base.effects,
      anchors: [
        ...base.anchors,
        WorldAnchorSnapshot(
          id: 'story_island_${island.id}',
          type: 'story_island',
          position: const Offset(0.5, 0.5),
          visualWeight: 0,
          cameraFocus: false,
        ),
      ],
      companionGender: base.companionGender,
      schemaVersion: base.schemaVersion,
    );
  }

  static String? dominantMoodForIsland(
    List<DailyMomentModel> moments,
    String islandId,
  ) {
    final counts = <String, int>{};
    for (final moment in moments) {
      final id = moment.storyIslandId ??
          moment.visualPayload['story_island_id'] as String?;
      if (id != islandId) continue;
      final moodId = effectiveEmotionIdForMoment(moment);
      counts[moodId] = (counts[moodId] ?? 0) + 1;
    }
    String? best;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  static List<BuildingSnapshot> _detailBuildings(StoryIslandModel island) {
    final out = <BuildingSnapshot>[];
    for (final level in island.progressionPlan) {
      if (!level.unlocked) continue;
      final lv = level.level.clamp(1, 10);
      out.add(
        BuildingSnapshot(
          definitionId:
              'story_island_${island.id}_lv${lv.toString().padLeft(2, '0')}',
          level: lv,
          anchor: StoryIslandLayout.buildingAnchorForLevel(level),
          type: 'story_${level.ring}',
          size: StoryIslandLayout.buildingSize(level),
          sprite:
              'islands/${island.categoryId}/buildings/lv${lv.toString().padLeft(2, '0')}.png',
          displayName: level.buildingType,
          unlockLevel: lv,
          unlockedAt: level.unlockedAt,
        ),
      );
    }
    return out..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
  }

  static List<BuildingSnapshot> _cardBuildings(StoryIslandModel island) {
    final out = <BuildingSnapshot>[];
    for (final level in island.progressionPlan) {
      if (!level.unlocked) continue;
      final lv = level.level.clamp(1, 10);
      out.add(
        BuildingSnapshot(
          definitionId:
              'story_island_card_${island.id}_lv${lv.toString().padLeft(2, '0')}',
          level: lv,
          anchor: StoryIslandLayout.buildingAnchorForLevel(level),
          type: 'story_${level.ring}',
          size: StoryIslandLayout.buildingSize(level),
          sprite:
              'islands/${island.categoryId}/buildings/lv${lv.toString().padLeft(2, '0')}.png',
          displayName: level.buildingType,
          unlockLevel: lv,
          unlockedAt: level.unlockedAt,
        ),
      );
    }
    return out..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
  }

  static List<BuildingSnapshot> _homeMapBuildings(StoryIslandModel island) {
    StoryIslandProgressLevelModel? best;
    for (final level in island.progressionPlan) {
      if (!level.unlocked) continue;
      if (best == null || level.level > best.level) {
        best = level;
      }
    }
    if (best == null) return const [];

    final lv = best.level.clamp(1, 10);
    final baseSize = StoryIslandLayout.buildingSize(best);
    final scaled = Offset(
      baseSize.dx * StoryIslandLayout.homeMapBuildingScale,
      baseSize.dy * StoryIslandLayout.homeMapBuildingScale,
    );
    return [
      BuildingSnapshot(
        definitionId:
            'story_island_map_${island.id}_lv${lv.toString().padLeft(2, '0')}',
        level: lv,
        anchor: const Offset(0.50, 0.57),
        type: 'story_${best.ring}',
        size: scaled,
        sprite:
            'islands/${island.categoryId}/buildings/lv${lv.toString().padLeft(2, '0')}.png',
        displayName: best.buildingType,
        unlockLevel: lv,
        unlockedAt: best.unlockedAt,
      ),
    ];
  }

  static double _companionScale(String sizeKind) {
    return switch (sizeKind) {
      'small' => 0.78,
      'medium' => 0.92,
      'large' => 1.08,
      _ => 0.9,
    };
  }
}
