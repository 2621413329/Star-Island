import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

/// Growth Island 视觉原型主角：温暖的成长旅人（Canvas 伪 3D）。
class CozyHeroRenderer {
  CozyHeroRenderer._();

  /// [CompanionPainter] / Avatar 用：在矩形内绘制。
  static void paintInRect(
    Canvas canvas,
    Size size, {
    String expression = 'calm',
    String prop = 'none',
    String? gender,
    double performanceLevel = 0,
  }) {
    final charSize = size.width * 0.78;
    paintAt(
      canvas,
      groundX: size.width * 0.5,
      groundY: size.height * 0.74,
      charSize: charSize,
      expression: expression,
      prop: prop,
      gender: gender,
      performanceLevel: performanceLevel,
      bodyBob: math.sin(performanceLevel * math.pi) * charSize * 0.04,
      scale: 1 + performanceLevel * 0.08,
    );
  }

  /// 岛屿场景用：以脚底锚点绘制。
  static void paintAt(
    Canvas canvas, {
    required double groundX,
    required double groundY,
    required double charSize,
    String expression = 'calm',
    String prop = 'none',
    double performanceLevel = 0,
    String? gender,
    double bodyBob = 0,
    double dx = 0,
    double dy = 0,
    double rotation = 0,
    double scale = 1,
  }) {
    final cx = groundX + dx;
    final cy = groundY - charSize * 0.42 + bodyBob + dy;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    canvas.scale(scale, scale);

    _drawGroundShadow(canvas, charSize);

    if (prop == 'backpack') {
      _drawBackpack(canvas, charSize);
    }

    _drawBody(canvas, charSize);
    _drawHead(canvas, charSize, expression, gender);
    _drawArms(canvas, charSize);

    canvas.restore();
  }

  static void _drawGroundShadow(Canvas canvas, double charSize) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, charSize * 0.34),
        width: charSize * 0.46,
        height: charSize * 0.12,
      ),
      Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.16),
    );
  }

  static void _drawBody(Canvas canvas, double charSize) {
    final bodyBounds = Rect.fromCenter(
      center: Offset(0, charSize * 0.18),
      width: charSize * 0.46,
      height: charSize * 0.72,
    );
    final body = Path()
      ..moveTo(0, -charSize * 0.10)
      ..cubicTo(
        -charSize * 0.16,
        -charSize * 0.08,
        -charSize * 0.22,
        charSize * 0.10,
        -charSize * 0.20,
        charSize * 0.32,
      )
      ..quadraticBezierTo(
        -charSize * 0.11,
        charSize * 0.47,
        -charSize * 0.04,
        charSize * 0.42,
      )
      ..quadraticBezierTo(0, charSize * 0.37, charSize * 0.04, charSize * 0.42)
      ..quadraticBezierTo(
        charSize * 0.11,
        charSize * 0.47,
        charSize * 0.20,
        charSize * 0.32,
      )
      ..cubicTo(
        charSize * 0.22,
        charSize * 0.10,
        charSize * 0.16,
        -charSize * 0.08,
        0,
        -charSize * 0.10,
      )
      ..close();
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.30, -0.45),
        radius: 1.05,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF8F7EE),
          Color(0xFFE5E3D5),
        ],
      ).createShader(bodyBounds.inflate(charSize * 0.08));
    final outlinePaint = Paint()
      ..color = const Color(0xFFD8D5C8).withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = charSize * 0.012;

    canvas.drawPath(
      body.shift(Offset(charSize * 0.025, charSize * 0.035)),
      Paint()..color = const Color(0xFF6B6B5D).withValues(alpha: 0.10),
    );
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, outlinePaint);

    for (final dx in [-charSize * 0.075, charSize * 0.075]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx, charSize * 0.435),
          width: charSize * 0.105,
          height: charSize * 0.065,
        ),
        bodyPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx, charSize * 0.435),
          width: charSize * 0.105,
          height: charSize * 0.065,
        ),
        outlinePaint,
      );
    }
  }

  static void _drawHead(
    Canvas canvas,
    double charSize,
    String expression,
    String? gender,
  ) {
    final headCenter = Offset(0, -charSize * 0.255);
    final headR = charSize * 0.305;
    final headRect = Rect.fromCircle(center: headCenter, radius: headR);
    final headPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.32, -0.42),
        radius: 1.0,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7F6EC),
          Color(0xFFE2DFD0),
        ],
      ).createShader(headRect.inflate(headR * 0.12));
    final outlinePaint = Paint()
      ..color = const Color(0xFFD8D5C8).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = charSize * 0.012;

    canvas.drawCircle(
      headCenter + Offset(headR * 0.08, headR * 0.10),
      headR * 0.98,
      Paint()..color = const Color(0xFF6B6B5D).withValues(alpha: 0.10),
    );
    if (gender == 'female') {
      _drawFemaleSilhouette(canvas, headCenter, headR, headPaint, outlinePaint);
    }
    canvas.drawCircle(headCenter, headR, headPaint);
    canvas.drawCircle(headCenter, headR, outlinePaint);
    if (gender == 'male') {
      _drawMaleAhoge(canvas, headCenter, headR, outlinePaint);
    }

    // 高光点
    canvas.drawCircle(
      headCenter + Offset(-headR * 0.30, -headR * 0.36),
      headR * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.46),
    );

    _drawFace(canvas, headCenter, charSize, expression, gender);
  }

  static void _drawMaleAhoge(
    Canvas canvas,
    Offset headCenter,
    double headR,
    Paint outlinePaint,
  ) {
    final ahogePaint = Paint()
      ..color = const Color(0xFFECE9DA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.075
      ..strokeCap = StrokeCap.round;
    final root = headCenter + Offset(headR * 0.02, -headR * 0.92);
    final tip = headCenter + Offset(headR * 0.18, -headR * 1.27);
    final path = Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(
        headCenter.dx + headR * 0.03,
        headCenter.dy - headR * 1.16,
        tip.dx,
        tip.dy,
      );
    canvas.drawPath(
      path.shift(Offset(headR * 0.03, headR * 0.04)),
      Paint()
        ..color = const Color(0xFF6B6B5D).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ahogePaint.strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(path, ahogePaint);
    canvas.drawPath(
      path,
      Paint()
        ..color = outlinePaint.color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = headR * 0.018
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _drawFemaleSilhouette(
    Canvas canvas,
    Offset headCenter,
    double headR,
    Paint headPaint,
    Paint outlinePaint,
  ) {
    final hair = Path()
      ..moveTo(headCenter.dx - headR * 0.72, headCenter.dy - headR * 0.36)
      ..quadraticBezierTo(
        headCenter.dx - headR * 1.18,
        headCenter.dy + headR * 0.28,
        headCenter.dx - headR * 0.82,
        headCenter.dy + headR * 1.03,
      )
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy + headR * 1.26,
        headCenter.dx + headR * 0.82,
        headCenter.dy + headR * 1.03,
      )
      ..quadraticBezierTo(
        headCenter.dx + headR * 1.18,
        headCenter.dy + headR * 0.28,
        headCenter.dx + headR * 0.72,
        headCenter.dy - headR * 0.36,
      )
      ..close();
    canvas.drawPath(
      hair.shift(Offset(headR * 0.05, headR * 0.08)),
      Paint()..color = const Color(0xFF6B6B5D).withValues(alpha: 0.08),
    );
    canvas.drawPath(hair, headPaint);
    canvas.drawPath(hair, outlinePaint);

    final bangPaint = Paint()
      ..color = const Color(0xFFECE9DA).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: headCenter + Offset(-headR * 0.10, -headR * 0.38),
        width: headR * 1.20,
        height: headR * 0.82,
      ),
      math.pi * 1.02,
      math.pi * 0.52,
      false,
      bangPaint,
    );
  }

  static void _drawFace(
    Canvas canvas,
    Offset headCenter,
    double charSize,
    String expression,
    String? gender,
  ) {
    final eyeY = headCenter.dy - charSize * 0.018;
    final eyeOffset = charSize * 0.060;
    final eyeR = charSize * 0.022;
    final eyePaint = Paint()..color = const Color(0xFF57534A);

    switch (expression) {
      case 'happy':
      case 'proud':
        for (final dx in [-eyeOffset, eyeOffset]) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(headCenter.dx + dx, eyeY),
              width: eyeR * 2.4,
              height: eyeR * 1.6,
            ),
            math.pi * 0.15,
            math.pi * 0.7,
            false,
            Paint()
              ..color = const Color(0xFF57534A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..strokeCap = StrokeCap.round,
          );
        }
      default:
        canvas.drawCircle(
          Offset(headCenter.dx - eyeOffset, eyeY),
          eyeR,
          eyePaint,
        );
        canvas.drawCircle(
          Offset(headCenter.dx + eyeOffset, eyeY),
          eyeR,
          eyePaint,
        );
    }
    if (gender == 'female') {
      final lash = Paint()
        ..color = const Color(0xFF57534A).withValues(alpha: 0.72)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      for (final side in [-1.0, 1.0]) {
        final outer = Offset(headCenter.dx + side * eyeOffset * 1.25, eyeY);
        canvas.drawLine(
          outer,
          outer + Offset(side * charSize * 0.018, -charSize * 0.018),
          lash,
        );
      }
    }

    final mouthCenter = headCenter + Offset(0, charSize * 0.035);
    final mouthPaint = Paint()
      ..color = const Color(0xFF6E6A60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    if (expression == 'happy' || expression == 'proud') {
      canvas.drawArc(
        Rect.fromCenter(
          center: mouthCenter,
          width: charSize * 0.13,
          height: charSize * 0.07,
        ),
        0.08,
        math.pi - 0.16,
        false,
        mouthPaint..strokeWidth = 1.5,
      );
    } else if (expression == 'sad') {
      canvas.drawLine(
        mouthCenter + Offset(-charSize * 0.04, 0),
        mouthCenter + Offset(charSize * 0.04, 0),
        mouthPaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: mouthCenter,
          width: charSize * 0.11,
          height: charSize * 0.055,
        ),
        0.12,
        math.pi - 0.24,
        false,
        mouthPaint,
      );
    }
  }

  static void _drawArms(Canvas canvas, double charSize) {
    final limbPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 1.0,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF6F4EA),
          Color(0xFFE0DDCE),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset.zero,
        width: charSize * 0.75,
        height: charSize * 0.75,
      ));
    final limbStroke = Paint()
      ..color = const Color(0xFFD8D5C8).withValues(alpha: 0.70)
      ..strokeWidth = charSize * 0.010
      ..style = PaintingStyle.stroke;
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(side * charSize * 0.155, -charSize * 0.005);
      final hand = shoulder + Offset(side * charSize * 0.105, charSize * 0.20);
      canvas.drawLine(
        shoulder,
        hand,
        Paint()
          ..color = const Color(0xFFE9E6D8)
          ..strokeWidth = charSize * 0.044
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        hand,
        charSize * 0.045,
        limbPaint,
      );
      canvas.drawCircle(hand, charSize * 0.045, limbStroke);
    }
  }

  static void _drawBackpack(Canvas canvas, double charSize) {
    final packRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, charSize * 0.02),
        width: charSize * 0.28,
        height: charSize * 0.32,
      ),
      Radius.circular(charSize * 0.06),
    );
    canvas.drawRRect(
      packRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
        ).createShader(packRect.outerRect),
    );
    canvas.drawRRect(
      packRect,
      Paint()
        ..color = const Color(0xFF4E342E).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}
