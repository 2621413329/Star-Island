import 'package:flutter/material.dart';

import '../core/constants/mood_catalog.dart';

class MoodFacePainter extends CustomPainter {
  MoodFacePainter({required this.type, required this.color, this.strokeWidth = 2.4});

  final MoodFaceType type;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    canvas.drawCircle(center, r, fill);
    canvas.drawCircle(center, r, stroke);

    final eyeY = center.dy - r * 0.12;
    switch (type) {
      case MoodFaceType.rad:
        canvas.drawLine(
          Offset(center.dx - r * 0.35, eyeY),
          Offset(center.dx - r * 0.08, eyeY),
          stroke,
        );
        canvas.drawLine(
          Offset(center.dx + r * 0.08, eyeY),
          Offset(center.dx + r * 0.35, eyeY),
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.18), width: r * 0.9, height: r * 0.55),
          0.1,
          2.9,
          false,
          stroke,
        );
      case MoodFaceType.good:
        canvas.drawCircle(Offset(center.dx - r * 0.28, eyeY), r * 0.09, stroke);
        canvas.drawCircle(Offset(center.dx + r * 0.28, eyeY), r * 0.09, stroke);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.12), width: r * 0.75, height: r * 0.45),
          0.2,
          2.7,
          false,
          stroke,
        );
      case MoodFaceType.meh:
        canvas.drawCircle(Offset(center.dx - r * 0.28, eyeY), r * 0.09, stroke);
        canvas.drawCircle(Offset(center.dx + r * 0.28, eyeY), r * 0.09, stroke);
        canvas.drawLine(
          Offset(center.dx - r * 0.3, center.dy + r * 0.28),
          Offset(center.dx + r * 0.3, center.dy + r * 0.28),
          stroke,
        );
      case MoodFaceType.bad:
        canvas.drawCircle(Offset(center.dx - r * 0.28, eyeY), r * 0.09, stroke);
        canvas.drawCircle(Offset(center.dx + r * 0.28, eyeY), r * 0.09, stroke);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.42), width: r * 0.7, height: r * 0.4),
          3.4,
          2.2,
          false,
          stroke,
        );
      case MoodFaceType.awful:
        canvas.drawLine(
          Offset(center.dx - r * 0.32, eyeY - r * 0.08),
          Offset(center.dx - r * 0.14, eyeY + r * 0.08),
          stroke,
        );
        canvas.drawLine(
          Offset(center.dx - r * 0.14, eyeY - r * 0.08),
          Offset(center.dx - r * 0.32, eyeY + r * 0.08),
          stroke,
        );
        canvas.drawLine(
          Offset(center.dx + r * 0.14, eyeY - r * 0.08),
          Offset(center.dx + r * 0.32, eyeY + r * 0.08),
          stroke,
        );
        canvas.drawLine(
          Offset(center.dx + r * 0.32, eyeY - r * 0.08),
          Offset(center.dx + r * 0.14, eyeY + r * 0.08),
          stroke,
        );
        final mouth = Path()
          ..moveTo(center.dx - r * 0.25, center.dy + r * 0.35)
          ..quadraticBezierTo(
            center.dx,
            center.dy + r * 0.15,
            center.dx + r * 0.25,
            center.dy + r * 0.42,
          );
        canvas.drawPath(mouth, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant MoodFacePainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
