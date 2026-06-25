import 'dart:math' as math;
import 'dart:ui';

import '../config/island_visual_config.dart';

/// 成长岛表面可放置区域的归一化约束（与 [IslandShapeProfile._growthWorldPath] 对齐）。
class IslandPlacement {
  IslandPlacement._();

  static const Offset center = Offset(0.5, 0.54);

  /// 圆形岛屿半径（相对屏宽）；实际绘制为像素等半径圆。
  static const double growthRadiusX = 0.34;

  /// 仅用于旧 normalized 椭圆检测的兼容半轴。
  static const double growthRadiusY = 0.34;

  /// 旧装饰落点仍使用略小的保守椭圆。
  static const double radiusX = 0.33;
  static const double radiusY = 0.33;

  static double pixelRadius(Size size, {bool compact = false}) {
    final islandScale = compact ? 1.414 : 1.0;
    return size.width *
        growthRadiusX *
        (compact ? 0.952 * islandScale : 1.0);
  }

  static Offset pixelCenter(Size size, {bool compact = false, double lift = 0}) {
    return Offset(
      size.width * 0.5,
      size.height * (compact ? 0.56 : 0.54) + lift,
    );
  }

  static bool containsPixel(
    Size size,
    Offset point, {
    bool compact = false,
    double inset = 1.0,
  }) {
    final c = pixelCenter(size, compact: compact);
    final r = pixelRadius(size, compact: compact) * inset;
    final dx = point.dx - c.dx;
    final dy = point.dy - c.dy;
    return dx * dx + dy * dy <= r * r;
  }

  /// 成长岛面圆内（[inset] 越小越靠中心）。
  static bool isOnGrowthIsland(Offset p, {double inset = 1.0}) {
    final r = growthRadiusX * inset;
    final dx = (p.dx - center.dx) / r;
    final dy = (p.dy - center.dy) / r;
    return dx * dx + dy * dy <= 1;
  }

  /// 在 growth_world 岛轮廓上取一点（[angleRadians]：0=右，π/2=下，π=左）。
  static Offset pointOnGrowthIslandEdge(
    double angleRadians, {
    double islandRadiusScale = 1.0,
    double inset = 1.0,
  }) {
    final wobble = 1 + math.sin(angleRadians * 3.0 + 0.6) * 0.012;
    final r = growthRadiusX * islandRadiusScale * inset * wobble;
    return Offset(
      center.dx + math.cos(angleRadians) * r,
      center.dy + math.sin(angleRadians) * r,
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
    final r = radiusX * inset;
    final dx = (p.dx - center.dx) / r;
    final dy = (p.dy - center.dy) / r;
    return dx * dx + dy * dy <= 1;
  }

  /// 将坐标投影到成长岛轮廓内（与建筑/HUD 落点对齐）。
  static Offset clampToGrowthIsland(Offset p, {double inset = 0.9}) {
    final r = growthRadiusX * inset;
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= r || dist == 0) return p;
    final scale = r / dist;
    return Offset(center.dx + dx * scale, center.dy + dy * scale);
  }

  /// 将坐标投影到岛面椭圆内，避免树/草生成到岛外或水面。
  static Offset clampToIsland(Offset p, {double inset = 0.9}) {
    final r = radiusX * inset;
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= r || dist == 0) return p;
    final scale = r / dist;
    return Offset(center.dx + dx * scale, center.dy + dy * scale);
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
