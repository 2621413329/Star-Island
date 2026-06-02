import 'package:flutter/material.dart';

/// 沙滩小星：按 expression / prop / tint 绘制，不再默认微笑。
class CompanionPainter extends CustomPainter {
  CompanionPainter({
    required this.style,
    required this.expression,
    required this.prop,
    required this.tint,
    required this.glow,
    this.performanceLevel = 0,
  });

  final String style;
  final String expression;
  final String prop;
  final Color tint;
  final Color glow;
  final double performanceLevel;

  bool get isChibi => style == 'chibi';

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final boost = 0.35 + performanceLevel * 0.45;
    final bodyPaint = Paint()
      ..color = Color.lerp(tint, Colors.white, 0.22)!.withValues(alpha: 0.68 + performanceLevel * 0.22)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isChibi ? 2.4 : 3.0) + performanceLevel;

    if (performanceLevel > 0.05) {
      canvas.drawCircle(
        center,
        size.width * (0.38 + performanceLevel * 0.12),
        Paint()..color = glow.withValues(alpha: 0.22 + performanceLevel * 0.38),
      );
    }

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.18),
      size.width * (0.3 + performanceLevel * 0.05),
      Paint()..color = glow.withValues(alpha: 0.32 * boost),
    );

    _drawProp(canvas, size, stroke);
    _drawBody(canvas, center, size, bodyPaint, stroke);
  }

  void _drawBody(Canvas canvas, Offset c, Size size, Paint fill, Paint stroke) {
    final headR = size.width * (isChibi ? 0.2 : 0.16);
    final headCenter = Offset(c.dx, c.dy - size.height * (isChibi ? 0.2 : 0.26));

    canvas.drawCircle(headCenter, headR, fill);
    canvas.drawCircle(headCenter, headR, stroke);

    final bodyH = size.height * (isChibi ? 0.24 : 0.34);
    final bodyW = size.width * (isChibi ? 0.3 : 0.24);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: bodyW, height: bodyH),
      Radius.circular(isChibi ? 22 : 14),
    );
    canvas.drawRRect(bodyRect, fill);
    canvas.drawRRect(bodyRect, stroke);

    final eyeY = headCenter.dy - headR * 0.08;
    final eyeR = headR * 0.1;
    final eyeFill = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (final dx in [-0.32, 0.32]) {
      canvas.drawCircle(Offset(headCenter.dx + headR * dx, eyeY), eyeR, eyeFill);
      canvas.drawCircle(Offset(headCenter.dx + headR * dx, eyeY), eyeR, stroke);
    }
    _drawExpression(canvas, headCenter, headR, stroke);
  }

  void _drawExpression(Canvas canvas, Offset headCenter, double headR, Paint stroke) {
    final mouthY = headCenter.dy + headR * 0.18;
    final mouthW = headR * 0.55;
    final mouthRect = Rect.fromCenter(center: Offset(headCenter.dx, mouthY), width: mouthW, height: headR * 0.35);

    switch (expression) {
      case 'happy':
        canvas.drawArc(mouthRect, 0.15, 2.85, false, stroke..strokeWidth = stroke.strokeWidth * 0.9);
      case 'sad':
      case 'hurt':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(headCenter.dx, mouthY + headR * 0.08), width: mouthW, height: headR * 0.3),
          3.4,
          2.5,
          false,
          stroke,
        );
        if (expression == 'hurt') {
          final tear = Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.75);
          canvas.drawCircle(Offset(headCenter.dx - headR * 0.28, headCenter.dy + headR * 0.05), 2.5, tear);
        }
      case 'angry':
        final brow = stroke..strokeWidth = stroke.strokeWidth * 1.1;
        canvas.drawLine(
          Offset(headCenter.dx - headR * 0.42, headCenter.dy - headR * 0.22),
          Offset(headCenter.dx - headR * 0.18, headCenter.dy - headR * 0.12),
          brow,
        );
        canvas.drawLine(
          Offset(headCenter.dx + headR * 0.42, headCenter.dy - headR * 0.22),
          Offset(headCenter.dx + headR * 0.18, headCenter.dy - headR * 0.12),
          brow,
        );
        canvas.drawLine(
          Offset(headCenter.dx - mouthW * 0.4, mouthY),
          Offset(headCenter.dx + mouthW * 0.4, mouthY),
          stroke,
        );
      case 'thinking':
        canvas.drawCircle(Offset(headCenter.dx + mouthW * 0.35, mouthY - headR * 0.05), headR * 0.06, stroke);
      default:
        canvas.drawLine(
          Offset(headCenter.dx - mouthW * 0.35, mouthY),
          Offset(headCenter.dx + mouthW * 0.35, mouthY),
          stroke..strokeWidth = stroke.strokeWidth * 0.85,
        );
    }
  }

  void _drawProp(Canvas canvas, Size size, Paint stroke) {
    final fill = Paint()
      ..color = tint.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    switch (prop) {
      case 'workbook':
        final book = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.08, size.height * 0.38, size.width * 0.28, size.height * 0.14),
          const Radius.circular(4),
        );
        canvas.drawRRect(book, fill);
        canvas.drawRRect(book, stroke);
        canvas.drawLine(
          Offset(size.width * 0.22, size.height * 0.38),
          Offset(size.width * 0.22, size.height * 0.52),
          stroke..strokeWidth = 1.5,
        );
        if (expression == 'sad' || expression == 'hurt') {
          final xPaint = Paint()
            ..color = const Color(0xFFE57373).withValues(alpha: 0.85)
            ..strokeWidth = 2;
          canvas.drawLine(
            Offset(size.width * 0.14, size.height * 0.44),
            Offset(size.width * 0.2, size.height * 0.48),
            xPaint,
          );
          canvas.drawLine(
            Offset(size.width * 0.2, size.height * 0.44),
            Offset(size.width * 0.14, size.height * 0.48),
            xPaint,
          );
        }
      case 'ball':
        canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.46), size.width * 0.1, fill);
        canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.46), size.width * 0.1, stroke);
      case 'friends':
        canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.44), size.width * 0.09, fill);
        canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.44), size.width * 0.09, stroke);
        canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.5), size.width * 0.07, fill);
      case 'home':
        final roof = Path()
          ..moveTo(size.width * 0.12, size.height * 0.42)
          ..lineTo(size.width * 0.22, size.height * 0.34)
          ..lineTo(size.width * 0.32, size.height * 0.42)
          ..close();
        canvas.drawPath(roof, fill);
        canvas.drawPath(roof, stroke);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.14, size.height * 0.42, size.width * 0.16, size.height * 0.1),
          fill,
        );
      case 'music':
        canvas.drawOval(
          Rect.fromCenter(center: Offset(size.width * 0.76, size.height * 0.42), width: 18, height: 22),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(size.width * 0.76, size.height * 0.42), width: 18, height: 22),
          stroke,
        );
      case 'umbrella':
        final arc = Path()
          ..addArc(
            Rect.fromCenter(center: Offset(size.width * 0.2, size.height * 0.32), width: 40, height: 28),
            3.14,
            3.14,
          );
        canvas.drawPath(arc, stroke..strokeWidth = 2.5);
        canvas.drawLine(
          Offset(size.width * 0.2, size.height * 0.32),
          Offset(size.width * 0.2, size.height * 0.5),
          stroke,
        );
      case 'stars':
      case 'none':
      default:
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(size.width * (0.14 + i * 0.18), size.height * 0.12),
            2.5,
            Paint()..color = Colors.white.withValues(alpha: 0.7),
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant CompanionPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.expression != expression ||
        oldDelegate.prop != prop ||
        oldDelegate.tint != tint ||
        oldDelegate.performanceLevel != performanceLevel;
  }
}
