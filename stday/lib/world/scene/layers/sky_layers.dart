import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

import '../../engine/world_state.dart';
import 'world_layer.dart';

class SkyLayer extends WorldLayer {
  SkyLayer() : super(layerPriority: -100);

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    if (s.x <= 0 || s.y <= 0) return;
    final env = state.environment;
    final rect = Offset.zero & Size(s.x, s.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            env.skyTop,
            env.skyBottom,
            Color.lerp(env.skyBottom, env.sea, 0.35)!
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    final sunPos = Offset(s.x * 0.18, s.y * 0.16);
    final sunR = s.x * (0.08 + env.sunIntensity * 0.06);
    canvas.drawCircle(
      sunPos,
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.35 + env.sunIntensity * 0.25),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sunPos, radius: sunR * 1.4)),
    );
  }
}

class CloudLayer extends WorldLayer {
  CloudLayer() : super(layerPriority: -90);

  double _time = 0;
  final List<double> _seed =
      List<double>.generate(14, (i) => (i * 0.73) % (math.pi * 2));

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    final density = state.environment.cloudDensity;
    final count = (4 + density * 6).round();
    for (var i = 0; i < count; i++) {
      final seed = _seed[i % _seed.length];
      final drift =
          (_time * (8 + i * 2) + i * 80 + seed * 30) % (s.x + 140) - 70;
      final y =
          s.y * (0.08 + (i * 0.07) % 0.28) + math.sin(_time * 0.22 + seed) * 6;
      _drawCloud(canvas, Offset(drift, y), 28 + i * 4.0, 0.22 + density * 0.2);
    }
  }

  void _drawCloud(Canvas canvas, Offset c, double w, double alpha) {
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawCircle(c, w * 0.35, paint);
    canvas.drawCircle(c + Offset(w * 0.28, -w * 0.08), w * 0.28, paint);
    canvas.drawCircle(c + Offset(w * 0.52, w * 0.02), w * 0.24, paint);
  }
}

class DistantLayer extends WorldLayer {
  DistantLayer() : super(layerPriority: -85);

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    if (state.environment.colorGrade == ColorGrade.golden) {
      canvas.drawCircle(
        Offset(s.x * 0.5, s.y * 0.22),
        s.x * 0.35,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.08),
      );
    }
    if (state.characters.isNotEmpty &&
        state.environment.particlePreset == 'bloom') {
      for (var i = 0; i < 3; i++) {
        final bx = s.x * (0.15 + i * 0.28) + math.sin(_time * 0.5 + i) * 12;
        final by = s.y * 0.2 + math.cos(_time * 0.7 + i) * 6;
        _drawBird(canvas, Offset(bx, by));
      }
    }
  }

  void _drawBird(Canvas canvas, Offset p) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: p, width: 10, height: 8), 0.2, 2.2,
        false, paint);
  }
}
