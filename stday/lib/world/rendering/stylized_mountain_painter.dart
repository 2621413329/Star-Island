import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

/// Growth World 背景：三层 stylized 山脉 + 空气透视 + 清晨暖光。
class StylizedMountainPainter {
  const StylizedMountainPainter();

  void paintGrowthBackground(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final horizon = size.height * 0.38;
    _drawAtmosphericHaze(canvas, size, horizon);
    _drawFarRange(canvas, size, horizon);
    _drawMidRange(canvas, size, horizon);
    _drawNearHills(canvas, size, horizon);
  }

  void _drawAtmosphericHaze(Canvas canvas, Size size, double horizon) {
    final rect = Rect.fromLTWH(
      0,
      horizon - size.height * 0.12,
      size.width,
      size.height * 0.14,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF8E1).withValues(alpha: 0.06),
            const Color(0xFFB3D9E8).withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  void _drawFarRange(Canvas canvas, Size size, double horizon) {
    final path = _buildSilhouette(
      size: size,
      baseY: horizon,
      amp: size.height * 0.095,
      seed: 1.7,
      segments: 32,
      smoothness: 0.62,
    );
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.85, -0.6),
          end: const Alignment(0.95, 0.8),
          colors: [
            const Color(0xFFB8C9D4).withValues(alpha: 0.30),
            const Color(0xFF9AADB8).withValues(alpha: 0.22),
            const Color(0xFF8A9DA8).withValues(alpha: 0.16),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(bounds),
    );
    _drawRidgeShadows(
      canvas,
      size,
      horizon,
      amp: size.height * 0.095,
      seed: 1.7,
      alpha: 0.06,
      segments: 32,
    );
  }

  void _drawMidRange(Canvas canvas, Size size, double horizon) {
    final baseY = horizon + size.height * 0.012;
    final path = _buildSilhouette(
      size: size,
      baseY: baseY,
      amp: size.height * 0.128,
      seed: 4.3,
      segments: 28,
      smoothness: 0.55,
      xOffset: size.width * 0.04,
    );
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.9, -0.55),
          end: const Alignment(1.0, 0.85),
          colors: [
            const Color(0xFF9AAFB8).withValues(alpha: 0.42),
            const Color(0xFF7E939E).withValues(alpha: 0.34),
            const Color(0xFF657A86).withValues(alpha: 0.28),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(bounds),
    );
    _drawForestPatches(canvas, size, baseY, seed: 4.3, count: 9, alpha: 0.10);
    _drawRockTexture(canvas, path, alpha: 0.07);
    _drawRidgeShadows(
      canvas,
      size,
      baseY,
      amp: size.height * 0.128,
      seed: 4.3,
      alpha: 0.10,
      segments: 28,
      xOffset: size.width * 0.04,
    );
    _drawSunlitRidges(
      canvas,
      size,
      baseY,
      amp: size.height * 0.128,
      seed: 4.3,
      segments: 28,
      xOffset: size.width * 0.04,
    );
  }

  void _drawNearHills(Canvas canvas, Size size, double horizon) {
    final baseY = horizon + size.height * 0.028;
    final path = _buildSilhouette(
      size: size,
      baseY: baseY,
      amp: size.height * 0.072,
      seed: 8.1,
      segments: 22,
      smoothness: 0.78,
      rounded: true,
    );
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.75, -0.45),
          end: const Alignment(0.85, 0.9),
          colors: [
            const Color(0xFF8FAF98).withValues(alpha: 0.48),
            const Color(0xFF6E8F78).withValues(alpha: 0.40),
            const Color(0xFF5A7562).withValues(alpha: 0.34),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );
    _drawForestPatches(canvas, size, baseY, seed: 8.1, count: 7, alpha: 0.14);
    _drawHillTreeSilhouettes(canvas, size, baseY, seed: 8.1);
    _drawSunlitRidges(
      canvas,
      size,
      baseY,
      amp: size.height * 0.072,
      seed: 8.1,
      segments: 22,
      rounded: true,
      highlightAlpha: 0.12,
    );
  }

  Path _buildSilhouette({
    required Size size,
    required double baseY,
    required double amp,
    required double seed,
    required int segments,
    required double smoothness,
    double xOffset = 0,
    bool rounded = false,
  }) {
    final points = <Offset>[];
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final x = size.width * t + xOffset * (t - 0.5);
      final h = _ridgeHeight(
        t,
        seed: seed,
        amp: amp,
        rounded: rounded,
      );
      points.add(Offset(x, baseY - h));
    }

    final path = Path()..moveTo(-size.width * 0.02, baseY);
    path.lineTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = prev.dx + (curr.dx - prev.dx) * smoothness;
      path.cubicTo(
        midX,
        prev.dy,
        size.width * (i / segments) - (curr.dx - midX),
        curr.dy,
        curr.dx,
        curr.dy,
      );
    }

    path
      ..lineTo(size.width * 1.02, baseY)
      ..close();
    return path;
  }

  double _ridgeHeight(
    double t, {
    required double seed,
    required double amp,
    bool rounded = false,
  }) {
    final r = t * math.pi * 2;
    var profile = 0.38 +
        0.26 * math.sin(r * 0.85 + seed) +
        0.16 * math.sin(r * 1.95 + seed * 1.4) +
        0.11 * math.sin(r * 3.35 + seed * 0.6) +
        0.07 * math.sin(r * 5.1 + seed * 2.1);
    if (rounded) {
      profile = math.pow(profile, 1.35).toDouble();
    }
    return amp * profile.clamp(0.22, 1.0);
  }

  void _drawRidgeShadows(
    Canvas canvas,
    Size size,
    double baseY, {
    required double amp,
    required double seed,
    required double alpha,
    required int segments,
    double xOffset = 0,
  }) {
    final shadow = Paint()
      ..color = const Color(0xFF3E5A66).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (var i = 2; i < segments - 1; i += 2) {
      final t = i / segments;
      final x = size.width * t + xOffset * (t - 0.5);
      final h = _ridgeHeight(t, seed: seed, amp: amp);
      final peak = Offset(x, baseY - h);
      canvas.drawLine(
        peak,
        peak + Offset(size.width * 0.035, h * 0.55),
        shadow,
      );
    }
  }

  void _drawSunlitRidges(
    Canvas canvas,
    Size size,
    double baseY, {
    required double amp,
    required double seed,
    required int segments,
    double xOffset = 0,
    bool rounded = false,
    double highlightAlpha = 0.09,
  }) {
    final light = Paint()
      ..color = const Color(0xFFFFF3C8).withValues(alpha: highlightAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < segments; i += 3) {
      final t = i / segments;
      final x = size.width * t + xOffset * (t - 0.5);
      final h = _ridgeHeight(t, seed: seed, amp: amp, rounded: rounded);
      final peak = Offset(x, baseY - h);
      canvas.drawLine(
        peak,
        peak + Offset(-size.width * 0.028, h * 0.42),
        light,
      );
    }
  }

  void _drawForestPatches(
    Canvas canvas,
    Size size,
    double baseY, {
    required double seed,
    required int count,
    required double alpha,
  }) {
    final rng = math.Random((seed * 1000).round());
    for (var i = 0; i < count; i++) {
      final t = 0.08 + rng.nextDouble() * 0.84;
      final x = size.width * t;
      final h = _ridgeHeight(t, seed: seed, amp: size.height * 0.11);
      final center = Offset(x, baseY - h * 0.72);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width * (0.04 + rng.nextDouble() * 0.03),
          height: size.height * (0.018 + rng.nextDouble() * 0.012),
        ),
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF3E5A48).withValues(alpha: alpha + 0.04),
              const Color(0xFF3E5A48).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCenter(
            center: center,
            width: size.width * 0.06,
            height: size.height * 0.03,
          )),
      );
    }
  }

  void _drawRockTexture(Canvas canvas, Path mountain, {required double alpha}) {
    final bounds = mountain.getBounds();
    final stroke = Paint()
      ..color = const Color(0xFF546E7A).withValues(alpha: alpha)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.clipPath(mountain);
    for (var i = 0; i < 18; i++) {
      final x = bounds.left + bounds.width * (0.08 + i * 0.048);
      final y0 = bounds.top + bounds.height * (0.25 + (i % 4) * 0.12);
      canvas.drawLine(
        Offset(x, y0),
        Offset(x + 3, y0 + bounds.height * 0.14),
        stroke,
      );
    }
    canvas.restore();
  }

  void _drawHillTreeSilhouettes(
    Canvas canvas,
    Size size,
    double baseY, {
    required double seed,
  }) {
    final rng = math.Random((seed * 777).round());
    final tree = Paint()
      ..color = const Color(0xFF3D5A44).withValues(alpha: 0.38);

    for (var i = 0; i < 6; i++) {
      final t = 0.12 + rng.nextDouble() * 0.76;
      final x = size.width * t;
      final h = _ridgeHeight(
        t,
        seed: seed,
        amp: size.height * 0.072,
        rounded: true,
      );
      final root = Offset(x, baseY - h * 0.88);
      canvas.drawLine(
        root,
        root + Offset(0, -10 - rng.nextDouble() * 8),
        tree..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        root + Offset(0, -14 - rng.nextDouble() * 6),
        5 + rng.nextDouble() * 4,
        tree,
      );
    }
  }
}
