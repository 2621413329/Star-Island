import 'dart:ui';

import '../../world/island/island_placement.dart';
import '../config/growth_island_config_models.dart';
import '../config/island_visual_config.dart';
import 'building_depth_scale.dart';
import 'building_sprite_metrics.dart';

/// 建筑在岛面上的归一化占地（宽 × 高），随岛屿半径等比缩放。
///
/// 宽度由 [BuildingSpriteMetrics] 统一宽高比推导，避免 PNG 独立拉伸变形。
/// [Offset.dy] = 高度系数（渲染时 × 280）；[Offset.dx] = 等比宽度系数。
class BuildingFootprint {
  BuildingFootprint._();

  static const _baseRadius = IslandVisualConfig.baseIslandRadius;
  /// 非学院建筑再收，降低立面重叠概率。
  static const _globalDisplayScale = 0.64;
  static const _academyDisplayScale = 0.70;
  /// 学院屏幕体量：碰撞占地克制，渲染单独放大。
  static const academyVisualRenderBoost = 5.6;
  static const _groundFacilityScale = 0.66;
  /// 栈桥碰撞占地保持克制；屏幕体量由 [pierVisualRenderBoost] 放大。
  static const _pierDisplayScale = 0.78;
  static const pierVisualRenderBoost = 2.5;
  static const _slenderLandmarkScale = 0.62;

  /// 与 [building_layer] 渲染放大一致。
  static double visualRenderBoostFor(String buildingId) {
    return switch (buildingId) {
      'growth_academy' => academyVisualRenderBoost,
      'harbor_pier' => pierVisualRenderBoost,
      _ => 1.0,
    };
  }

  /// 碰撞用视觉放大：对齐「屏幕封顶后的建筑主体」，不是整张放大 PNG 的透明包围盒。
  ///
  /// 学院/栈桥会先 ×boost 再被视口高度封顶；碰撞只取主体立面，避免占满岛面
  /// 导致其余建筑全部挤到同一备用点。
  static double visualCollisionWidthBoostFor(String buildingId) {
    final boost = visualRenderBoostFor(buildingId);
    if (boost <= 1.0) return 1.0;
    return switch (buildingId) {
      // footprint 本身已偏宽，主体再略收，封顶放大主要体现在高度。
      'growth_academy' => 0.82,
      'harbor_pier' => 1.20,
      _ => boost,
    };
  }

  static double visualCollisionHeightBoostFor(String buildingId) {
    final boost = visualRenderBoostFor(buildingId);
    if (boost <= 1.0) return 1.0;
    return switch (buildingId) {
      'growth_academy' => 1.35,
      'harbor_pier' => 0.70,
      _ => 1.0 + (boost - 1.0) * 0.55,
    };
  }

  /// 放大后用于建筑间防重叠的 footprint（主体尺寸）。
  static Offset visualCollisionFootprint(
    String buildingId,
    Offset footprint,
  ) {
    final w = visualCollisionWidthBoostFor(buildingId);
    final h = visualCollisionHeightBoostFor(buildingId);
    if ((w - 1.0).abs() < 0.001 && (h - 1.0).abs() < 0.001) {
      return footprint;
    }
    return Offset(footprint.dx * w, footprint.dy * h);
  }

  /// 放大 + 纵深缩放后的岛缘校验用 footprint（贴地主体，非整张透明包围盒）。
  static Offset visualEdgeFootprint(
    String buildingId,
    Offset footprint, {
    required double anchorDy,
  }) {
    final visual = visualCollisionFootprint(buildingId, footprint);
    final depth = BuildingDepthScale.forAnchorDy(anchorDy);
    return Offset(visual.dx * depth, visual.dy * depth);
  }

  /// 栈桥设计上探出河岸，不做「放大后仍全在岛面」校验。
  static bool skipsVisualEdgeCheck(String buildingId) {
    return buildingId == 'harbor_pier';
  }

  /// 放大后主体左右脚点是否仍落在成长岛面上。
  static bool isVisuallyOnGrowthIsland(
    Offset anchor,
    Offset footprint, {
    required String buildingId,
    double inset = 0.80,
    double islandRadius = 1.0,
  }) {
    if (skipsVisualEdgeCheck(buildingId)) return true;
    final edge = visualEdgeFootprint(
      buildingId,
      footprint,
      anchorDy: anchor.dy,
    );
    return isFullyOnGrowthIsland(
      anchor,
      edge,
      inset: inset,
      islandRadius: islandRadius,
    );
  }

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
    return switch (config.id) {
      // 花圃/喷泉单独放大，不吃地面设施整体收束。
      'habit_flowerbed' || 'memory_fountain' => 1.05,
      // 画廊与梦想观测台同档体量。
      'memory_gallery' => _slenderLandmarkScale,
      _ => switch (config.type) {
          'academy' => _academyDisplayScale,
          'pier' => _pierDisplayScale,
          'plaza' || 'flowerbed' => _groundFacilityScale,
          'lighthouse' ||
          'clocktower' ||
          'observatory' ||
          'gallery' =>
            _slenderLandmarkScale,
          _ => _globalDisplayScale,
        },
    };
  }

  /// footprint 贴地脚点是否均在成长岛面内（含宽×0.5 安全距）。
  ///
  /// 脚点使用真实岛面椭圆，不用 [buildingSurfaceVerticalScale] 拉伸，
  /// 避免建筑「站在水面外」。
  static bool isFullyOnGrowthIsland(
    Offset anchor,
    Offset footprint, {
    double inset = 0.82,
    double islandRadius = 1.0,
  }) {
    if (!IslandPlacement.isOnGrowthIsland(
      anchor,
      inset: inset,
      islandRadius: islandRadius,
    )) {
      return false;
    }
    final rect = edgeBoundsRect(anchor, footprint);
    final samples = <Offset>[
      Offset(rect.left, anchor.dy),
      Offset(rect.right, anchor.dy),
    ];
    for (final point in samples) {
      if (!IslandPlacement.isOnGrowthIsland(
        point,
        inset: (inset - 0.02).clamp(0.5, 1.0),
        islandRadius: islandRadius,
      )) {
        return false;
      }
    }
    return true;
  }

  static Rect edgeBoundsRect(Offset anchor, Offset footprint) {
    // 岛缘采样取贴地主体，避免透明包围盒把岸位误判出岛。
    final w = footprint.dx * 0.50;
    final h = footprint.dy * 0.42;
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy - footprint.dy * 0.22),
      width: w,
      height: h,
    );
  }

  static double _baseHeight(BuildingConfig config) {
    return switch (config.id) {
      'lighthouse' => 0.46,
      'growth_clocktower' => 0.38,
      'dream_observatory' => 0.34,
      'growth_academy' => 0.42,
      'lighthouse_base' => 0.30,
      'growth_house_lv2' => 0.28,
      'growth_house' => 0.26,
      'library_seed' => 0.26,
      // 与梦想观测台同高。
      'memory_gallery' => 0.34,
      'record_shed' || 'quiet_tent' => 0.22,
      // 记忆喷泉放大约一倍。
      'memory_fountain' => 0.44,
      'emotion_windchime' => 0.26,
      'starter_stone' => 0.14,
      'memory_mailbox' => 0.17,
      'harbor_pier' => 0.20,
      'story_plaza' || 'companion_plaza' => 0.12,
      // 习惯花圃放大约一倍。
      'habit_flowerbed' => 0.28,
      _ => _heightForType(config.type, config.upgradeLevel),
    };
  }

  static double _heightForType(String type, int upgradeLevel) {
    return switch (type) {
      'lighthouse' => 0.46,
      'lighthouse_base' => 0.30,
      'clocktower' => 0.38,
      'observatory' => 0.34,
      'academy' => 0.34,
      'house' => 0.26 + upgradeLevel * 0.02,
      'library' || 'gallery' => 0.28,
      'fountain' => 0.22,
      'shed' || 'tent' => 0.24,
      'windchime' => 0.26,
      'pier' => 0.12,
      'plaza' => 0.12,
      'flowerbed' => 0.14,
      'mailbox' => 0.17,
      'stone' => 0.14,
      _ => 0.22,
    };
  }
}
