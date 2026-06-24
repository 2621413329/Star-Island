import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

import '../../core/models/mood_island_config.dart';
import '../engine/world_state.dart';
import '../../island/placement/island_placement.dart';

/// Growth Island 2.0 平地草坪：短密草坪纹理，严格限制在石质边缘以内。
class GrowthWorldGroundPainter {
  const GrowthWorldGroundPainter({
    required this.compact,
    required this.time,
    required this.environment,
  });

  final bool compact;
  final double time;
  final MoodEnvironmentState environment;

  void paint(Canvas canvas, Size size, IslandState island) {
    final style = island.style;
    final islandScale = island.radius.clamp(0.85, 1.25);
    final cx = size.width * 0.5;
    final cy = size.height * (compact ? 0.56 : 0.54);
    final compactScale = compact ? 1.414 : 1.0;
    final rx = size.width *
        IslandPlacement.growthRadiusX *
        (compact ? 0.952 : 1.0) *
        compactScale *
        islandScale *
        0.90;
    final ry = size.height *
        IslandPlacement.growthRadiusY *
        (compact ? 1.19 : 1.0) *
        compactScale *
        islandScale *
        0.90;

    _drawLawnBase(canvas, size, style, cx, cy, rx, ry);
    _drawDirectionalShading(canvas, style, cx, cy, rx, ry);
    _drawShortLawnBlades(canvas, style, cx, cy, rx, ry, seed: 53);
  }

  void _drawLawnBase(
    Canvas canvas,
    Size size,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final rng = math.Random(42);
    const greens = [0.0, 0.06, 0.12, -0.04, -0.08];
    for (var i = 0; i < 64; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = math.sqrt(rng.nextDouble()) * 0.88;
      final px = cx + math.cos(angle) * rx * dist;
      final py = cy + math.sin(angle) * ry * dist;
      if (!_insideEllipse(px, py, cx, cy, rx * 0.98, ry * 0.98)) continue;
      final w = 10 + rng.nextDouble() * 22;
      final h = w * (0.42 + rng.nextDouble() * 0.22);
      final tint = greens[i % greens.length];
      final base = tint >= 0
          ? Color.lerp(style.grass, Colors.white, tint.clamp(0, 0.35))!
          : Color.lerp(style.grass, const Color(0xFF2E7D32), -tint)!;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: w, height: h),
        Paint()
          ..color = base.withValues(alpha: 0.10 + rng.nextDouble() * 0.12),
      );
    }
  }

  void _drawDirectionalShading(
    Canvas canvas,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final light = environment.lightDirection;
    final warmCenter = Offset(
      cx - light.dx * rx * 0.35,
      cy - light.dy * ry * 0.35,
    );
    final warm = Rect.fromCenter(
      center: warmCenter,
      width: rx * 1.15,
      height: ry * 2.2,
    );
    canvas.drawOval(
      warm,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(
              Colors.white,
              const Color(0xFFFFF3E0),
              environment.lightWarmth,
            )!.withValues(alpha: 0.16),
            Colors.transparent,
          ],
        ).createShader(warm),
    );

    final coolCenter = Offset(
      cx + light.dx * rx * 0.42,
      cy + light.dy * ry * 0.42,
    );
    final cool = Rect.fromCenter(
      center: coolCenter,
      width: rx * 0.95,
      height: ry * 1.8,
    );
    canvas.drawOval(
      cool,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(style.grass, const Color(0xFF1B5E20), 0.18)!
                .withValues(alpha: environment.ambientShadeStrength),
            Colors.transparent,
          ],
        ).createShader(cool),
    );
  }

  void _drawShortLawnBlades(
    Canvas canvas,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry, {
    required int seed,
  }) {
    final rng = math.Random(seed);
    final stroke = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.75;
    final count = compact ? 180 : 240;
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = math.sqrt(rng.nextDouble()) * 0.92;
      final base = Offset(
        cx + math.cos(angle) * rx * dist,
        cy + math.sin(angle) * ry * dist,
      );
      if (!_insideEllipse(base.dx, base.dy, cx, cy, rx * 0.97, ry * 0.97)) {
        continue;
      }
      final lean = environment.shadowDx * 0.35 + (rng.nextDouble() - 0.5) * 0.25;
      final bladeH = 2.2 + rng.nextDouble() * 2.8;
      stroke.color = Color.lerp(
        style.grass,
        rng.nextBool() ? const Color(0xFF8BC34A) : const Color(0xFF689F38),
        0.18 + rng.nextDouble() * 0.22,
      )!.withValues(alpha: 0.38 + rng.nextDouble() * 0.28);
      for (var b = -1; b <= 1; b++) {
        canvas.drawLine(
          base,
          base + Offset(lean + b * 0.9, -bladeH),
          stroke,
        );
      }
    }
  }

  bool _insideEllipse(
    double x,
    double y,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final dx = (x - cx) / rx;
    final dy = (y - cy) / ry;
    return dx * dx + dy * dy <= 1;
  }
}
