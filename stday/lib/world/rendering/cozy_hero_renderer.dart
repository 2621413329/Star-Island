import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

import '../engine/world_state.dart';

/// Growth Island Mascot：奶油白软陶公仔，极简、治愈、无服装配饰。
class CozyHeroRenderer {
  CozyHeroRenderer._();

  /// [CompanionPainter] / Avatar 用：在矩形内绘制。
  static void paintInRect(
    Canvas canvas,
    Size size, {
    String expression = 'calm',
    String prop = 'none',
    List<String> extraProps = const [],
    String? gender,
    Color? starCoreColor,
    double performanceLevel = 0,
  }) {
    final charSize = size.width * 0.88;
    paintAt(
      canvas,
      groundX: size.width * 0.5,
      groundY: size.height * 0.76,
      charSize: charSize,
      expression: expression,
      prop: prop,
      extraProps: extraProps,
      gender: gender,
      starCoreColor: starCoreColor,
      performanceLevel: performanceLevel,
      bodyBob: math.sin(performanceLevel * math.pi) * charSize * 0.035,
      scale: 1 + performanceLevel * 0.06,
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
    List<String> extraProps = const [],
    String? gender,
    Color? starCoreColor,
    double performanceLevel = 0,
    double bodyBob = 0,
    double dx = 0,
    double dy = 0,
    double rotation = 0,
    double scale = 1,
    MoodEnvironmentState? lighting,
  }) {
    final cx = groundX + dx;
    final cy = groundY - charSize * 0.55 + bodyBob + dy;
    final female = _isFemale(gender);
    final env = lighting ?? _defaultLighting;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    canvas.scale(scale, scale);

    _drawGroundContactShadow(canvas, charSize, env);
    _drawArms(canvas, charSize, female: female, lighting: env);
    _drawBody(
      canvas,
      charSize,
      female: female,
      starCoreColor: starCoreColor ?? const Color(0xFFFFF6D8),
      performanceLevel: performanceLevel,
      lighting: env,
    );
    _drawProps(
      canvas,
      charSize,
      [prop, ...extraProps],
      female: female,
    );
    _drawHead(canvas, charSize, expression, female: female, lighting: env);

    canvas.restore();
  }

  static const _defaultLighting = MoodEnvironmentState(
    skyTop: Color(0xFFE8F6FA),
    skyBottom: Color(0xFFD4EFF5),
    sea: Color(0xFF5BB5D5),
    sunIntensity: 1.0,
    cloudDensity: 0.3,
    windStrength: 0.2,
    waveIntensity: 0.3,
    particlePreset: 'bloom',
    rain: false,
    colorGrade: ColorGrade.neutral,
  );

  static bool _isFemale(String? gender) {
    final normalized = gender?.toLowerCase();
    return normalized == 'female' || normalized == 'girl' || normalized == '女';
  }

  static void _drawGroundContactShadow(
    Canvas canvas,
    double charSize,
    MoodEnvironmentState env,
  ) {
    final shadowCenter = Offset(
      charSize * env.shadowDx * 0.42,
      charSize * 0.55 + env.shadowDy * charSize * 0.12,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: charSize * (0.50 + env.shadowStretch.abs() * 0.08),
        height: charSize * (0.11 + env.shadowStretch.abs() * 0.03),
      ),
      Paint()
        ..color = const Color(0xFF2B4B5A).withValues(alpha: env.shadowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter + Offset(charSize * env.shadowDx * 0.08, 1),
        width: charSize * (0.34 + env.shadowStretch.abs() * 0.05),
        height: charSize * 0.07,
      ),
      Paint()
        ..color = const Color(0xFF1F3A47).withValues(alpha: env.shadowAlpha * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  static Paint _clayPaint(
    Rect bounds, {
    Alignment center = const Alignment(-0.34, -0.48),
    MoodEnvironmentState? lighting,
  }) {
    final warm = lighting?.lightWarmth ?? 0.35;
    return Paint()
      ..shader = RadialGradient(
        center: center,
        radius: 1.08,
        colors: [
          Color.lerp(
            const Color(0xFFFFFFFF),
            const Color(0xFFFFF3E0),
            warm * 0.35,
          )!,
          Color.lerp(
            const Color(0xFFFFFBF2),
            const Color(0xFFFFE8C8),
            warm * 0.25,
          )!,
          const Color(0xFFECE5D4),
          const Color(0xFFCFC5AF),
        ],
        stops: const [0.0, 0.36, 0.72, 1.0],
      ).createShader(bounds);
  }

  static Paint _softOutline(double charSize) {
    return Paint()
      ..color = const Color(0xFFD8D1BF).withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = charSize * 0.010;
  }

  static void _drawHead(
    Canvas canvas,
    double charSize,
    String expression, {
    required bool female,
    required MoodEnvironmentState lighting,
  }) {
    final headCenter = Offset(0, -charSize * 0.265);
    final headWidth = charSize * (female ? 0.70 : 0.73);
    final headHeight = charSize * (female ? 0.67 : 0.66);
    final headPath = _bunHeadPath(
      center: headCenter,
      width: headWidth,
      height: headHeight,
      cheekSoftness: female ? 1.05 : 1.00,
    );
    final bounds = Rect.fromCenter(
      center: headCenter,
      width: headWidth,
      height: headHeight,
    );

    canvas.drawPath(
      headPath.shift(Offset(charSize * 0.035, charSize * 0.040)),
      Paint()..color = const Color(0xFF6B6252).withValues(alpha: 0.10),
    );
    canvas.drawPath(headPath, _clayPaint(bounds.inflate(charSize * 0.10), lighting: lighting));
    _drawVolumeShade(
      canvas,
      headPath,
      bounds,
      charSize,
      strength: lighting.ambientShadeStrength,
      lightDirection: lighting.lightDirection,
    );
    canvas.drawPath(headPath, _softOutline(charSize));

    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter + Offset(-headWidth * 0.18, -headHeight * 0.19),
        width: headWidth * 0.26,
        height: headHeight * 0.16,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );

    _drawFace(canvas, headCenter, charSize, expression, female: female);
  }

  static Path _bunHeadPath({
    required Offset center,
    required double width,
    required double height,
    required double cheekSoftness,
  }) {
    final halfW = width * 0.5;
    final top = center.dy - height * 0.48;
    final upperY = center.dy - height * 0.36;
    final cheekY = center.dy + height * 0.08;
    final jawY = center.dy + height * 0.34;
    final bottomY = center.dy + height * 0.45;
    return Path()
      ..moveTo(center.dx, top)
      ..cubicTo(
        center.dx - halfW * 0.34,
        upperY,
        center.dx - halfW * 0.92 * cheekSoftness,
        center.dy - height * 0.20,
        center.dx - halfW * 0.98,
        cheekY,
      )
      ..cubicTo(
        center.dx - halfW * 0.95,
        jawY,
        center.dx - halfW * 0.42,
        bottomY,
        center.dx - halfW * 0.08,
        bottomY,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + height * 0.47,
        center.dx + halfW * 0.08,
        bottomY,
      )
      ..cubicTo(
        center.dx + halfW * 0.42,
        bottomY,
        center.dx + halfW * 0.95,
        jawY,
        center.dx + halfW * 0.98,
        cheekY,
      )
      ..cubicTo(
        center.dx + halfW * 0.92 * cheekSoftness,
        center.dy - height * 0.20,
        center.dx + halfW * 0.34,
        upperY,
        center.dx,
        top,
      )
      ..close();
  }

  static void _drawVolumeShade(
    Canvas canvas,
    Path path,
    Rect bounds,
    double charSize, {
    required double strength,
    Offset lightDirection = const Offset(-1, -0.2),
  }) {
    final shadeSide = lightDirection.dx >= 0
        ? Alignment.centerRight
        : Alignment.centerLeft;
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      bounds.inflate(charSize * 0.12),
      Paint()
        ..shader = LinearGradient(
          begin: lightDirection.dx >= 0
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: shadeSide,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
            const Color(0xFF8A806D).withValues(alpha: strength),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(bounds.inflate(charSize * 0.12)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          bounds.center.dx + lightDirection.dx * bounds.width * 0.08,
          bounds.bottom - bounds.height * 0.05,
        ),
        width: bounds.width * 0.74,
        height: bounds.height * 0.20,
      ),
      Paint()
        ..color = const Color(0xFF756B5B).withValues(alpha: strength * 0.42),
    );
    canvas.restore();
  }

  static void _drawFace(
    Canvas canvas,
    Offset headCenter,
    double charSize,
    String expression, {
    required bool female,
  }) {
    final eyeY = headCenter.dy + charSize * 0.028;
    final eyeOffset = charSize * (female ? 0.088 : 0.094);
    final eyeR = charSize * 0.025;
    final eyePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.45),
        radius: 0.9,
        colors: [Color(0xFF1F211F), Color(0xFF050505)],
      ).createShader(Rect.fromCircle(center: headCenter, radius: charSize));

    canvas.drawCircle(Offset(headCenter.dx - eyeOffset, eyeY), eyeR, eyePaint);
    canvas.drawCircle(Offset(headCenter.dx + eyeOffset, eyeY), eyeR, eyePaint);

    final mouthCenter = headCenter + Offset(0, charSize * 0.098);
    final mouthPaint = Paint()
      ..color = const Color(0xFF5F584F).withValues(alpha: 0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = charSize * 0.014
      ..strokeCap = StrokeCap.round;
    final smileLift =
        expression == 'happy' || expression == 'proud' ? 1.12 : 0.82;
    canvas.drawArc(
      Rect.fromCenter(
        center: mouthCenter,
        width: charSize * 0.128,
        height: charSize * 0.062 * smileLift,
      ),
      0.16,
      math.pi - 0.32,
      false,
      mouthPaint,
    );
  }

  static void _drawBody(
    Canvas canvas,
    double charSize, {
    required bool female,
    required Color starCoreColor,
    required double performanceLevel,
    required MoodEnvironmentState lighting,
  }) {
    final bodyCenter = Offset(0, charSize * 0.155);
    final bodyWidth = charSize * (female ? 0.52 : 0.56);
    final bodyHeight = charSize * (female ? 0.58 : 0.56);
    final bodyRect = Rect.fromCenter(
      center: bodyCenter,
      width: bodyWidth,
      height: bodyHeight,
    );
    final body = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(bodyWidth * 0.48),
    );

    _drawLegs(canvas, charSize, female: female);
    canvas.drawRRect(
      body.shift(Offset(charSize * 0.028, charSize * 0.032)),
      Paint()..color = const Color(0xFF6B6252).withValues(alpha: 0.10),
    );
    canvas.drawRRect(body, _clayPaint(bodyRect.inflate(charSize * 0.08), lighting: lighting));
    _drawRRectVolumeShade(
      canvas,
      body,
      bodyRect,
      charSize,
      strength: lighting.ambientShadeStrength,
      lightDirection: lighting.lightDirection,
    );
    canvas.drawRRect(body, _softOutline(charSize));

    canvas.drawOval(
      Rect.fromCenter(
        center: bodyCenter + Offset(-bodyWidth * 0.16, -bodyHeight * 0.18),
        width: bodyWidth * 0.30,
        height: bodyHeight * 0.16,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );

    _drawStarCore(
      canvas,
      bodyCenter + Offset(0, -bodyHeight * 0.02),
      charSize,
      starCoreColor,
      performanceLevel,
    );
  }

  static void _drawRRectVolumeShade(
    Canvas canvas,
    RRect rrect,
    Rect bounds,
    double charSize, {
    required double strength,
    Offset lightDirection = const Offset(-1, -0.2),
  }) {
    final shadeSide = lightDirection.dx >= 0
        ? Alignment.centerRight
        : Alignment.centerLeft;
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      bounds.inflate(charSize * 0.10),
      Paint()
        ..shader = LinearGradient(
          begin: lightDirection.dx >= 0
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: shadeSide,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
            const Color(0xFF8A806D).withValues(alpha: strength),
          ],
          stops: const [0.0, 0.46, 1.0],
        ).createShader(bounds.inflate(charSize * 0.10)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          bounds.center.dx + lightDirection.dx * bounds.width * 0.08,
          bounds.bottom - bounds.height * 0.08,
        ),
        width: bounds.width * 0.72,
        height: bounds.height * 0.22,
      ),
      Paint()
        ..color = const Color(0xFF756B5B).withValues(alpha: strength * 0.40),
    );
    canvas.restore();
  }

  static void _drawArms(
    Canvas canvas,
    double charSize, {
    required bool female,
    required MoodEnvironmentState lighting,
  }) {
    final armPaint = _clayPaint(Rect.fromCenter(
      center: Offset.zero,
      width: charSize * 0.70,
      height: charSize * 0.70,
    ), lighting: lighting);
    final outline = _softOutline(charSize);
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(side * charSize * (female ? 0.210 : 0.225),
          -charSize * (female ? 0.020 : 0.024));
      final hand = shoulder +
          Offset(
            side * charSize * (female ? 0.086 : 0.100),
            charSize * (female ? 0.275 : 0.260),
          );
      final arm = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(
          shoulder.dx + side * charSize * 0.020,
          shoulder.dy + charSize * 0.132,
          hand.dx,
          hand.dy,
        );
      canvas.drawPath(
        arm.shift(Offset(charSize * 0.018 * side, charSize * 0.020)),
        Paint()
          ..color = const Color(0xFF6B6252).withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = charSize * 0.082
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        arm,
        armPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = charSize * 0.080
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        arm,
        outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = charSize * 0.010
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  static void _drawLegs(
    Canvas canvas,
    double charSize, {
    required bool female,
  }) {
    final legPaint = _clayPaint(Rect.fromCenter(
      center: Offset(0, charSize * 0.36),
      width: charSize * 0.42,
      height: charSize * 0.24,
    ));
    final outline = _softOutline(charSize);
    final legY = charSize * 0.465;
    final legOffset = charSize * (female ? 0.083 : 0.096);
    for (final dx in [-legOffset, legOffset]) {
      final foot = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(dx, legY),
          width: charSize * (female ? 0.132 : 0.146),
          height: charSize * 0.165,
        ),
        Radius.circular(charSize * 0.068),
      );
      canvas.drawRRect(
        foot.shift(Offset(charSize * 0.012, charSize * 0.014)),
        Paint()..color = const Color(0xFF6B6252).withValues(alpha: 0.08),
      );
      canvas.drawRRect(foot, legPaint);
      canvas.drawRRect(foot, outline);
    }
  }

  static void _drawProps(
    Canvas canvas,
    double charSize,
    List<String> props, {
    required bool female,
  }) {
    final visible = props
        .where((p) => p != 'none' && p != 'stars')
        .toSet()
        .toList();
    if (visible.isEmpty) return;

    final anchors = visible.length == 1
        ? [Offset(charSize * 0.24, charSize * -0.20)]
        : <Offset>[
            Offset(charSize * (female ? 0.26 : 0.28), charSize * 0.18),
            Offset(charSize * -0.32, charSize * 0.05),
            Offset(charSize * 0.36, charSize * -0.04),
          ];
    for (var i = 0; i < visible.length && i < anchors.length; i++) {
      _drawProp(
        canvas,
        charSize,
        visible[i],
        anchor: anchors[i],
        female: female,
      );
    }
  }

  static void _drawProp(
    Canvas canvas,
    double charSize,
    String prop, {
    required Offset anchor,
    required bool female,
  }) {
    if (prop == 'none' || prop == 'stars') return;
    final scale = charSize / 72;
    final shadow = Paint()
      ..color = const Color(0xFF6B6252).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final stroke = Paint()
      ..color = const Color(0xFF6E6256).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (prop) {
      case 'workbook':
      case 'exam_paper':
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: anchor,
            width: 17 * scale,
            height: 22 * scale,
          ),
          Radius.circular(3 * scale),
        );
        canvas.drawRRect(rect.shift(Offset(2 * scale, 2 * scale)), shadow);
        canvas.drawRRect(
          rect,
          Paint()..color = const Color(0xFFFFF7E2),
        );
        canvas.drawRRect(rect, stroke);
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
            anchor + Offset(-5 * scale, (-5 + i * 5) * scale),
            anchor + Offset(5 * scale, (-5 + i * 5) * scale),
            stroke..color = const Color(0xFFB9A98D).withValues(alpha: 0.55),
          );
        }
      case 'ball':
      case 'basketball':
        canvas.drawCircle(anchor, 9 * scale, shadow);
        canvas.drawCircle(
          anchor,
          8 * scale,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.45),
              colors: prop == 'basketball'
                  ? const [Color(0xFFFFE0B2), Color(0xFFFF8A50)]
                  : const [Color(0xFFFFFFFF), Color(0xFFFFC46B)],
            ).createShader(Rect.fromCircle(center: anchor, radius: 9 * scale)),
        );
        canvas.drawCircle(anchor, 8 * scale, stroke);
        if (prop == 'basketball') {
          canvas.drawLine(
            anchor + Offset(-7 * scale, 0),
            anchor + Offset(7 * scale, 0),
            stroke..strokeWidth = 1.1 * scale,
          );
          canvas.drawArc(
            Rect.fromCircle(center: anchor, radius: 7 * scale),
            0.4,
            2.4,
            false,
            stroke..strokeWidth = 1.1 * scale,
          );
        }
      case 'water_bottle':
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: anchor + Offset(0, 2 * scale),
            width: 10 * scale,
            height: 20 * scale,
          ),
          Radius.circular(4 * scale),
        );
        canvas.drawRRect(body.shift(Offset(1.5 * scale, 1.5 * scale)), shadow);
        canvas.drawRRect(
          body,
          Paint()..color = const Color(0xFFB3E5FC),
        );
        canvas.drawRRect(body, stroke);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: anchor + Offset(0, -10 * scale),
              width: 6 * scale,
              height: 4 * scale,
            ),
            Radius.circular(2 * scale),
          ),
          Paint()..color = const Color(0xFF81D4FA),
        );
      case 'palette':
        final board = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: anchor,
            width: 22 * scale,
            height: 16 * scale,
          ),
          Radius.circular(8 * scale),
        );
        canvas.drawRRect(board, Paint()..color = const Color(0xFFFFE0B2));
        canvas.drawRRect(board, stroke);
        final dots = [
          const Color(0xFFE57373),
          const Color(0xFFFFD54F),
          const Color(0xFF64B5F6),
          const Color(0xFF81C784),
        ];
        for (var i = 0; i < dots.length; i++) {
          canvas.drawCircle(
            anchor + Offset((-6 + i * 4) * scale, (-2 + (i % 2)) * scale),
            2.2 * scale,
            Paint()..color = dots[i],
          );
        }
      case 'badminton_racket':
        canvas.drawOval(
          Rect.fromCenter(
            center: anchor + Offset(1 * scale, -6 * scale),
            width: 14 * scale,
            height: 18 * scale,
          ),
          stroke,
        );
        canvas.drawLine(
          anchor + Offset(3 * scale, 3 * scale),
          anchor + Offset(10 * scale, 16 * scale),
          stroke..strokeWidth = 2.0 * scale,
        );
      case 'friends':
      case 'chat_bubbles':
        for (final offset in [Offset.zero, Offset(7 * scale, -5 * scale)]) {
          final bubble = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: anchor + offset,
              width: 16 * scale,
              height: 11 * scale,
            ),
            Radius.circular(6 * scale),
          );
          canvas.drawRRect(
            bubble,
            Paint()..color = const Color(0xFFE4F4FF),
          );
          canvas.drawRRect(bubble, stroke);
        }
      case 'heart':
        final heart = Path()
          ..moveTo(anchor.dx, anchor.dy + 7 * scale)
          ..cubicTo(
              anchor.dx - 14 * scale,
              anchor.dy - 2 * scale,
              anchor.dx - 7 * scale,
              anchor.dy - 12 * scale,
              anchor.dx,
              anchor.dy - 5 * scale)
          ..cubicTo(
              anchor.dx + 7 * scale,
              anchor.dy - 12 * scale,
              anchor.dx + 14 * scale,
              anchor.dy - 2 * scale,
              anchor.dx,
              anchor.dy + 7 * scale)
          ..close();
        canvas.drawPath(heart.shift(Offset(1.5 * scale, 1.5 * scale)), shadow);
        canvas.drawPath(heart, Paint()..color = const Color(0xFFFFA7B8));
      case 'home':
        final house = Path()
          ..moveTo(anchor.dx - 9 * scale, anchor.dy)
          ..lineTo(anchor.dx, anchor.dy - 9 * scale)
          ..lineTo(anchor.dx + 9 * scale, anchor.dy)
          ..lineTo(anchor.dx + 7 * scale, anchor.dy + 10 * scale)
          ..lineTo(anchor.dx - 7 * scale, anchor.dy + 10 * scale)
          ..close();
        canvas.drawPath(house, Paint()..color = const Color(0xFFFFE0B2));
        canvas.drawPath(house, stroke);
      case 'music':
        canvas.drawCircle(anchor + Offset(-3 * scale, 8 * scale), 4 * scale,
            Paint()..color = const Color(0xFF8EC5FF));
        canvas.drawLine(
            anchor + Offset(1 * scale, 8 * scale),
            anchor + Offset(1 * scale, -8 * scale),
            stroke..strokeWidth = 2 * scale);
        canvas.drawLine(anchor + Offset(1 * scale, -8 * scale),
            anchor + Offset(9 * scale, -5 * scale), stroke);
      case 'umbrella':
        final canopy = Path()
          ..moveTo(anchor.dx - 12 * scale, anchor.dy)
          ..quadraticBezierTo(anchor.dx, anchor.dy - 14 * scale,
              anchor.dx + 12 * scale, anchor.dy)
          ..close();
        canvas.drawPath(canopy, Paint()..color = const Color(0xFFB9B0D8));
        canvas.drawPath(canopy, stroke);
        canvas.drawLine(anchor, anchor + Offset(0, 14 * scale), stroke);
      case 'trophy':
      case 'medal':
        canvas.drawCircle(
            anchor, 8 * scale, Paint()..color = const Color(0xFFFFD76A));
        canvas.drawCircle(anchor, 8 * scale, stroke);
        _drawSpark(
            canvas, anchor, 4 * scale, Colors.white.withValues(alpha: 0.85));
      case 'game_controller':
        final pad = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: anchor, width: 24 * scale, height: 13 * scale),
          Radius.circular(7 * scale),
        );
        canvas.drawRRect(pad, Paint()..color = const Color(0xFFE8E3D6));
        canvas.drawRRect(pad, stroke);
        canvas.drawCircle(anchor + Offset(6 * scale, -1 * scale), 1.8 * scale,
            Paint()..color = const Color(0xFF5D4E44));
        canvas.drawLine(anchor + Offset(-8 * scale, 0),
            anchor + Offset(-3 * scale, 0), stroke);
        canvas.drawLine(anchor + Offset(-5.5 * scale, -2.5 * scale),
            anchor + Offset(-5.5 * scale, 2.5 * scale), stroke);
      case 'running_shoes':
        for (final dy in [-3.0, 4.0]) {
          final shoe = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: anchor + Offset(0, dy * scale),
              width: 18 * scale,
              height: 7 * scale,
            ),
            Radius.circular(4 * scale),
          );
          canvas.drawRRect(shoe, Paint()..color = const Color(0xFFDDECCF));
          canvas.drawRRect(shoe, stroke);
        }
      case 'glasses':
        for (final dx in [-5.0, 5.0]) {
          canvas.drawCircle(anchor + Offset(dx * scale, 0), 4 * scale, stroke);
        }
        canvas.drawLine(anchor + Offset(-1 * scale, 0),
            anchor + Offset(1 * scale, 0), stroke);
      default:
        _drawSpark(canvas, anchor, 8 * scale, const Color(0xFFFFF59D));
    }
  }

  static void _drawSpark(
      Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.30, center.dy - radius * 0.30)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.30, center.dy + radius * 0.30)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.30, center.dy + radius * 0.30)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.30, center.dy - radius * 0.30)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static void _drawStarCore(
    Canvas canvas,
    Offset center,
    double charSize,
    Color color,
    double performanceLevel,
  ) {
    final pulse = 0.82 + 0.18 * math.sin(performanceLevel * math.pi);
    final glowRadius = charSize * (0.160 + performanceLevel * 0.032);
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.52 * pulse),
            color.withValues(alpha: 0.22 * pulse),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );

    final star = _starPath(center, charSize * 0.088);
    canvas.drawPath(
      star,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            color.withValues(alpha: 0.90),
          ],
        ).createShader(
            Rect.fromCircle(center: center, radius: charSize * 0.105)),
    );
    canvas.drawPath(
      star,
      Paint()
        ..color = color.withValues(alpha: 0.46)
        ..style = PaintingStyle.stroke
        ..strokeWidth = charSize * 0.008
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static Path _starPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.48;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }
}
