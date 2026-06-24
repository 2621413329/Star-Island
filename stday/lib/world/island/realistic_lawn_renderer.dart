import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

import '../../core/models/mood_island_config.dart';
import '../engine/world_state.dart';
import 'lawn_obstacle_mask.dart';

/// 程序化写实草坪：草簇 + 逐片渐变 + 环境光遮蔽 + 光照高光（非贴图）。
class RealisticLawnRenderer {
  const RealisticLawnRenderer({
    required this.compact,
    required this.time,
    required this.environment,
    required this.sceneSize,
    this.pass = LawnRenderPass.background,
    this.obstacleMask,
    this.clipPath,
  });

  final bool compact;
  final double time;
  final MoodEnvironmentState environment;
  final Size sceneSize;
  final LawnRenderPass pass;
  final LawnObstacleMask? obstacleMask;
  final Path? clipPath;

  static const _deepGreen = Color(0xFF1B5E20);
  static const _shadowGreen = Color(0xFF2E7D32);
  static const _midGreen = Color(0xFF4CAF50);
  static const _litGreen = Color(0xFF8BC34A);
  static const _tipGreen = Color(0xFFCDDC39);
  static const _highlight = Color(0xFFE8F5A8);

  void paint(
    Canvas canvas, {
    required MoodIslandConfig style,
    required double cx,
    required double cy,
    required double rx,
    required double ry,
  }) {
    final tufts = _generateTufts(cx, cy, rx, ry);
    tufts.sort((a, b) => a.depth.compareTo(b.depth));

    if (pass == LawnRenderPass.background) {
      _drawGroundTint(canvas, style, cx, cy, rx, ry);
      _drawAmbientOcclusion(canvas, tufts);
      for (final tuft in tufts) {
        _drawTuft(canvas, tuft, style);
      }
      _drawDirectionalAtmosphere(canvas, style, cx, cy, rx, ry);
      _drawSpecularHighlights(canvas, tufts);
      return;
    }

    for (final tuft in tufts) {
      _drawTuft(canvas, tuft, style, foreground: true);
    }
  }

  List<_GrassTuft> _generateTufts(double cx, double cy, double rx, double ry) {
    if (pass == LawnRenderPass.foreground) {
      return _generateForegroundTufts();
    }

    final rng = math.Random(53);
    const target = 360;
    final compactTarget = 250;
    final goal = compact ? compactTarget : target;
    final tufts = <_GrassTuft>[];
    var attempts = 0;
    while (tufts.length < goal && attempts < goal * 14) {
      attempts++;
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = math.sqrt(rng.nextDouble()) * 0.91;
      final x = cx + math.cos(angle) * rx * dist;
      final y = cy + math.sin(angle) * ry * dist;
      if (!_insideLawn(x, y)) continue;

      final norm = _toNormalized(Offset(x, y));
      if (obstacleMask?.blocksTuftBase(norm) ?? false) continue;

      tufts.add(
        _GrassTuft(
          base: Offset(x, y),
          normalizedBase: norm,
          depth: y + dist * 0.08,
          seed: tufts.length * 17 + rng.nextInt(997),
          bladeCount: 5 + rng.nextInt(4),
          spread: 2.2 + rng.nextDouble() * 2.8,
          heightScale: 0.85 + rng.nextDouble() * 0.45,
        ),
      );
    }
    return tufts;
  }

  List<_GrassTuft> _generateForegroundTufts() {
    final mask = obstacleMask;
    if (mask == null || mask.obstacles.isEmpty) return const [];

    final tufts = <_GrassTuft>[];
    var seed = 900;
    for (final obstacle in mask.obstacles) {
      if (obstacle.id == 'protagonist') continue;
      final rng = math.Random(obstacle.id.hashCode);
      final count = 4 + rng.nextInt(4);
      for (var i = 0; i < count; i++) {
        final t = (i + 1) / (count + 1);
        final norm = Offset(
          obstacle.rect.left + obstacle.rect.width * t,
          obstacle.rect.bottom + 0.003 + rng.nextDouble() * 0.010,
        );
        if (!_isOnGrowthIsland(norm)) continue;
        if (mask.blocksTuftBase(norm)) continue;

        final base = _toPixel(norm);
        if (!_insideLawn(base.dx, base.dy)) continue;

        tufts.add(
          _GrassTuft(
            base: base,
            normalizedBase: norm,
            depth: base.dy + 0.5,
            seed: seed++,
            bladeCount: 4 + rng.nextInt(3),
            spread: 1.8 + rng.nextDouble() * 1.6,
            heightScale: 0.72 + rng.nextDouble() * 0.28,
          ),
        );
      }
    }
    return tufts;
  }

  Offset _toNormalized(Offset pixel) => Offset(
        pixel.dx / sceneSize.width,
        pixel.dy / sceneSize.height,
      );

  Offset _toPixel(Offset normalized) => Offset(
        normalized.dx * sceneSize.width,
        normalized.dy * sceneSize.height,
      );

  bool _isOnGrowthIsland(Offset norm, {double inset = 0.88}) {
    const cx = 0.5;
    const cy = 0.54;
    const rx = 0.50 * inset;
    const ry = 0.125 * inset;
    final dx = (norm.dx - cx) / rx;
    final dy = (norm.dy - cy) / ry;
    return dx * dx + dy * dy <= 1;
  }

  void _drawGroundTint(
    Canvas canvas,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            -environment.lightDirection.dx * 0.35,
            -environment.lightDirection.dy * 0.35,
          ),
          radius: 0.95,
          colors: [
            Color.lerp(style.grass, _midGreen, 0.18)!,
            Color.lerp(style.grass, _shadowGreen, 0.12)!,
            Color.lerp(style.grass, _deepGreen, 0.22)!,
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(rect),
    );
  }

  void _drawAmbientOcclusion(Canvas canvas, List<_GrassTuft> tufts) {
    final ao = Paint();
    for (final tuft in tufts) {
      final rng = math.Random(tuft.seed);
      final w = 3.5 + rng.nextDouble() * 4.5;
      final h = w * 0.42;
      ao.shader = RadialGradient(
        colors: [
          _deepGreen.withValues(alpha: 0.22 + rng.nextDouble() * 0.10),
          _deepGreen.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCenter(
        center: tuft.base + Offset(0, 0.6),
        width: w * 2.4,
        height: h * 2.2,
      ));
      canvas.drawOval(
        Rect.fromCenter(center: tuft.base + Offset(0, 0.8), width: w * 2.2, height: h * 2),
        ao,
      );
    }
  }

  void _drawTuft(
    Canvas canvas,
    _GrassTuft tuft,
    MoodIslandConfig style, {
    bool foreground = false,
  }) {
    final rng = math.Random(tuft.seed);
    final light = environment.lightDirection;
    final sway = math.sin(time * 1.15 + tuft.seed * 0.11) * 0.65;

    for (var b = 0; b < tuft.bladeCount; b++) {
      final fan = (b / (tuft.bladeCount - 1).clamp(1, 8) - 0.5) * tuft.spread;
      final lean = fan + environment.shadowDx * 0.18 + sway * 0.35;
      final height =
          (foreground ? 2.8 : 3.6) + rng.nextDouble() * (foreground ? 3.2 : 4.2);
      final bladeH = height * tuft.heightScale;
      final base = tuft.base + Offset(fan * 0.35, 0);
      final ctrl = base + Offset(lean * 0.55, -bladeH * 0.42);
      final tip = base + Offset(lean + sway, -bladeH);

      if (!_bladeInsideLawn(base, tip)) continue;

      final bladePath = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
      final bounds = bladePath.getBounds().inflate(1.2);

      final facing = Offset(lean, -bladeH);
      final facingLen = facing.distance.clamp(0.001, 999);
      final lit = (facing.dx / facingLen * light.dx +
              facing.dy / facingLen * light.dy)
          .clamp(-1.0, 1.0);

      final baseColor = Color.lerp(
        _deepGreen,
        _shadowGreen,
        0.35 + rng.nextDouble() * 0.25,
      )!;
      final midColor = Color.lerp(style.grass, _midGreen, 0.25 + lit * 0.15)!;
      final tipColor = Color.lerp(
        lit > 0.05 ? _litGreen : _midGreen,
        lit > 0.25 ? _tipGreen : _litGreen,
        (lit * 0.5 + 0.5) * (0.35 + environment.lightWarmth * 0.25),
      )!;

      final strokeW = (foreground ? 0.50 : 0.55) + rng.nextDouble() * 0.45;
      final alphaScale = foreground ? 0.72 : 1.0;
      canvas.drawPath(
        bladePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              baseColor.withValues(alpha: 0.92 * alphaScale),
              midColor.withValues(alpha: 0.88 * alphaScale),
              tipColor.withValues(alpha: (0.82 + lit * 0.12) * alphaScale),
            ],
            stops: const [0.0, 0.48, 1.0],
          ).createShader(bounds),
      );

      if (lit > 0.18 && !foreground) {
        canvas.drawPath(
          bladePath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW * 0.42
            ..strokeCap = StrokeCap.round
            ..color = _highlight.withValues(alpha: 0.10 + lit * 0.14),
        );
      }
    }
  }

  void _drawDirectionalAtmosphere(
    Canvas canvas,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final light = environment.lightDirection;
    final warm = Rect.fromCenter(
      center: Offset(cx - light.dx * rx * 0.32, cy - light.dy * ry * 0.32),
      width: rx * 1.05,
      height: ry * 2.0,
    );
    canvas.drawOval(
      warm,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(
              _tipGreen,
              const Color(0xFFFFF3E0),
              environment.lightWarmth * 0.45,
            )!.withValues(alpha: 0.08 + environment.sunIntensity * 0.04),
            Colors.transparent,
          ],
        ).createShader(warm),
    );

    final cool = Rect.fromCenter(
      center: Offset(cx + light.dx * rx * 0.38, cy + light.dy * ry * 0.38),
      width: rx * 0.9,
      height: ry * 1.6,
    );
    canvas.drawOval(
      cool,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(style.grass, _deepGreen, 0.28)!
                .withValues(alpha: environment.ambientShadeStrength * 0.85),
            Colors.transparent,
          ],
        ).createShader(cool),
    );
  }

  void _drawSpecularHighlights(Canvas canvas, List<_GrassTuft> tufts) {
    if (environment.sunIntensity < 0.55) return;
    final light = environment.lightDirection;
    final dotPaint = Paint()..strokeCap = StrokeCap.round;
    for (final tuft in tufts) {
      if (tuft.seed % 5 != 0) continue;
      final rng = math.Random(tuft.seed + 7);
      final lean = (rng.nextDouble() - 0.5) * tuft.spread +
          environment.shadowDx * 0.15;
      final height = (3.8 + rng.nextDouble() * 3.6) * tuft.heightScale;
      final tip = tuft.base + Offset(lean, -height);
      final lit = lean * light.dx - light.dy;
      if (lit < 0.12) continue;
      dotPaint.color = _highlight.withValues(
        alpha: 0.16 + environment.sunIntensity * 0.10,
      );
      canvas.drawCircle(tip, 0.45 + rng.nextDouble() * 0.35, dotPaint);
    }
  }

  bool _insideLawn(double x, double y) {
    if (clipPath != null) {
      return clipPath!.contains(Offset(x, y));
    }
    return false;
  }

  bool _bladeInsideLawn(Offset base, Offset tip) {
    if (clipPath == null) return true;
    return clipPath!.contains(base) && clipPath!.contains(tip);
  }
}

class _GrassTuft {
  const _GrassTuft({
    required this.base,
    required this.normalizedBase,
    required this.depth,
    required this.seed,
    required this.bladeCount,
    required this.spread,
    required this.heightScale,
  });

  final Offset base;
  final Offset normalizedBase;
  final double depth;
  final int seed;
  final int bladeCount;
  final double spread;
  final double heightScale;
}
