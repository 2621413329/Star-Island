import 'dart:math' as math;
import 'dart:ui';

import '../config/island_visual_config.dart';

/// 成长岛表面可放置区域的归一化约束（与 [IslandShapeProfile._growthWorldPath] 对齐）。
class IslandPlacement {
  IslandPlacement._();

  static const Offset center = Offset(0.5, 0.54);

  /// 与 [IslandShapeProfile._growthWorldPath] 非 compact 模式一致的岛面椭圆半轴。
  static const double growthRadiusX = 0.50;
  static const double growthRadiusY = 0.125;

  /// 旧装饰落点仍使用略小的保守椭圆。
  static const double radiusX = 0.43;
  static const double radiusY = 0.105;

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

  /// 码头锚点：左下缘（约 135°），随岛屿半径等比外扩。
  static Offset harborPierAnchor({required double islandRadius}) {
    const base = IslandVisualConfig.baseIslandRadius;
    final scale = (islandRadius / base).clamp(0.85, 1.35);
    return pointOnGrowthIslandEdge(
      3 * math.pi / 4,
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
