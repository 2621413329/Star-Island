import 'dart:math' as math;
import 'dart:ui';

import 'island_visual_config.dart';

/// 成长岛表面可放置区域的归一化约束（与 [IslandShapeProfile._growthWorldPath] 对齐）。
class IslandPlacement {
  IslandPlacement._();

  static const Offset center = Offset(0.5, 0.54);

  /// 与 [IslandShapeProfile._growthWorldPath] 非 compact 模式一致的岛面椭圆半轴。
  /// 调大此值可直接放大屏幕上的岛屿可视面积（勿仅用 engine radius 倍数，避免被视口裁切）。
  static const double growthRadiusX = 0.50;
  static const double growthRadiusY = 0.118;

  /// 旧装饰落点仍使用略小的保守椭圆。
  static const double radiusX = 0.37;
  static const double radiusY = 0.09;

  /// 建筑贴地校验用纵向拉伸，与成长岛顶面视觉（非 compact 略扁 + 上缘建筑带）对齐。
  static const double buildingSurfaceVerticalScale = 2.55;

  /// 与 [IslandShapeProfile.applyIslandRadiusScale] 一致的半径钳制。
  static double effectiveIslandRadius(double islandRadius) =>
      islandRadius.clamp(0.6, 1.05);

  /// 将按「满半径岛面」设计的锚点，收缩到当前 [islandRadius] 的可视岛内。
  ///
  /// 岛体渲染用 [applyIslandRadiusScale] 绕 [center] 缩放；固定落点若不做同样
  /// 收缩，会在低等级/缩小岛上落到水面外。
  static Offset scaleAnchorToRadius(
    Offset p, {
    required double islandRadius,
  }) {
    final scale = effectiveIslandRadius(islandRadius);
    if ((scale - 1.0).abs() < 0.001) return p;
    return Offset(
      center.dx + (p.dx - center.dx) * scale,
      center.dy + (p.dy - center.dy) * scale,
    );
  }

  /// 椭圆归一化坐标 → 岛面点（[nx]/[ny] 在单位圆内，0=中心，1=岛缘）。
  static Offset fromEllipseUnit(
    double nx,
    double ny, {
    double inset = 1.0,
    double islandRadius = 1.0,
  }) {
    final scale = effectiveIslandRadius(islandRadius);
    return Offset(
      center.dx + nx * growthRadiusX * inset * scale,
      center.dy + ny * growthRadiusY * inset * scale,
    );
  }

  /// 成长岛面椭圆内（[inset] 越小越靠中心）。
  ///
  /// [islandRadius] 须与渲染用 [IslandState.radius] 一致，否则装饰会落在可视岛外。
  static bool isOnGrowthIsland(
    Offset p, {
    double inset = 1.0,
    double islandRadius = 1.0,
  }) {
    final scale = effectiveIslandRadius(islandRadius);
    return _insideEllipse(
      p,
      rx: growthRadiusX * inset * scale,
      ry: growthRadiusY * inset * scale,
    );
  }

  /// 建筑 footprint 边缘是否落在可放置岛面（含上缘视觉扩展）。
  ///
  /// 仅用于立面上缘采样；贴地脚点请用 [isOnGrowthIsland]。
  static bool isOnGrowthIslandBuildingSurface(
    Offset p, {
    double inset = 0.86,
    double islandRadius = 1.0,
  }) {
    final scale = effectiveIslandRadius(islandRadius);
    return _insideEllipse(
      p,
      rx: growthRadiusX * inset * scale,
      ry: growthRadiusY * inset * scale * buildingSurfaceVerticalScale,
    );
  }

  static bool _insideEllipse(
    Offset p, {
    required double rx,
    required double ry,
  }) {
    final nx = (p.dx - center.dx) / rx;
    final ny = (p.dy - center.dy) / ry;
    return nx * nx + ny * ny <= 1;
  }

  /// 在 growth_world 岛轮廓上取一点（[angleRadians]：0=右，π/2=下，π=左）。
  static Offset pointOnGrowthIslandEdge(
    double angleRadians, {
    double islandRadiusScale = 1.0,
    double inset = 1.0,
  }) {
    final wobble = 1 + math.sin(angleRadians * 3.0 + 0.6) * 0.012;
    final rx = growthRadiusX * islandRadiusScale * inset * wobble;
    final ry = growthRadiusY * islandRadiusScale * inset * wobble;
    return Offset(
      center.dx + math.cos(angleRadians) * rx,
      center.dy + math.sin(angleRadians) * ry,
    );
  }

  /// 主岛码头锚点：岛缘正下方（π/2），随岛屿半径等比外扩。
  /// 仅成长主岛 [IslandBuildingLayout] 使用；副岛有独立落点逻辑。
  static Offset harborPierAnchor({required double islandRadius}) {
    const base = IslandVisualConfig.baseIslandRadius;
    final scale = (islandRadius / base).clamp(0.85, 1.35);
    return pointOnGrowthIslandEdge(
      math.pi / 2,
      islandRadiusScale: scale,
    );
  }

  /// 点是否在岛面椭圆内（[inset] 0~1，越小越靠中心）。
  static bool isOnIsland(Offset p, {double inset = 1}) {
    final rx = radiusX * inset;
    final ry = radiusY * inset;
    final nx = (p.dx - center.dx) / rx;
    final ny = (p.dy - center.dy) / ry;
    return nx * nx + ny * ny <= 1;
  }

  /// 将坐标投影到成长岛轮廓内（与建筑/HUD 落点对齐）。
  ///
  /// [islandRadius] 须与渲染用 [IslandState.radius] 一致。
  static Offset clampToGrowthIsland(
    Offset p, {
    double inset = 0.9,
    double islandRadius = 1.0,
  }) {
    final scale = effectiveIslandRadius(islandRadius);
    final rx = growthRadiusX * inset * scale;
    final ry = growthRadiusY * inset * scale;
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    final nx = dx / rx;
    final ny = dy / ry;
    final dist = math.sqrt(nx * nx + ny * ny);
    if (dist <= 1 || dist == 0) return p;
    final pull = 1 / dist;
    return Offset(
      center.dx + dx * pull,
      center.dy + dy * pull,
    );
  }

  /// 将坐标投影到岛面椭圆内，避免树/草生成到岛外或水面。
  static Offset clampToIsland(Offset p, {double inset = 0.9}) {
    final rx = radiusX * inset;
    final ry = radiusY * inset;
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    final nx = dx / rx;
    final ny = dy / ry;
    final dist = math.sqrt(nx * nx + ny * ny);
    if (dist <= 1 || dist == 0) return p;
    final scale = 1 / dist;
    return Offset(
      center.dx + dx * scale,
      center.dy + dy * scale,
    );
  }

  /// 在矩形区域内随机取点，并保证落在岛面内（固定种子 → 固定位置）。
  static Offset randomInZone(
    Rect zone,
    math.Random random, {
    double inset = 0.9,
    int maxAttempts = 12,
  }) {
    for (var i = 0; i < maxAttempts; i++) {
      final candidate = Offset(
        zone.left + zone.width * random.nextDouble(),
        zone.top + zone.height * random.nextDouble(),
      );
      if (isOnIsland(candidate, inset: inset)) {
        return candidate;
      }
    }
    final fallback = Offset(
      zone.left + zone.width * 0.5,
      zone.top + zone.height * 0.5,
    );
    return clampToIsland(fallback, inset: inset);
  }
}
