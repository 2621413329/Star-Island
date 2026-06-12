import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../world/rendering/cozy_hero_renderer.dart';

/// 半透明精神体：按 expression / prop / tint 绘制情绪、姿态与经历物件。
class CompanionPainter extends CustomPainter {
  CompanionPainter({
    required this.style,
    required this.expression,
    required this.prop,
    required this.tint,
    required this.glow,
    this.extraProps = const [],
    this.performanceLevel = 0,
    this.showAura = true,
    this.gender,
  });

  final String style;
  final String expression;
  final String prop;
  final List<String> extraProps;
  final Color tint;
  final Color glow;
  final double performanceLevel;
  final bool showAura;

  /// male/female 只影响软陶 Mascot 的轮廓比例，不添加服装或配饰。
  final String? gender;

  bool get isCozy => style == 'cozy';
  bool get isChibi => style == 'chibi_legacy';

  Color get _starCoreColor => switch (expression) {
        'happy' => const Color(0xFFFFD76A),
        'proud' || 'expecting' || 'hopeful' => const Color(0xFF5FE3C0),
        'sad' || 'hurt' => const Color(0xFF9FD7FF),
        'thinking' || 'anxious' => const Color(0xFFB79CFF),
        'angry' => const Color(0xFFFF7A4D),
        _ => const Color(0xFF8EC5FF),
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (isCozy) {
      CozyHeroRenderer.paintInRect(
        canvas,
        size,
        expression: expression,
        prop: prop,
        extraProps: extraProps,
        gender: gender,
        starCoreColor: _starCoreColor,
        performanceLevel: performanceLevel,
      );
      return;
    }

    final center = Offset(size.width / 2, size.height * 0.55);
    final boost = 0.35 + performanceLevel * 0.45;
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(tint, Colors.white, 0.62)!
              .withValues(alpha: 0.55 + performanceLevel * 0.2),
          Color.lerp(tint, const Color(0xFF24334D), 0.18)!
              .withValues(alpha: 0.42 + performanceLevel * 0.16),
        ],
      ).createShader(Rect.fromCenter(
          center: center, width: size.width * 0.7, height: size.height * 0.8))
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isChibi ? 2.4 : 3.0) + performanceLevel;

    if (showAura && performanceLevel > 0.05) {
      canvas.drawCircle(
        center,
        size.width * (0.38 + performanceLevel * 0.12),
        Paint()..color = glow.withValues(alpha: 0.22 + performanceLevel * 0.38),
      );
    }

    if (showAura) {
      _drawAura(canvas, size, center, boost);
    }
    _drawProp(canvas, size, stroke);
    _drawBody(canvas, center, size, bodyPaint, stroke);
  }

  void _drawAura(Canvas canvas, Size size, Offset center, double boost) {
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          glow.withValues(alpha: 0.22 * boost),
          tint.withValues(alpha: 0.08 * boost),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.52));
    canvas.drawCircle(center, size.width * 0.52, halo);

    final ribbon = Paint()
      ..color = Color.lerp(tint, Colors.white, 0.45)!.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.36 + i * 0.12);
      final path = Path()
        ..moveTo(size.width * 0.22, y)
        ..cubicTo(size.width * 0.36, y - 12, size.width * 0.62, y + 12,
            size.width * 0.78, y - 2);
      canvas.drawPath(path, ribbon);
    }
  }

  void _drawBody(Canvas canvas, Offset c, Size size, Paint fill, Paint stroke) {
    final headR = size.width * (isChibi ? 0.2 : 0.15);
    final headCenter =
        Offset(c.dx, c.dy - size.height * (isChibi ? 0.2 : 0.27));

    _drawHair(canvas, headCenter, headR, fill, stroke);
    canvas.drawCircle(headCenter, headR, fill);
    canvas.drawCircle(headCenter, headR, stroke);

    final bodyH = size.height * (isChibi ? 0.24 : 0.34);
    final bodyW = size.width * (isChibi ? 0.3 : 0.24);
    final bodyPath = Path()
      ..moveTo(c.dx, c.dy - bodyH * 0.55)
      ..cubicTo(c.dx - bodyW * 0.55, c.dy - bodyH * 0.32, c.dx - bodyW * 0.5,
          c.dy + bodyH * 0.34, c.dx, c.dy + bodyH * 0.6)
      ..cubicTo(c.dx + bodyW * 0.5, c.dy + bodyH * 0.34, c.dx + bodyW * 0.55,
          c.dy - bodyH * 0.32, c.dx, c.dy - bodyH * 0.55)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, stroke);

    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.82),
          tint.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: bodyW * 0.55));
    canvas.drawCircle(c + Offset(0, bodyH * 0.02), bodyW * 0.35, core);

    final armPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth * 0.72
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(-bodyW * 0.48, -bodyH * 0.12),
        c + Offset(-bodyW * 0.74, bodyH * 0.18), armPaint);
    canvas.drawLine(c + Offset(bodyW * 0.48, -bodyH * 0.12),
        c + Offset(bodyW * 0.72, bodyH * 0.12), armPaint);

    final eyeY = headCenter.dy - headR * 0.08;
    final eyeR = headR * 0.1;
    final eyeFill = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (final dx in [-0.32, 0.32]) {
      canvas.drawCircle(
          Offset(headCenter.dx + headR * dx, eyeY), eyeR, eyeFill);
      canvas.drawCircle(Offset(headCenter.dx + headR * dx, eyeY), eyeR, stroke);
    }
    _drawExpression(canvas, headCenter, headR, stroke);
  }

  void _drawHair(
    Canvas canvas,
    Offset headCenter,
    double headR,
    Paint fill,
    Paint stroke,
  ) {
    if (gender != 'female') return;

    final hairFill = Paint()
      ..color = Color.lerp(tint, const Color(0xFF3D2C4A), 0.35)!
          .withValues(alpha: 0.55);
    final hairStroke = Paint()
      ..color = Color.lerp(tint, Colors.white, 0.45)!.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth * 0.85
      ..strokeCap = StrokeCap.round;

    final top = headCenter + Offset(0, -headR * 1.05);
    final hair = Path()
      ..moveTo(top.dx, top.dy + headR * 0.35)
      ..quadraticBezierTo(
        headCenter.dx - headR * 1.35,
        headCenter.dy - headR * 0.15,
        headCenter.dx - headR * 1.05,
        headCenter.dy + headR * 1.05,
      )
      ..quadraticBezierTo(
        headCenter.dx - headR * 0.35,
        headCenter.dy + headR * 1.45,
        headCenter.dx,
        headCenter.dy + headR * 1.2,
      )
      ..quadraticBezierTo(
        headCenter.dx + headR * 0.35,
        headCenter.dy + headR * 1.45,
        headCenter.dx + headR * 1.05,
        headCenter.dy + headR * 1.05,
      )
      ..quadraticBezierTo(
        headCenter.dx + headR * 1.35,
        headCenter.dy - headR * 0.15,
        top.dx,
        top.dy + headR * 0.35,
      )
      ..close();
    canvas.drawPath(hair, hairFill);
    canvas.drawPath(hair, hairStroke);

    canvas.drawArc(
      Rect.fromCenter(
        center: headCenter + Offset(0, -headR * 0.72),
        width: headR * 1.85,
        height: headR * 1.1,
      ),
      math.pi * 1.05,
      math.pi * 0.92,
      false,
      hairStroke..strokeWidth = stroke.strokeWidth * 0.7,
    );
  }

  void _drawExpression(
      Canvas canvas, Offset headCenter, double headR, Paint stroke) {
    final mouthY = headCenter.dy + headR * 0.18;
    final mouthW = headR * 0.55;
    final mouthRect = Rect.fromCenter(
        center: Offset(headCenter.dx, mouthY),
        width: mouthW,
        height: headR * 0.35);

    switch (expression) {
      case 'happy':
        canvas.drawArc(mouthRect, 0.15, 2.85, false,
            stroke..strokeWidth = stroke.strokeWidth * 0.9);
      case 'sad':
      case 'hurt':
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(headCenter.dx, mouthY + headR * 0.08),
              width: mouthW,
              height: headR * 0.3),
          3.4,
          2.5,
          false,
          stroke,
        );
        if (expression == 'hurt') {
          final tear = Paint()
            ..color = const Color(0xFF81D4FA).withValues(alpha: 0.75);
          canvas.drawCircle(
              Offset(
                  headCenter.dx - headR * 0.28, headCenter.dy + headR * 0.05),
              2.5,
              tear);
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
        canvas.drawCircle(
            Offset(headCenter.dx + mouthW * 0.35, mouthY - headR * 0.05),
            headR * 0.06,
            stroke);
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
      case 'exam_paper':
        _drawExamPaper(canvas, size, stroke, fill);
        return;
      case 'workbook':
      case 'book':
      case 'desk':
        final book = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.08, size.height * 0.38,
              size.width * 0.28, size.height * 0.14),
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
        if (prop == 'desk') {
          canvas.drawLine(
            Offset(size.width * 0.04, size.height * 0.54),
            Offset(size.width * 0.38, size.height * 0.54),
            stroke..strokeWidth = 2,
          );
        }
      case 'glasses':
        final gStroke = stroke..strokeWidth = 1.8;
        canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.33),
            size.width * 0.065, gStroke);
        canvas.drawCircle(Offset(size.width * 0.57, size.height * 0.33),
            size.width * 0.065, gStroke);
        canvas.drawLine(
          Offset(size.width * 0.51, size.height * 0.33),
          Offset(size.width * 0.52, size.height * 0.33),
          gStroke,
        );
      case 'ball':
      case 'basketball':
        canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.46),
            size.width * 0.1, fill);
        canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.46),
            size.width * 0.1, stroke);
        if (prop == 'basketball') {
          final b = Offset(size.width * 0.78, size.height * 0.46);
          canvas.drawArc(
            Rect.fromCircle(center: b, radius: size.width * 0.1),
            0.2,
            2.8,
            false,
            stroke..strokeWidth = 1.3,
          );
          canvas.drawLine(
            Offset(b.dx - size.width * 0.1, b.dy),
            Offset(b.dx + size.width * 0.1, b.dy),
            stroke,
          );
        }
      case 'badminton_racket':
        _drawBadminton(canvas, size, stroke, fill);
      case 'medal':
        canvas.drawCircle(
          Offset(size.width * 0.76, size.height * 0.42),
          size.width * 0.08,
          Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.82),
        );
        canvas.drawCircle(
          Offset(size.width * 0.76, size.height * 0.42),
          size.width * 0.08,
          stroke,
        );
        canvas.drawLine(
          Offset(size.width * 0.71, size.height * 0.33),
          Offset(size.width * 0.76, size.height * 0.38),
          stroke,
        );
        canvas.drawLine(
          Offset(size.width * 0.81, size.height * 0.33),
          Offset(size.width * 0.76, size.height * 0.38),
          stroke,
        );
      case 'running_shoes':
        final shoe = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.67, size.height * 0.5, size.width * 0.2,
              size.height * 0.08),
          const Radius.circular(5),
        );
        canvas.drawRRect(shoe, fill);
        canvas.drawRRect(shoe, stroke);
        canvas.drawOval(
          Rect.fromLTWH(size.width * 0.72, size.height * 0.52,
              size.width * 0.06, size.height * 0.05),
          stroke..strokeWidth = 1.2,
        );
      case 'game_controller':
        _drawGameController(canvas, size, stroke, fill);
      case 'friends':
        canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.44),
            size.width * 0.09, fill);
        canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.44),
            size.width * 0.09, stroke);
        canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.5),
            size.width * 0.07, fill);
        _drawSmallHeart(
            canvas, Offset(size.width * 0.74, size.height * 0.32), tint);
      case 'chat_bubbles':
        _drawChatBubbles(canvas, size, stroke, fill);
      case 'heart':
        _drawSmallHeart(
            canvas, Offset(size.width * 0.78, size.height * 0.42), tint);
      case 'home':
        final roof = Path()
          ..moveTo(size.width * 0.12, size.height * 0.42)
          ..lineTo(size.width * 0.22, size.height * 0.34)
          ..lineTo(size.width * 0.32, size.height * 0.42)
          ..close();
        canvas.drawPath(roof, fill);
        canvas.drawPath(roof, stroke);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.14, size.height * 0.42,
              size.width * 0.16, size.height * 0.1),
          fill,
        );
      case 'music':
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width * 0.76, size.height * 0.42),
              width: 18,
              height: 22),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width * 0.76, size.height * 0.42),
              width: 18,
              height: 22),
          stroke,
        );
      case 'umbrella':
        final arc = Path()
          ..addArc(
            Rect.fromCenter(
                center: Offset(size.width * 0.2, size.height * 0.32),
                width: 40,
                height: 28),
            3.14,
            3.14,
          );
        canvas.drawPath(arc, stroke..strokeWidth = 2.5);
        canvas.drawLine(
          Offset(size.width * 0.2, size.height * 0.32),
          Offset(size.width * 0.2, size.height * 0.5),
          stroke,
        );
      case 'trophy':
        _drawTrophy(canvas, size, stroke, fill);
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

  void _drawExamPaper(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final paperRect = Rect.fromLTWH(size.width * 0.07, size.height * 0.36,
        size.width * 0.28, size.height * 0.19);
    final paper = RRect.fromRectAndRadius(paperRect, const Radius.circular(6));
    canvas.drawRRect(
      paper,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.84),
            tint.withValues(alpha: 0.22),
          ],
        ).createShader(paperRect),
    );
    canvas.drawRRect(paper, stroke);

    final linePaint = Paint()
      ..color = const Color(0xFF546E7A).withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = paperRect.top + paperRect.height * (0.28 + i * 0.18);
      canvas.drawLine(Offset(paperRect.left + 8, y),
          Offset(paperRect.right - 8, y), linePaint);
    }

    final mark = Paint()
      ..color = const Color(0xFFE57373).withValues(alpha: 0.9)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(paperRect.left + paperRect.width * 0.63,
          paperRect.top + paperRect.height * 0.18),
      Offset(paperRect.left + paperRect.width * 0.82,
          paperRect.top + paperRect.height * 0.34),
      mark,
    );
    canvas.drawLine(
      Offset(paperRect.left + paperRect.width * 0.82,
          paperRect.top + paperRect.height * 0.18),
      Offset(paperRect.left + paperRect.width * 0.63,
          paperRect.top + paperRect.height * 0.34),
      mark,
    );

    if (expression == 'sad' || expression == 'hurt') {
      final shadow = Paint()
        ..color = const Color(0xFF78909C).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.22, size.height * 0.61),
            width: size.width * 0.34,
            height: size.height * 0.08),
        0.08,
        math.pi - 0.16,
        false,
        shadow,
      );
    }
  }

  void _drawGameController(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.64, size.height * 0.44, size.width * 0.26,
          size.height * 0.14),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);
    final btnPaint = Paint()..color = tint.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.51),
        size.width * 0.028, btnPaint);
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.51),
        size.width * 0.028, btnPaint);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.47),
        size.width * 0.028, btnPaint);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.55),
        size.width * 0.028, btnPaint);
    if (expression == 'happy') {
      canvas.drawCircle(
        Offset(size.width * 0.86, size.height * 0.38),
        3,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.9),
      );
    }
  }

  void _drawBadminton(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final racketCenter = Offset(size.width * 0.78, size.height * 0.4);
    final racketStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawOval(
      Rect.fromCenter(
          center: racketCenter,
          width: size.width * 0.18,
          height: size.width * 0.24),
      racketStroke,
    );
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(racketCenter.dx + i * 3.0, racketCenter.dy - size.width * 0.09),
        Offset(racketCenter.dx + i * 3.0, racketCenter.dy + size.width * 0.09),
        racketStroke..strokeWidth = 0.7,
      );
    }
    canvas.drawLine(
      racketCenter + Offset(-size.width * 0.03, size.width * 0.1),
      Offset(size.width * 0.66, size.height * 0.58),
      Paint()
        ..color = tint.withValues(alpha: 0.72)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final shuttle = Path()
      ..moveTo(size.width * 0.18, size.height * 0.34)
      ..lineTo(size.width * 0.27, size.height * 0.3)
      ..lineTo(size.width * 0.27, size.height * 0.39)
      ..close();
    canvas.drawPath(
        shuttle, Paint()..color = Colors.white.withValues(alpha: 0.78));
    canvas.drawCircle(Offset(size.width * 0.17, size.height * 0.365), 3, fill);
    if (expression == 'sad' || expression == 'hurt') {
      canvas.drawLine(
        Offset(size.width * 0.12, size.height * 0.5),
        Offset(size.width * 0.32, size.height * 0.55),
        Paint()
          ..color = const Color(0xFF90A4AE).withValues(alpha: 0.45)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawChatBubbles(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final a = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.66, size.height * 0.32, size.width * 0.2,
          size.height * 0.11),
      const Radius.circular(9),
    );
    final b = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.34, size.width * 0.18,
          size.height * 0.1),
      const Radius.circular(9),
    );
    canvas.drawRRect(a, fill);
    canvas.drawRRect(a, stroke);
    canvas.drawRRect(
        b, Paint()..color = const Color(0xFFF8BBD0).withValues(alpha: 0.5));
    canvas.drawRRect(b, stroke);
    for (final dot in [0.7, 0.76, 0.82]) {
      canvas.drawCircle(Offset(size.width * dot, size.height * 0.375), 1.6,
          Paint()..color = Colors.white);
    }
  }

  void _drawSmallHeart(Canvas canvas, Offset c, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy + 8)
      ..cubicTo(c.dx - 18, c.dy - 4, c.dx - 8, c.dy - 18, c.dx, c.dy - 8)
      ..cubicTo(c.dx + 8, c.dy - 18, c.dx + 18, c.dy - 4, c.dx, c.dy + 8)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(color, const Color(0xFFF8BBD0), 0.45)!
              .withValues(alpha: 0.72));
  }

  void _drawTrophy(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final cup = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.68, size.height * 0.32, size.width * 0.16,
          size.height * 0.12),
      const Radius.circular(7),
    );
    final gold = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.72);
    canvas.drawRRect(cup, gold);
    canvas.drawRRect(cup, stroke);
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.44),
      Offset(size.width * 0.76, size.height * 0.54),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.54),
      Offset(size.width * 0.82, size.height * 0.54),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CompanionPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.expression != expression ||
        oldDelegate.prop != prop ||
        oldDelegate.extraProps != extraProps ||
        oldDelegate.tint != tint ||
        oldDelegate.performanceLevel != performanceLevel ||
        oldDelegate.showAura != showAura ||
        oldDelegate.gender != gender;
  }
}
