import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;

import '../../rendering/retained_picture.dart';
import '../../rendering/stylized_mountain_painter.dart';
import '../../engine/world_state.dart';
import 'world_layer.dart';

class SkyLayer extends WorldLayer {
  SkyLayer() : super(layerPriority: -100);

  final RetainedPicture _sky = RetainedPicture();

  @override
  void onRemove() {
    _sky.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    if (s.x <= 0 || s.y <= 0) return;
    final env = state.environment;
    final token = Object.hash(
      s.x.round(),
      s.y.round(),
      state.island.style.biome,
      env.skyTop.toARGB32(),
      env.skyBottom.toARGB32(),
      env.sea.toARGB32(),
      (env.sunX * 1000).round(),
      (env.sunY * 1000).round(),
      (env.sunIntensity * 1000).round(),
      (env.lightWarmth * 1000).round(),
    );
    _sky.draw(canvas, token, _paintSky);
  }

  void _paintSky(Canvas canvas) {
    final s = sceneSize;
    final env = state.environment;
    final rect = Offset.zero & Size(s.x, s.y);
    final isGrowth = state.island.style.biome == 'growth_world';
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isGrowth
              ? [
                  Color.lerp(env.skyTop, Colors.white, 0.16)!,
                  Color.lerp(env.skyBottom, Colors.white, 0.08)!,
                  Color.lerp(env.skyBottom, env.sea, 0.30)!,
                ]
              : [
                  env.skyTop,
                  env.skyBottom,
                  Color.lerp(env.skyBottom, env.sea, 0.35)!,
                ],
          stops: isGrowth ? const [0, 0.48, 1] : const [0, 0.55, 1],
        ).createShader(rect),
    );

    final sunPos = Offset(s.x * env.sunX, s.y * env.sunY);
    final sunIntensity =
        isGrowth ? math.max(env.sunIntensity, 0.62) : env.sunIntensity;
    final sunR = s.x * (0.07 + sunIntensity * 0.05);
    if (sunIntensity >= 0.55) {
      final rayAlpha = (sunIntensity - 0.45).clamp(0.0, 0.45);
      final rayPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFD54F),
          const Color(0xFFFFB74D),
          env.lightWarmth,
        )!
            .withValues(alpha: rayAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      if (sunIntensity >= 0.85) {
        for (var i = 0; i < 14; i++) {
          final a = i * math.pi * 2 / 14;
          canvas.drawLine(
            sunPos + Offset(math.cos(a), math.sin(a)) * (sunR * 0.86),
            sunPos + Offset(math.cos(a), math.sin(a)) * (sunR * 1.18),
            rayPaint,
          );
        }
      }
      canvas.drawCircle(
        sunPos,
        sunR * 0.62,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.98),
              Color.lerp(
                const Color(0xFFFFD54F),
                const Color(0xFFFF8A65),
                env.lightWarmth,
              )!
                  .withValues(alpha: 0.78),
              const Color(0xFFFFA726).withValues(alpha: 0.18),
            ],
          ).createShader(Rect.fromCircle(center: sunPos, radius: sunR * 0.75)),
      );
    }
    canvas.drawCircle(
      sunPos,
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(
              const Color(0xFFFFF8E1),
              const Color(0xFFFFE0B2),
              env.lightWarmth,
            )!
                .withValues(alpha: 0.36 + sunIntensity * 0.28),
            const Color(0xFFFFD54F)
                .withValues(alpha: sunIntensity >= 0.9 ? 0.18 : 0.0),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sunPos, radius: sunR * 1.65)),
    );
  }
}

class CloudLayer extends WorldLayer {
  CloudLayer() : super(layerPriority: -90);

  double _time = 0;
  final List<double> _seed =
      List<double>.generate(14, (i) => (i * 0.73) % (math.pi * 2));
  final Map<String, Picture> _cloudShapes = {};

  @override
  void onRemove() {
    for (final picture in _cloudShapes.values) {
      picture.dispose();
    }
    _cloudShapes.clear();
    super.onRemove();
  }

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
    final key = '${w.round()}|${(alpha * 255).round()}';
    var picture = _cloudShapes[key];
    if (picture == null) {
      final recorder = PictureRecorder();
      final recording = Canvas(recorder);
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      recording.drawCircle(Offset.zero, w * 0.35, paint);
      recording.drawCircle(Offset(w * 0.28, -w * 0.08), w * 0.28, paint);
      recording.drawCircle(Offset(w * 0.52, w * 0.02), w * 0.24, paint);
      picture = recorder.endRecording();
      _cloudShapes[key] = picture;
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawPicture(picture);
    canvas.restore();
  }
}

class DistantLayer extends WorldLayer {
  DistantLayer()
      : _mountainPainter = const StylizedMountainPainter(),
        super(layerPriority: -85);

  final StylizedMountainPainter _mountainPainter;
  final RetainedPicture _backdrop = RetainedPicture();
  double _time = 0;

  @override
  void onRemove() {
    _backdrop.dispose();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    final token = Object.hash(
      s.x.round(),
      s.y.round(),
      state.island.style.biome,
      state.environment.colorGrade,
    );
    _backdrop.draw(canvas, token, (recording) {
      if (state.island.style.biome == 'growth_world') {
        _drawDistantMountains(recording, s);
      }
      if (state.environment.colorGrade == ColorGrade.golden) {
        recording.drawCircle(
          Offset(s.x * 0.5, s.y * 0.22),
          s.x * 0.35,
          Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.08),
        );
      }
    });
    if (state.characters.isNotEmpty &&
        state.environment.particlePreset == 'bloom') {
      for (var i = 0; i < 3; i++) {
        final bx = s.x * (0.15 + i * 0.28) + math.sin(_time * 0.5 + i) * 12;
        final by = s.y * 0.2 + math.cos(_time * 0.7 + i) * 6;
        _drawBird(canvas, Offset(bx, by));
      }
    }
  }

  void _drawDistantMountains(Canvas canvas, Vector2 s) {
    _mountainPainter.paintGrowthBackground(
      canvas,
      Size(s.x, s.y),
    );
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
