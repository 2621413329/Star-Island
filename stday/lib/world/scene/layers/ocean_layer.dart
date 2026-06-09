import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show Alignment, Colors, LinearGradient;

import 'world_layer.dart';

class OceanLayer extends WorldLayer {
  OceanLayer() : super(layerPriority: -70);

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
    final env = state.environment;
    final seaDeep = Color.lerp(env.sea, const Color(0xFF0277BD), 0.34)!;

    final isGrowth = state.island.style.biome == 'growth_world';
    final horizon = isGrowth ? s.y * 0.38 : s.y * 0.26;
    final rect = Rect.fromLTWH(0, horizon, s.x, s.y - horizon);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [env.sea, seaDeep],
        ).createShader(rect),
    );

    final waveAmp = 4 + env.waveIntensity * 8;
    final shimmer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (var i = 0; i < 22; i++) {
      final y = s.y * (0.38 + (i % 9) * 0.06) + math.sin(_time * (0.6 + env.waveIntensity * 0.4) + i) * waveAmp;
      final x = (i * 47.0 + _time * (14 + env.waveIntensity * 10)) % (s.x + 80) - 40;
      final len = 20 + (i % 4) * 16;
      shimmer.color = Colors.white.withValues(alpha: 0.08 + 0.08 * env.waveIntensity);
      canvas.drawLine(Offset(x, y), Offset(x + len, y + math.sin(i + _time) * 5), shimmer);
    }
  }
}
