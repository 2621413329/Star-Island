import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show Alignment, LinearGradient;

class RockRenderer {
  const RockRenderer();

  void render(
    Canvas canvas, {
    required Offset base,
    required double scale,
    required double rotation,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(rotation + math.sin(base.dx * 0.01) * 0.05);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: 16 * scale,
      height: 9 * scale,
    );
    canvas.drawOval(
      rect.shift(Offset(1.5 * scale, 1.5 * scale)),
      Paint()..color = const Color(0xFF24485A).withValues(alpha: 0.12),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
        ).createShader(rect),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF607D8B).withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale,
    );
    canvas.restore();
  }
}
