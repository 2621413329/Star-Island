import 'dart:ui';

import '../../world/island/island_placement.dart';
import '../config/growth_island_config_models.dart';
import '../config/island_visual_config.dart';
import 'building_sprite_metrics.dart';

/// 建筑在岛面上的归一化占地（宽 × 高），随岛屿半径等比缩放。
///
/// 宽度由 [BuildingSpriteMetrics] 统一宽高比推导，避免 PNG 独立拉伸变形。
/// [Offset.dy] = 高度系数（渲染时 × 280）；[Offset.dx] = 等比宽度系数。
class BuildingFootprint {
  BuildingFootprint._();

  static const _baseRadius = IslandVisualConfig.baseIslandRadius;
  static const _globalDisplayScale = 0.72;
  static const _academyDisplayScale = 0.72;
  static const academyVisualRenderBoost = 5.0;
  static const _groundFacilityScale = 0.72;
  static const _pierDisplayScale = 0.92;
  static const _slenderLandmarkScale = 0.70;

  static Offset resolve(BuildingConfig config, {required double islandRadius}) {
    final baseHeight = _baseHeight(config);
    final islandScale = (islandRadius / _baseRadius).clamp(0.85, 1.35);
    final displayScale = _displayScaleFor(config);
    final height = baseHeight * islandScale * displayScale;
    final width = BuildingSpriteMetrics.uniformSize(
          buildingId: config.id,
          targetHeight: baseHeight,
        ).width *
        islandScale *
        displayScale;
    return Offset(width, height);
  }

  static double _displayScaleFor(BuildingConfig config) {
    return switch (config.type) {
      'academy' => _academyDisplayScale,
      'pier' => _pierDisplayScale,
      'plaza' || 'flowerbed' => _groundFacilityScale,
      'lighthouse' || 'clocktower' || 'observatory' => _slenderLandmarkScale,
      _ => _globalDisplayScale,
    };
  }

  /// footprint 边缘采样点是否均在成长岛面内（含宽×0.5 安全距）。
  static bool isFullyOnGrowthIsland(
    Offset anchor,
    Offset footprint, {
    double inset = 0.86,
  }) {
    if (!IslandPlacement.isOnGrowthIslandBuildingSurface(anchor,
        inset: inset)) {
      return false;
    }
    final rect = edgeBoundsRect(anchor, footprint);
    final samples = <Offset>[
      anchor,
      Offset(rect.left, anchor.dy),
      Offset(rect.right, anchor.dy),
    ];
    for (final point in samples) {
      if (!IslandPlacement.isOnGrowthIslandBuildingSurface(
        point,
        inset: inset - 0.02,
      )) {
        return false;
      }
    }
    return true;
  }

  static Rect edgeBoundsRect(Offset anchor, Offset footprint) {
    final w = footprint.dx * 0.90;
    final h = footprint.dy * 0.68;
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy - footprint.dy * 0.34),
      width: w,
      height: h,
    );
  }

  static double _baseHeight(BuildingConfig config) {
    return switch (config.id) {
      'lighthouse' => 0.42,
      'growth_clocktower' => 0.34,
      'dream_observatory' => 0.30,
      'growth_academy' => 0.42,
      'lighthouse_base' => 0.26,
      'growth_house_lv2' => 0.24,
      'growth_house' => 0.21,
      'library_seed' || 'memory_gallery' => 0.22,
      'record_shed' || 'quiet_tent' => 0.18,
      'memory_fountain' => 0.17,
      'emotion_windchime' => 0.20,
      'starter_stone' => 0.11,
      'memory_mailbox' => 0.13,
      'harbor_pier' => 0.18,
      'story_plaza' || 'companion_plaza' => 0.10,
      'habit_flowerbed' => 0.11,
      _ => _heightForType(config.type, config.upgradeLevel),
    };
  }

  static double _heightForType(String type, int upgradeLevel) {
    return switch (type) {
      'lighthouse' => 0.42,
      'lighthouse_base' => 0.26,
      'clocktower' => 0.34,
      'observatory' => 0.30,
      'academy' => 0.34,
      'house' => 0.20 + upgradeLevel * 0.02,
      'library' || 'gallery' => 0.22,
      'fountain' => 0.17,
      'shed' || 'tent' => 0.18,
      'windchime' => 0.20,
      'pier' => 0.12,
      'plaza' => 0.10,
      'flowerbed' => 0.11,
      'mailbox' => 0.13,
      'stone' => 0.11,
      _ => 0.18,
    };
  }
}
