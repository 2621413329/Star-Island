import 'dart:math' as math;
import 'dart:ui';

import 'story_island_size.dart';
import '../../data/models/story_island_models.dart';
import '../../world/island/island_placement.dart';

/// 副岛建筑布局与缩放（不影响主岛 [IslandBuildingLayout]）。
abstract final class StoryIslandLayout {
  /// 副岛详情页视口缩放（主岛详情仍用默认 1.0）。
  static const detailViewportScale = 1.58;

  /// 群岛地图单建筑预览相对详情尺寸。
  static const homeMapBuildingScale = 0.44;

  /// 成长值在 10 个等级间均匀分布，每级 30。
  static const growthPerLevel = storyIslandGrowthPerLevel;

  /// 建筑满级累计成长值。
  static const maxLevelGrowth = storyIslandMaxLevelGrowth;

  /// 与主岛详情默认半径对齐，保证环带落在可视岛面内。
  static const detailIslandRadius = 0.82;

  static const _anchorCenter = IslandPlacement.center;

  /// 环带半径（单位椭圆 0~1）：outer → middle → inner，留足 footprint 边距。
  static const _ringUnitRadii = [0.70, 0.46, 0.26];
  static const _ringAngleOffset = [0.0, 0.55, 1.10];

  /// 按环带在岛上均匀分布 10 个建筑锚点（outer → center）。
  ///
  /// 使用与主岛一致的成长岛椭圆，避免圆形环带把建筑推到水面外。
  static Offset buildingAnchor(
    int level, {
    double islandRadius = detailIslandRadius,
  }) {
    final lv = level.clamp(1, 10);
    if (lv == 10) return _anchorCenter;

    final ringIndex = (lv - 1) ~/ 3;
    final slotInRing = (lv - 1) % 3;
    final unitRadius =
        _ringUnitRadii[ringIndex.clamp(0, _ringUnitRadii.length - 1)];
    final angle =
        _ringAngleOffset[ringIndex.clamp(0, _ringAngleOffset.length - 1)] +
            slotInRing * (2 * math.pi / 3);
    final anchor = IslandPlacement.fromEllipseUnit(
      math.cos(angle) * unitRadius,
      math.sin(angle) * unitRadius,
      inset: 0.88,
      islandRadius: islandRadius,
    );
    return IslandPlacement.clampToGrowthIsland(
      anchor,
      inset: 0.86,
      islandRadius: islandRadius,
    );
  }

  static Offset buildingAnchorForLevel(StoryIslandProgressLevelModel level) =>
      buildingAnchor(level.level);

  static Offset buildingSizeForRing(String ring) {
    final base = switch (ring) {
      'outer' => 0.09,
      'middle' => 0.11,
      'inner' => 0.12,
      'center' => 0.14,
      _ => 0.10,
    };
    return Offset(base, base);
  }

  static Offset buildingSize(StoryIslandProgressLevelModel level) =>
      buildingSizeForRing(level.ring);

  static double cardPreviewZoom(String sizeKind) {
    return switch (sizeKind) {
      'small' => 1.02,
      'medium' => 1.18,
      'large' => 1.32,
      _ => 1.12,
    };
  }

  static double mapPreviewZoom(String sizeKind) {
    return switch (sizeKind) {
      'small' => 0.88,
      'medium' => 0.96,
      'large' => 1.04,
      _ => 0.92,
    };
  }
}
