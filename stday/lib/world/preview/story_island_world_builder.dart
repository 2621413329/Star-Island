import 'dart:math';
import 'dart:ui';

import '../../core/constants/emotion_catalog.dart'
    show defaultEmotionId, effectiveEmotionIdForMoment, emotionById;
import '../../core/models/character_mood.dart';
import '../../core/constants/story_island_layout.dart';
import '../../data/models/profile_models.dart';
import '../../data/models/story_island_models.dart';
import '../engine/world_state.dart';
import '../island/story_island_art.dart';
import 'story_island_building_icon.dart';

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
      island: _withPlate(base.island, island.categoryId),
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
    final previewIsland =
        _withPlate(base.island, island.categoryId, radius: 0.78);
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

  static IslandState _withPlate(
    IslandState base,
    String categoryId, {
    double? radius,
  }) {
    return IslandState(
      shapeKey: base.shapeKey,
      style: base.style,
      elevation: base.elevation,
      prosperityTier: base.prosperityTier,
      radius: radius ?? base.radius,
      plateKey: categoryId,
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
      island: _withPlate(base.island, island.categoryId),
      characters: _detailCharacters(base.characters),
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

  /// 副岛详情不沿用主岛前缘站位，避免小人脚点落到岛缘/水面外。
  static List<CharacterSnapshot> _detailCharacters(
    List<CharacterSnapshot> source,
  ) {
    if (source.isEmpty) return source;
    return [
      for (final c in source)
        CharacterSnapshot(
          id: c.id,
          mood: c.mood,
          level: c.level,
          accessoryIds: c.accessoryIds,
          animationKey: c.animationKey,
          normalizedPos: StoryIslandLayout.companionStandPos,
          expression: c.expression,
          prop: c.prop,
          extraProps: c.extraProps,
          companionScene: c.companionScene,
          companionPose: c.companionPose,
          linkedEventId: c.linkedEventId,
          tintHex: c.tintHex,
          motion: c.motion,
          scale: c.scale,
        ),
    ];
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
    return [
      _levelBuilding(island, idPrefix: 'story_island', playUnlockFx: true),
    ];
  }

  static List<BuildingSnapshot> _cardBuildings(StoryIslandModel island) {
    return [
      _levelBuilding(island, idPrefix: 'story_island_card'),
    ];
  }

  /// 建筑图跟着 [StoryIslandModel.currentLevel] 走。
  /// 写日常涨的等级不一定带 unlocked_at，不能再用解锁时间决定画哪一座。
  static BuildingSnapshot _levelBuilding(
    StoryIslandModel island, {
    required String idPrefix,
    bool playUnlockFx = false,
    double sizeScale = 1,
  }) {
    final lv = StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(island);
    final progress = _progressForLevel(island, lv);
    final ring = progress?.ring ?? 'outer';
    final base = progress == null
        ? StoryIslandLayout.buildingSizeForRing(ring)
        : StoryIslandLayout.buildingSize(progress);
    final padded = lv.toString().padLeft(2, '0');
    final category = StoryIslandArt.fileId(island.categoryId);
    return BuildingSnapshot(
      definitionId: '${idPrefix}_${island.id}_lv$padded',
      level: lv,
      anchor: StoryIslandLayout.buildingAnchor(lv),
      type: 'story_$ring',
      size: sizeScale == 1
          ? base
          : Offset(base.dx * sizeScale, base.dy * sizeScale),
      sprite: 'islands/$category/buildings/lv$padded.png',
      displayName: progress?.buildingType ?? '成长建筑',
      unlockLevel: lv,
      unlockedAt: progress?.unlockedAt,
      playUnlockFx: playUnlockFx,
    );
  }

  static StoryIslandProgressLevelModel? _progressForLevel(
    StoryIslandModel island,
    int level,
  ) {
    for (final item in island.progressionPlan) {
      if (item.level == level) return item;
    }
    if (island.progressionPlan.isEmpty) return null;
    final index = (level - 1).clamp(0, island.progressionPlan.length - 1);
    return island.progressionPlan[index];
  }

  static List<BuildingSnapshot> _homeMapBuildings(StoryIslandModel island) {
    return [
      _levelBuilding(
        island,
        idPrefix: 'story_island_map',
        sizeScale: StoryIslandLayout.homeMapBuildingScale,
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
