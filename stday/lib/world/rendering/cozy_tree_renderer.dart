import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

/// 参考 cozy 岛风格：层叠松树 + 簇状阔叶树 + 石块。
class CozyTreeRenderer {
  CozyTreeRenderer._();

  static void drawGroundShadow(Canvas canvas, Offset base, double scale) {
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, 3 * scale),
        width: 28 * scale,
        height: 9 * scale,
      ),
      Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.14),
    );
  }

  static void drawPine(
    Canvas canvas,
    Offset base,
    double growth,
    double wind,
    double time, {
    double scaleMul = 1,
  }) {
    final scale = (0.78 + growth * 0.38) * scaleMul;
    final sway = math.sin(time * 0.85 + base.dx * 0.008) * (1.2 + wind * 2);
    drawGroundShadow(canvas, base, scale);

    final trunkPaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 3.6 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      base,
      base + Offset(sway * 0.3, -46 * scale),
      trunkPaint,
    );

    const greens = [
      Color(0xFF388E3C),
      Color(0xFF43A047),
      Color(0xFF66BB6A),
    ];
    for (var i = 0; i < 3; i++) {
      final y = base.dy - (18 + i * 13) * scale;
      final w = (30 - i * 6) * scale;
      final layer = Path()
        ..moveTo(base.dx + sway * 0.25, y - 20 * scale)
        ..lineTo(base.dx - w + sway * 0.15, y + 10 * scale)
        ..lineTo(base.dx + w + sway * 0.15, y + 10 * scale)
        ..close();
      canvas.drawPath(
        layer,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(greens[i], Colors.white, 0.25)!,
              greens[i],
            ],
          ).createShader(layer.getBounds()),
      );
    }
  }

  static void drawPuffy(
    Canvas canvas,
    Offset base,
    double growth,
    double wind,
    double time, {
    double scaleMul = 1,
  }) {
    final scale = (0.76 + growth * 0.36) * scaleMul;
    final sway = math.sin(time * 0.75 + base.dx * 0.007) * (1.5 + wind * 2.5);
    drawGroundShadow(canvas, base, scale * 1.1);

    final trunkTop = base + Offset(sway * 0.2, -28 * scale);
    canvas.drawLine(
      base,
      trunkTop,
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 3.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    final clusters = <(Offset offset, double w, double h, Color color)>[
      (Offset(-14 * scale, -8 * scale), 22 * scale, 16 * scale, const Color(0xFF4CAF50)),
      (Offset(16 * scale, -6 * scale), 20 * scale, 15 * scale, const Color(0xFF66BB6A)),
      (Offset(0, -22 * scale), 24 * scale, 18 * scale, const Color(0xFF43A047)),
      (Offset(-8 * scale, -18 * scale), 16 * scale, 12 * scale, const Color(0xFF81C784)),
      (Offset(10 * scale, -20 * scale), 15 * scale, 11 * scale, const Color(0xFF388E3C)),
    ];
    for (final c in clusters) {
      _drawPuffyCluster(
        canvas,
        trunkTop + c.$1 + Offset(sway * 0.15, 0),
        c.$2,
        c.$3,
        c.$4,
      );
    }
  }

  static void _drawPuffyCluster(
    Canvas canvas,
    Offset center,
    double w,
    double h,
    Color color,
  ) {
    final light = Color.lerp(color, Colors.white, 0.38)!;
    final dark = Color.lerp(color, const Color(0xFF1B5E20), 0.22)!;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()
        ..shader = RadialGradient(
          colors: [light, color, dark.withValues(alpha: 0.85)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCenter(center: center, width: w, height: h)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-w * 0.18, h * 0.06),
        width: w * 0.52,
        height: h * 0.48,
      ),
      Paint()..color = light.withValues(alpha: 0.42),
    );
  }

  static void drawRock(Canvas canvas, Offset base, double growth) {
    final scale = 0.7 + growth * 0.35;
    for (var i = 0; i < 3; i++) {
      final c = base + Offset((i - 1) * 9.0 * scale, -2.0 * scale - i * 1.2);
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: (14 + i * 3) * scale,
          height: (9 + i * 2) * scale,
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB0BEC5),
              Color(0xFF78909C),
              Color(0xFF607D8B),
            ],
          ).createShader(Rect.fromCenter(
            center: c,
            width: 20 * scale,
            height: 12 * scale,
          )),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, 4 * scale),
        width: 26 * scale,
        height: 7 * scale,
      ),
      Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.1),
    );
  }
}
