import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/models/mood_island_config.dart';

/// 俯视浅海浮岛：乳白沙滩环 + 柔草绒面 + 浅青水域（参考 serene lagoon 示意）。
class SereneLagoonIslandPainter {
  SereneLagoonIslandPainter._();

  static void paint(
    Canvas canvas,
    Size size, {
    required MoodIslandConfig style,
    required double anim,
  }) {
    final waterTop = Color.lerp(style.sea, const Color(0xFFE8F7FA), 0.55)!;
    final waterDeep = Color.lerp(style.sea, const Color(0xFF9FD4DE), 0.35)!;
    final sandLight = Color.lerp(style.sand, Colors.white, 0.72)!;
    final sandWarm = Color.lerp(style.sand, const Color(0xFFE8DFD0), 0.25)!;
    final grassLight = Color.lerp(style.grass, Colors.white, 0.48)!;
    final grassMid = style.grass;
    final grassDeep = Color.lerp(style.grass, const Color(0xFF5E8F6A), 0.22)!;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [waterTop, waterDeep, waterTop.withValues(alpha: 0.92)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    final cx = size.width * 0.5;
    final cy = size.height * 0.46;
    final grassRx = size.width * 0.31;
    final grassRy = size.height * 0.19;
    final sandRx = grassRx * 1.14;
    final sandRy = grassRy * 1.12;

    final grassPath = _ellipsePath(cx, cy, grassRx, grassRy);
    final sandPath = _ellipsePath(cx, cy + grassRy * 0.06, sandRx, sandRy);

    final shadowRect = Rect.fromCenter(
      center: Offset(cx, cy + grassRy * 0.92),
      width: sandRx * 2.05,
      height: grassRy * 0.55,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = ui.Gradient.radial(
          shadowRect.center,
          shadowRect.width * 0.52,
          [
            const Color(0xFF7AA8B0).withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ),
    );

    _drawShallowWater(canvas, cx, cy, sandRx, sandRy, style.sea);

    canvas.drawPath(
      sandPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.05,
          colors: [sandLight, sandWarm, sandWarm.withValues(alpha: 0.85)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(sandPath.getBounds()),
    );

    canvas.save();
    canvas.clipPath(grassPath);
    canvas.drawPath(
      grassPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.12, -0.38),
          radius: 1.08,
          colors: [grassLight, grassMid, grassDeep],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(grassPath.getBounds()),
    );
    _drawGrassTufts(canvas, grassPath.getBounds(), grassDeep, grassMid);
    canvas.restore();

    canvas.drawPath(
      grassPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.42),
    );

    final ripplePhase = anim * 2 * math.pi;
    for (var i = 0; i < 4; i++) {
      final p = ((ripplePhase / (2 * math.pi) + i * 0.22) % 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + grassRy * 1.05),
          width: sandRx * (1.35 + p * 0.22),
          height: grassRy * (0.22 + p * 0.08),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: (1 - p) * 0.16),
      );
    }
  }

  static Path _ellipsePath(double cx, double cy, double rx, double ry) {
    return Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
  }

  static void _drawShallowWater(
    Canvas canvas,
    double cx,
    double cy,
    double sandRx,
    double sandRy,
    Color sea,
  ) {
    final shallow = _ellipsePath(cx, cy + sandRy * 0.04, sandRx * 1.06, sandRy * 1.08);
    canvas.drawPath(
      shallow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            sea.withValues(alpha: 0.08),
            sea.withValues(alpha: 0.22),
            sea.withValues(alpha: 0.04),
          ],
          stops: const [0.35, 0.72, 1.0],
        ).createShader(shallow.getBounds()),
    );
  }

  static void _drawGrassTufts(
    Canvas canvas,
    Rect bounds,
    Color dark,
    Color mid,
  ) {
    final rnd = math.Random(19);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final count = (bounds.width * bounds.height / 180).round().clamp(48, 120);
    for (var i = 0; i < count; i++) {
      final x = bounds.left + rnd.nextDouble() * bounds.width;
      final y = bounds.top + rnd.nextDouble() * bounds.height * 0.9;
      final h = 3.5 + rnd.nextDouble() * 5.5;
      paint.strokeWidth = 0.8 + rnd.nextDouble() * 0.6;
      paint.color = (i.isEven ? dark : mid).withValues(alpha: 0.22 + rnd.nextDouble() * 0.18);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + rnd.nextDouble() * 2 - 1, y - h),
        paint,
      );
    }
  }
}
