import 'dart:math' as math;
import 'dart:ui';

class FlowerRenderer {
  const FlowerRenderer();

  void render(
    Canvas canvas, {
    required Offset base,
    required double scale,
    required Color color,
    required double time,
  }) {
    final stem = Paint()
      ..color = const Color(0xFF66A96B).withValues(alpha: 0.46)
      ..strokeWidth = 1.0 * scale
      ..strokeCap = StrokeCap.round;
    final bob = math.sin(time * 1.6 + base.dx * 0.02) * scale;
    for (var i = 0; i < 3; i++) {
      final dx = (i - 1) * 4.0 * scale;
      final p = base + Offset(dx, bob - (i % 2) * 2 * scale);
      canvas.drawLine(p, p + Offset(0, -6 * scale), stem);
      canvas.drawCircle(
        p + Offset(0, -7 * scale),
        2.2 * scale,
        Paint()..color = color.withValues(alpha: 0.66),
      );
      canvas.drawCircle(
        p + Offset(0, -7 * scale),
        0.9 * scale,
        Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.72),
      );
    }
  }
}
