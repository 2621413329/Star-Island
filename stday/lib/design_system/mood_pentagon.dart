import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 五芒星顶点顺序，与 [MoodRadarChart] 一致（顶→顺时针）。
const moodPentagonOrder = ['happy', 'calm', 'thinking', 'sad', 'angry'];

Path moodPentagonPath(Offset center, double radius) {
  final path = Path();
  for (var i = 0; i < 5; i++) {
    final angle = -math.pi / 2 + i * 2 * math.pi / 5;
    final p = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

Offset moodPentagonVertex(Offset center, double radius, int index) {
  final angle = -math.pi / 2 + index * 2 * math.pi / 5;
  return Offset(
    center.dx + radius * math.cos(angle),
    center.dy + radius * math.sin(angle),
  );
}

/// 选中心情时的五芒星光晕：中心 0% 不透明 → 外缘 100% 不透明。
class MoodPentagonGlow extends StatelessWidget {
  const MoodPentagonGlow({
    super.key,
    required this.color,
    required this.size,
    this.visible = true,
  });

  final Color color;
  final double size;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return SizedBox(width: size, height: size);
    return CustomPaint(
      size: Size(size, size),
      painter: _MoodPentagonGlowPainter(color: color),
    );
  }
}

class _MoodPentagonGlowPainter extends CustomPainter {
  _MoodPentagonGlowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.5;
    final path = moodPentagonPath(center, radius);
    final bounds = path.getBounds().inflate(2);

    canvas.save();
    canvas.clipPath(path);
    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        color.withValues(alpha: 0),
        color.withValues(alpha: 0.12),
        color.withValues(alpha: 0.55),
        color.withValues(alpha: 1),
      ],
      const [0.0, 0.45, 0.78, 1.0],
    );
    canvas.drawRect(bounds, Paint()..shader = gradient);
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MoodPentagonGlowPainter oldDelegate) =>
      oldDelegate.color != color;
}
