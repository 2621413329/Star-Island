import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../core/models/mood_island_config.dart';
import '../../island/placement/island_placement.dart';

/// 岛屿形状配置：顶面 Path 与侧壁挤出。
class IslandShapeProfile {
  const IslandShapeProfile({required this.key});

  final String key;

  static IslandShapeProfile resolve(MoodIslandConfig style) =>
      IslandShapeProfile(key: _resolveShapeKey(style));

  static String _resolveShapeKey(MoodIslandConfig style) {
    if (style.islandShape == 'growth_world') return 'growth_world';
    if (style.islandShape != 'heart') return style.islandShape;
    return switch (style.moodId) {
      'happy' => 'lagoon',
      'thinking' => 'crescent',
      'sad' => 'round',
      'angry' => 'ridge',
      _ => 'organic',
    };
  }

  Path buildTopPath(Size size, {double lift = 0, bool compact = false}) {
    return switch (key) {
      'growth_world' => _growthWorldPath(size, lift: lift, compact: compact),
      'round' => _ellipsePath(size,
          lift: lift, compact: compact, scaleX: 0.58, scaleY: 0.28),
      'organic' => _organicPath(size, lift: lift, compact: compact),
      'lagoon' => _lagoonPath(size, lift: lift, compact: compact),
      'ridge' => _ridgePath(size, lift: lift, compact: compact),
      'crescent' => _crescentPath(size, lift: lift, compact: compact),
      'symbol_heart' => _heartPath(size, lift: lift, compact: compact),
      _ => _organicPath(size, lift: lift, compact: compact),
    };
  }

  /// 向内收缩的顶面路径，用于草坪裁剪（避免草长到石质边缘外）。
  ///
  /// [islandRadius] 与 [IslandRenderer] / 成长岛 [IslandState.radius] 一致，
  /// 确保石缘、草坪与水面交界对齐。
  Path buildInsetPath(
    Size size, {
    double lift = 0,
    bool compact = false,
    double inset = 0.05,
    double islandRadius = 1.0,
  }) {
    var outer = buildTopPath(size, lift: lift, compact: compact);
    if (key != 'growth_world') return outer;
    outer = applyIslandRadiusScale(
      outer,
      size,
      compact: compact,
      islandRadius: islandRadius,
    );
    return insetPathFromOuter(outer, inset);
  }

  static Offset growthWorldTransformCenter(Size size, {required bool compact}) {
    return Offset(size.width * 0.5, size.height * (compact ? 0.56 : 0.54));
  }

  /// 与成长岛 [IslandState.radius] 缩放顶面 Path，使侧壁/石缘/草坪轮廓一致。
  static Path applyIslandRadiusScale(
    Path path,
    Size size, {
    required bool compact,
    required double islandRadius,
  }) {
    final radius = islandRadius.clamp(0.6, 1.25);
    if (radius == 1) return path;
    final center = growthWorldTransformCenter(size, compact: compact);
    final tx = center.dx * (1 - radius);
    final ty = center.dy * (1 - radius);
    return path.transform(Float64List.fromList([
      radius,
      0,
      0,
      0,
      0,
      radius,
      0,
      0,
      0,
      0,
      1,
      0,
      tx,
      ty,
      0,
      1,
    ]));
  }

  static Path insetPathFromOuter(Path outer, double inset) {
    if (inset <= 0.001) return outer;
    final bounds = outer.getBounds();
    final center = bounds.center;
    final scale = (1 - inset).clamp(0.72, 0.98);
    final matrix = Float64List.fromList([
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      center.dx * (1 - scale),
      center.dy * (1 - scale),
      0,
      1,
    ]);
    return outer.transform(matrix);
  }

  Path _growthWorldPath(Size size,
      {required double lift, required bool compact}) {
    final cx = size.width * 0.5;
    final islandScale = compact ? 1.414 : 1.0;
    final cy = size.height * (compact ? 0.56 : 0.54) + lift;
    final rx = size.width *
        (compact
            ? IslandPlacement.growthRadiusX * 0.952 * islandScale
            : IslandPlacement.growthRadiusX);
    final ry = size.height *
        (compact
            ? IslandPlacement.growthRadiusY * 1.19 * islandScale
            : IslandPlacement.growthRadiusY);
    final path = Path();
    for (var i = 0; i <= 128; i++) {
      final t = math.pi * 2 * i / 128;
      final wobble = 1 + math.sin(t * 3.0 + 0.6) * 0.012;
      final p = Offset(
        cx + math.cos(t) * rx * wobble,
        cy + math.sin(t) * ry * wobble,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  Path _heartPath(Size size, {required double lift, required bool compact}) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * (compact ? 0.58 : 0.56) + lift;
    final scaleX = w * (compact ? 0.31 : 0.38);
    final scaleY = h * (compact ? 0.2 : 0.24);
    final path = Path();
    for (var i = 0; i <= 160; i++) {
      final t = math.pi * 2 * i / 160;
      final x = 16 * math.pow(math.sin(t), 3).toDouble();
      final y = -(13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t));
      final p = Offset(cx + x / 18 * scaleX, cy + y / 18 * scaleY);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  Path _ellipsePath(
    Size size, {
    required double lift,
    required bool compact,
    required double scaleX,
    required double scaleY,
  }) {
    final cx = size.width * 0.5;
    final cy = size.height * (compact ? 0.58 : 0.56) + lift;
    return Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * scaleX,
        height: size.height * scaleY,
      ));
  }

  Path _crescentPath(Size size, {required double lift, required bool compact}) {
    final base = _ellipsePath(size,
        lift: lift, compact: compact, scaleX: 0.58, scaleY: 0.28);
    final bite = _ellipsePath(size,
        lift: lift + size.height * 0.02,
        compact: compact,
        scaleX: 0.19,
        scaleY: 0.11);
    return Path.combine(PathOperation.difference, base,
        bite.shift(Offset(size.width * 0.12, -size.height * 0.02)));
  }

  Path _organicPath(Size size, {required double lift, required bool compact}) {
    final cx = size.width * 0.5;
    final cy = size.height * (compact ? 0.58 : 0.56) + lift;
    final rx = size.width * (compact ? 0.42 : 0.52);
    final ry = size.height * (compact ? 0.21 : 0.28);
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final t = math.pi * 2 * i / 120;
      final wobble = 1 + math.sin(t * 3.0) * 0.06 + math.cos(t * 5.0) * 0.035;
      final p = Offset(cx + math.cos(t) * rx * wobble,
          cy + math.sin(t) * ry * (0.88 + math.sin(t + 1.2) * 0.05));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  Path _lagoonPath(Size size, {required double lift, required bool compact}) {
    final base = _organicPath(size, lift: lift, compact: compact);
    final notch = _ellipsePath(size,
        lift: lift + size.height * 0.015,
        compact: compact,
        scaleX: 0.13,
        scaleY: 0.065);
    return Path.combine(PathOperation.difference, base,
        notch.shift(Offset(-size.width * 0.22, size.height * 0.01)));
  }

  Path _ridgePath(Size size, {required double lift, required bool compact}) {
    final cx = size.width * 0.5;
    final cy = size.height * (compact ? 0.58 : 0.56) + lift;
    final rx = size.width * (compact ? 0.4 : 0.5);
    final ry = size.height * (compact ? 0.21 : 0.27);
    return Path()
      ..moveTo(cx - rx, cy + ry * 0.08)
      ..cubicTo(cx - rx * 0.78, cy - ry * 0.95, cx - rx * 0.18, cy - ry * 1.08,
          cx + rx * 0.18, cy - ry * 0.9)
      ..cubicTo(cx + rx * 0.72, cy - ry * 0.62, cx + rx, cy - ry * 0.1,
          cx + rx * 0.92, cy + ry * 0.2)
      ..cubicTo(cx + rx * 0.78, cy + ry * 0.78, cx + rx * 0.08, cy + ry * 0.92,
          cx - rx * 0.48, cy + ry * 0.65)
      ..cubicTo(cx - rx * 0.82, cy + ry * 0.48, cx - rx * 1.02, cy + ry * 0.28,
          cx - rx, cy + ry * 0.08)
      ..close();
  }
}
