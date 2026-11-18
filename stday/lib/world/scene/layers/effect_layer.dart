import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

import '../../engine/world_state.dart';
import '../../rendering/retained_picture.dart';
import '../world_paint_pass.dart';
import 'world_layer.dart';

class EffectLayer extends WorldLayer {
  EffectLayer({this.highlightedEventId}) : super(layerPriority: 900);

  String? highlightedEventId;

  double _time = 0;
  final RetainedPicture _anchorGlow = RetainedPicture();
  final Paint _dot = Paint();
  final Paint _rain = Paint()
    ..color = const Color(0x52FFFFFF)
    ..strokeWidth = 1.1;
  final Paint _leafFill = Paint()
    ..color = const Color(0x8CFFCC80)
    ..style = PaintingStyle.fill;
  final Paint _leafStroke = Paint()
    ..color = const Color(0x478D6E63)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  final Paint _goldenDot = Paint()..color = const Color(0x59FFD54F);

  @override
  void onRemove() {
    _anchorGlow.dispose();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void onWorldStateChanged(WorldState worldState) {}

  void setHighlight(String? eventId) => highlightedEventId = eventId;

  @override
  void renderTree(Canvas canvas) {
    if (skipPaintSlot(WorldPaintPass.frontMotion)) return;
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    final env = state.environment;
    final accent = state.island.style.accent;

    if (env.rain) _drawRain(canvas, s);
    _drawParticles(canvas, s, env.particlePreset, accent);
    _drawWorldAnchor(canvas, s);

    if (highlightedEventId != null) {
      for (final c in state.characters) {
        if (c.linkedEventId == highlightedEventId) {
          final p = Offset(c.normalizedPos.dx * s.x, c.normalizedPos.dy * s.y);
          _drawMomentReaction(canvas, p, accent);
        }
      }
    }

    if (state.environment.colorGrade == ColorGrade.golden) {
      for (var i = 0; i < 8; i++) {
        final p = Offset(
          s.x * (0.2 + (i * 0.09) % 0.6),
          s.y * (0.3 + (i * 0.11) % 0.35) + math.sin(_time + i) * 6,
        );
        canvas.drawCircle(p, 2.5, _goldenDot);
      }
    }
  }

  void _drawWorldAnchor(Canvas canvas, Vector2 s) {
    if (state.anchors.isEmpty) return;
    final anchor = state.anchors.first;
    final p = Offset(anchor.position.dx * s.x, anchor.position.dy * s.y);
    final pulse = 0.5 + 0.5 * math.sin(_time * 1.5);
    final base = 30 + anchor.visualWeight * 34;
    final radius = base + pulse * 5;
    final token = Object.hash(
      anchor.visualWeight,
      state.island.style.accent.toARGB32(),
    );
    canvas.save();
    canvas.translate(p.dx, p.dy - 16);
    canvas.scale(radius / base);
    _anchorGlow.draw(canvas, token, (recording) {
      final rect = Rect.fromCircle(center: Offset.zero, radius: base);
      recording.drawCircle(
        Offset.zero,
        base,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF8D8)
                  .withValues(alpha: 0.06 + anchor.visualWeight * 0.08),
              state.island.style.accent.withValues(alpha: 0.03),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    });
    canvas.restore();
  }

  void _drawMomentReaction(Canvas canvas, Offset p, Color accent) {
    final pulse = math.sin(_time * 4.2).abs();
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        p,
        24 + i * 13 + pulse * 8,
        Paint()
          ..color = Color.lerp(accent, Colors.white, 0.35)!
              .withValues(alpha: 0.18 - i * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawLine(
      p + const Offset(0, -62),
      p + const Offset(0, 24),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            accent.withValues(alpha: 0.34),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCenter(center: p, width: 24, height: 96))
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi * 0.2 + _time * 0.8;
      final r = 18 + (i % 4) * 8 + pulse * 4;
      final dot = p + Offset(math.cos(a) * r, math.sin(a) * r * 0.55 - 8);
      canvas.drawCircle(dot, 1.4 + (i % 3) * 0.45,
          Paint()..color = accent.withValues(alpha: 0.38));
    }
  }

  void _drawRain(Canvas canvas, Vector2 s) {
    for (var i = 0; i < 42; i++) {
      final x = (i * 37.0 + _time * 24) % s.x;
      final y = (i * 23.0 + _time * 86) % (s.y * 0.68);
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + 9), _rain);
    }
  }

  void _drawParticles(Canvas canvas, Vector2 s, String preset, Color accent) {
    if (preset == 'soft_rain') {
      _drawRain(canvas, s);
      return;
    }
    if (preset == 'drizzle') return;
    if (preset == 'leaves' || preset == 'wind_leaves') {
      _drawLeaves(canvas, s);
      return;
    }
    final count = preset == 'golden_sparkle' ? 26 : 12;
    for (var i = 0; i < count; i++) {
      final p = Offset(
        s.x * (0.15 + (i * 0.061) % 0.7),
        s.y * (0.2 + (i * 0.097) % 0.5) + math.sin(_time * 1.2 + i) * 8,
      );
      final alpha = 0.2 + 0.25 * math.sin(_time + i).abs();
      _dot.color =
          (preset == 'golden_sparkle' ? const Color(0xFFFFD54F) : accent)
              .withValues(alpha: alpha);
      canvas.drawCircle(
        p,
        preset == 'golden_sparkle'
            ? 3.0
            : preset == 'bloom'
                ? 2.8
                : 2.2,
        _dot,
      );
    }
  }

  void _drawLeaves(Canvas canvas, Vector2 s) {
    for (var i = 0; i < 14; i++) {
      final x = (i * 57.0 + _time * (24 + i % 3 * 6)) % (s.x + 40) - 20;
      final y = (i * 31.0 + _time * (18 + i % 4 * 4)) % (s.y * 0.75);
      final a = _time * 1.2 + i;
      final leaf = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
            x + 6 * math.cos(a), y - 4, x + 10 * math.cos(a), y + 5)
        ..quadraticBezierTo(x + 2, y + 9, x, y)
        ..close();
      canvas.drawPath(leaf, _leafFill);
      canvas.drawPath(leaf, _leafStroke);
    }
  }
}
