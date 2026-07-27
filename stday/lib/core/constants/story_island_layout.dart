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

  /// 详情页建筑立面相对归一化 size 的视觉放大（贴地脚点仍受椭圆约束）。
  static const detailBuildingVisualScale = 1.65;

  /// 副岛详情小人站位：落在岛心略偏前的草面，避免沿用主岛前缘 (0.5, 0.625) 掉出岛缘。
  static const companionStandPos = Offset(0.50, 0.56);

  /// 成长值在 10 个等级间均匀分布，每级 30。
  static const growthPerLevel = storyIslandGrowthPerLevel;

  /// 建筑满级累计成长值。
  static const maxLevelGrowth = storyIslandMaxLevelGrowth;

  /// 与主岛详情默认半径对齐，保证环带落在可视岛面内。
  static const detailIslandRadius = 0.82;

  static const _anchorCenter = IslandPlacement.center;

  /// 环带半径（单位椭圆 0~1）：outer → middle → inner。
  /// 比旧值更靠内，给立面留高度，避免靠后建筑整栋画到岛缘外。
  static const _ringUnitRadii = [0.48, 0.32, 0.18];

  /// 外环偏向左/右/前，避开正后方（屏幕上方岛缘外）。
  static const _ringAngleOffset = [math.pi * 0.18, 0.72, 1.28];

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
    // 限制过深的后方落点（ny < 0 为屏幕上方），避免立面伸出岛外。
    final nx = math.cos(angle) * unitRadius;
    final ny = math.min(math.sin(angle) * unitRadius, 0.55);
    final backClampedNy = math.max(ny, -0.28);
    final anchor = IslandPlacement.fromEllipseUnit(
      nx,
      backClampedNy,
      inset: 0.78,
      islandRadius: islandRadius,
    );
    return IslandPlacement.clampToGrowthIsland(
      anchor,
      inset: 0.72,
      islandRadius: islandRadius,
    );
  }

  static Offset buildingAnchorForLevel(StoryIslandProgressLevelModel level) =>
      buildingAnchor(level.level);

  static Offset buildingSizeForRing(String ring) {
    final base = switch (ring) {
      'outer' => 0.15,
      'middle' => 0.17,
      'inner' => 0.185,
      'center' => 0.20,
      _ => 0.16,
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
