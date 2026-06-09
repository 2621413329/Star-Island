import 'dart:math' as math;
import 'dart:ui';

class GrassRenderer {
  const GrassRenderer();

  void render(
    Canvas canvas, {
    required Offset base,
    required double scale,
    required double wind,
    required double time,
  }) {
    final sway = math.sin(time * 1.8 + base.dx * 0.03) * wind * 2.2;
    final paint = Paint()
      ..color = const Color(0xFF5DAE63).withValues(alpha: 0.46)
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      final x = base.dx + i * 2.3 * scale;
      final h = (5 + (i.abs() % 2) * 2) * scale;
      canvas.drawLine(
        Offset(x, base.dy),
        Offset(x + sway * (0.4 + i.abs() * 0.1), base.dy - h),
        paint,
      );
    }
  }
}
