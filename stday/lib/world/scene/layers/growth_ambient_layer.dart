import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, RadialGradient;

import 'world_layer.dart';

/// Growth Island 专属氛围：海鸥弧线、树叶飘落、建筑区柔光。
class GrowthAmbientLayer extends WorldLayer {
  GrowthAmbientLayer() : super(layerPriority: 12);

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    if (state.island.style.biome != 'growth_world') return;

    final s = sceneSize;
    final tier = state.island.prosperityTier;
    _drawSeagullPaths(canvas, s);
    _drawFloatingMotes(canvas, s);
    _drawFallingLeaves(canvas, s, density: tier >= 2 ? 14 : 8);
    _drawBuildingGlows(canvas, s);
  }

  /// 海鸥沿海面弧线飞行（固定路径，不随 mood 变化岛体）。
  void _drawSeagullPaths(Canvas canvas, Vector2 s) {
    const paths = [
      (0.08, 0.12, 0.92, 0.18, 0.32),
      (0.15, 0.16, 0.85, 0.14, 0.28),
      (0.05, 0.20, 0.95, 0.22, 0.35),
    ];
    for (var i = 0; i < paths.length; i++) {
      final (x0, y0, x1, y1, speed) = paths[i];
      final t = (_time * speed + i * 0.4) % 1.0;
      final cx = s.x * (x0 + (x1 - x0) * t);
      final arc = math.sin(t * math.pi);
      final cy = s.y * (y0 + (y1 - y0) * t) - arc * s.y * 0.04;
      _drawBird(canvas, Offset(cx, cy), wingPhase: _time * 4 + i);
    }
  }

  void _drawBird(Canvas canvas, Offset p, {required double wingPhase}) {
    final flap = math.sin(wingPhase) * 2;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: p + Offset(0, flap), width: 11, height: 7),
      0.15,
      2.1,
      false,
      paint,
    );
  }

  void _drawFloatingMotes(Canvas canvas, Vector2 s) {
    for (var i = 0; i < 18; i++) {
      final seed = i * 0.913;
      final x = s.x * (0.12 + (i * 0.071) % 0.76) +
          math.sin(_time * 0.28 + seed) * 10;
      final y =
          s.y * (0.30 + (i * 0.047) % 0.36) + math.sin(_time * 0.9 + seed) * 7;
      final pulse = 0.5 + 0.5 * math.sin(_time * 1.4 + seed);
      canvas.drawCircle(
        Offset(x, y),
        1.2 + pulse * 1.4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF9C4).withValues(alpha: 0.28 + pulse * 0.18),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 6)),
      );
    }
  }

  void _drawFallingLeaves(Canvas canvas, Vector2 s, {required int density}) {
    final count = density;
    for (var i = 0; i < count; i++) {
      final seed = i * 1.618;
      final x = (s.x * (0.15 + (i * 0.061) % 0.7) +
              math.sin(_time * 0.35 + seed) * 12) %
          s.x;
      final fall = (_time * (0.08 + (i % 3) * 0.02) + seed * 0.1) % 1.0;
      final y = s.y * (0.28 + fall * 0.38);
      final rot = _time * 0.8 + seed;
      final colors = [
        const Color(0xFF81C784),
        const Color(0xFFA5D6A7),
        const Color(0xFF66BB6A),
      ];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 5, height: 3),
        Paint()
          ..color =
              colors[i % colors.length].withValues(alpha: 0.45 + fall * 0.2),
      );
      canvas.restore();
    }
  }

  void _drawBuildingGlows(Canvas canvas, Vector2 s) {
    for (final b in state.buildings) {
      final anchor = Offset(b.anchor.dx * s.x, b.anchor.dy * s.y);
      final pulse = 0.85 + 0.15 * math.sin(_time * 1.8 + b.anchor.dx * 8);
      final radius = (22 + b.level * 4) * pulse;
      canvas.drawCircle(
        anchor + const Offset(0, -8),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF9C4).withValues(alpha: 0.14),
              state.island.style.accent.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: anchor, radius: radius)),
      );
    }
  }
}
