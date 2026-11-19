import 'dart:ui';

import 'story_island_size.dart';
import '../../data/models/story_island_models.dart';
import '../../world/island/painted_island_pits.dart';

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

  /// 副岛当前建筑的坑。1 级在前缘，10 级收到草地中心，同一时刻只放这一座。
  static Offset buildingAnchor(
    int level, {
    double islandRadius = detailIslandRadius,
  }) {
    return PaintedIslandPits.storyBuilding(level);
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
