import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'world_island_layout.dart';
import 'world_preview_performance.dart';

/// 顶部 15% 极淡天空，其余全是海。
class WorldPreviewHorizonSkyLayer extends StatelessWidget {
  const WorldPreviewHorizonSkyLayer({super.key, required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HorizonSkyPainter(phase: phase),
      size: Size.infinite,
    );
  }
}

class _HorizonSkyPainter extends CustomPainter {
  _HorizonSkyPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final skyH = size.height * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, skyH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFB8DCFF).withValues(alpha: 0.55),
            const Color(0xFF8FD0FF).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, skyH)),
    );
  }

  @override
  bool shouldRepaint(covariant _HorizonSkyPainter oldDelegate) => false;
}

/// 海底渐层（World 最底层）。
class WorldPreviewSeabedLayer extends StatelessWidget {
  const WorldPreviewSeabedLayer({
    super.key,
    required this.phase,
    this.quality = WorldPreviewQuality.high,
  });

  final double phase;
  final WorldPreviewQuality quality;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SeabedPainter(phase: phase),
      size: Size.infinite,
    );
  }
}

class _SeabedPainter extends CustomPainter {
  _SeabedPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, 0.2),
          radius: 1.4,
          colors: const [
            Color(0xFF2E6FA8),
            Color(0xFF1A5080),
            Color(0xFF0F3558),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _SeabedPainter oldDelegate) => false;
}

/// 六层活体海面：浅蓝底 → 波纹 → 反光 → 流动 → 浪花 → 海流。
class WorldPreviewOceanLayer extends StatelessWidget {
  const WorldPreviewOceanLayer({
    super.key,
    required this.phase,
    this.quality = WorldPreviewQuality.high,
  });

  final double phase;
  final WorldPreviewQuality quality;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LivingOceanPainter(phase: phase, quality: quality),
      size: Size.infinite,
    );
  }
}

class _LivingOceanPainter extends CustomPainter {
  _LivingOceanPainter({required this.phase, required this.quality});

  final double phase;
  final WorldPreviewQuality quality;
  static const _tile = 88.0;

  bool get _rich => WorldPreviewPerformance.useRichOcean(quality);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _layer1BaseGradient(canvas, rect, size);
    if (_rich) {
      _layer2RippleTiles(canvas, size);
      _layer3Specular(canvas, size);
      _layer4Flow(canvas, size);
      _layer5Foam(canvas, size);
      _layer6Current(canvas, size);
    } else {
      _layer4Flow(canvas, size, bands: 3);
      _layer3Specular(canvas, size, count: 6);
    }
    _edgeDeepening(canvas, size);
  }

  void _layer1BaseGradient(Canvas canvas, Rect rect, Size size) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.05),
          radius: 1.08,
          colors: const [
            Color(0xFF9FDFFF),
            Color(0xFF72C4F5),
            Color(0xFF4AA8E8),
            Color(0xFF2E88CC),
          ],
          stops: [0.0, 0.38, 0.72, 1.0],
        ).createShader(rect),
    );
  }

  void _layer2RippleTiles(Canvas canvas, Size size) {
    final step = quality == WorldPreviewQuality.balanced ? 2 : 1;
    final ox = (phase * _tile * 1.6) % _tile;
    final oy = (phase * _tile * 0.5) % _tile;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var row = -1; row < size.height / _tile + 2; row += step) {
      for (var col = -1; col < size.width / _tile + 2; col += step) {
        final w =
            math.sin(phase * math.pi * 2 + col * 0.5 + row * 0.35);
        p.color = Colors.white.withValues(alpha: 0.04 + w.abs() * 0.025);
        final cx = col * _tile - ox + _tile * 0.5;
        final cy = row * _tile - oy + _tile * 0.5 + w * 3;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: _tile * 0.7, height: _tile * 0.38),
          p,
        );
      }
    }
  }

  void _layer3Specular(Canvas canvas, Size size, {int count = 16}) {
    for (var i = 0; i < count; i++) {
      final t = (phase * 0.4 + i * 0.09) % 1.0;
      canvas.drawCircle(
        Offset(size.width * t, size.height * (0.18 + (i % 6) * 0.12)),
        1.4 + (i % 3) * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.16),
      );
    }
  }

  void _layer4Flow(Canvas canvas, Size size, {int bands = 6}) {
    for (var band = 0; band < bands; band++) {
      final path = Path()..moveTo(0, size.height * (0.12 + band * 0.14));
      for (var x = 0.0; x <= size.width; x += 6) {
        final y = size.height * (0.12 + band * 0.14) +
            math.sin(x * 0.018 + phase * math.pi * 2 + band) * 4;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.06 - band * 0.006),
      );
    }
  }

  void _layer5Foam(Canvas canvas, Size size) {
    final foam = Paint()..color = Colors.white.withValues(alpha: 0.14);
    for (var i = 0; i < 8; i++) {
      final t = (phase * 0.25 + i * 0.12) % 1.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * t, size.height * (0.65 + i * 0.04)),
          width: 28 + i * 4,
          height: 6,
        ),
        foam..color = Colors.white.withValues(alpha: 0.08 + (i % 3) * 0.03),
      );
    }
  }

  void _layer6Current(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFCAEEFF).withValues(alpha: 0.10);
    for (var i = 0; i < 3; i++) {
      final path = Path();
      final startX = size.width * (-0.1 + i * 0.35 + phase * 0.15) % size.width;
      path.moveTo(startX, size.height * 0.45);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * (0.5 + i * 0.06),
        size.width * (0.6 + i * 0.15),
        size.height * 0.78,
      );
      canvas.drawPath(path, p);
    }
  }

  void _edgeDeepening(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.08),
          radius: 1.12,
          colors: [
            Colors.transparent,
            const Color(0xFF0E3D6E).withValues(alpha: 0.22),
          ],
          stops: const [0.58, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _LivingOceanPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.quality != quality;
}

/// 岛间航线：白色虚线 + 极淡水面反光（连接群岛）。
class WorldPreviewRouteLayer extends CustomPainter {
  WorldPreviewRouteLayer({
    required this.phase,
    this.activeSlotIds = const {},
    this.quality = WorldPreviewQuality.high,
  });

  final double phase;
  final Set<String> activeSlotIds;
  final WorldPreviewQuality quality;

  @override
  void paint(Canvas canvas, Size size) {
    final main = WorldIslandLayout.forSlot(WorldIslandLayout.mainSlotId);
    final p0 = _px(main.position, size);

    for (final slotId in WorldIslandLayout.storyRankSlotIds) {
      if (activeSlotIds.isNotEmpty && !activeSlotIds.contains(slotId)) {
        continue;
      }
      final target = WorldIslandLayout.forSlot(slotId);
      final p2 = _px(target.position, size);
      final lift = 12.0 + (p0.dy - p2.dy).abs() * 0.06;
      final mid = Offset(
        (p0.dx + p2.dx) / 2,
        math.min(p0.dy, p2.dy) - lift,
      );

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Colors.white.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      if (quality != WorldPreviewQuality.low) {
        _dashed(canvas, path, phase);
      } else {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = Colors.white.withValues(alpha: 0.28),
        );
      }
    }
  }

  void _dashed(Canvas canvas, Path path, double phase) {
    const dash = 6.0;
    const gap = 8.0;
    final offset = (phase * 28) % (dash + gap);
    for (final metric in path.computeMetrics()) {
      var d = offset;
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        canvas.drawPath(
          metric.extractPath(d, end),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3
            ..color = Colors.white.withValues(alpha: 0.42),
        );
        d += dash + gap;
      }
    }
  }

  Offset _px(Offset n, Size s) => Offset(n.dx * s.width, n.dy * s.height);

  @override
  bool shouldRepaint(covariant WorldPreviewRouteLayer oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.activeSlotIds != activeSlotIds;
}

/// 极小云层（仅占顶部 ~12%）。
class WorldPreviewCloudLayer extends StatelessWidget {
  const WorldPreviewCloudLayer({super.key, required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _TinyCloudPainter(phase: phase),
        size: Size.infinite,
      ),
    );
  }
}

class _TinyCloudPainter extends CustomPainter {
  _TinyCloudPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.32);
    for (var i = 0; i < 2; i++) {
      final t = (phase * 0.08 + i * 0.4) % 1.0;
      final cx = size.width * (0.15 + t * 0.7 + i * 0.2);
      final cy = size.height * (0.04 + i * 0.03);
      canvas.drawCircle(Offset(cx, cy), 10 + i * 3, paint);
      canvas.drawCircle(Offset(cx + 10, cy + 2), 8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TinyCloudPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// 生命层：海鸥、小船、鱼跃、漂浮木桶、光斑。
class WorldPreviewLifeLayer extends StatelessWidget {
  const WorldPreviewLifeLayer({
    super.key,
    required this.phase,
    this.quality = WorldPreviewQuality.high,
  });

  final double phase;
  final WorldPreviewQuality quality;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _LifePainter(phase: phase, quality: quality),
        size: Size.infinite,
      ),
    );
  }
}

class _LifePainter extends CustomPainter {
  _LifePainter({required this.phase, required this.quality});

  final double phase;
  final WorldPreviewQuality quality;

  @override
  void paint(Canvas canvas, Size size) {
    _birds(canvas, size);
    _boat(canvas, size);
    if (quality == WorldPreviewQuality.high) {
      _barrel(canvas, size);
      _fishJump(canvas, size);
    }
    _sparkles(canvas, size, count: quality == WorldPreviewQuality.high ? 12 : 6);
  }

  void _birds(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.50);
    for (var i = 0; i < 4; i++) {
      final t = (phase * 0.15 + i * 0.22) % 1.0;
      final cx = size.width * t;
      final cy = size.height * (0.08 + i * 0.025);
      final wing = math.sin(phase * math.pi * 10 + i) * 2.5;
      canvas.drawPath(
        Path()
          ..moveTo(cx - 6, cy + wing)
          ..quadraticBezierTo(cx, cy - 1.5, cx + 6, cy + wing),
        p,
      );
    }
  }

  void _boat(Canvas canvas, Size size) {
    final t = (phase * 0.06) % 1.0;
    final cx = size.width * (0.05 + t * 0.9);
    final cy = size.height * 0.78 + math.sin(phase * math.pi * 2) * 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF8B5E3C).withValues(alpha: 0.7),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 1, cy)
        ..lineTo(cx + 1, cy - 11)
        ..lineTo(cx - 5, cy - 3)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.78),
    );
    // 船尾航迹
    final trail = Path()
      ..moveTo(cx - 8, cy + 1)
      ..quadraticBezierTo(cx - 22, cy + 3, cx - 36, cy + 1);
    canvas.drawPath(
      trail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _barrel(Canvas canvas, Size size) {
    final t = (phase * 0.04 + 0.3) % 1.0;
    final cx = size.width * (0.2 + t * 0.55);
    final cy = size.height * 0.62 + math.sin(phase * math.pi * 2 + 1) * 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 8, height: 6),
      Paint()..color = const Color(0xFF6D4C41).withValues(alpha: 0.55),
    );
  }

  void _fishJump(Canvas canvas, Size size) {
    final jump = math.max(0, math.sin(phase * math.pi * 2 * 0.35));
    if (jump < 0.15) return;
    final cx = size.width * 0.62;
    final cy = size.height * 0.55 - jump * 18;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 7, height: 3),
      Paint()..color = const Color(0xFF90CAF9).withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      Offset(cx + 3, cy - 1),
      1,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  void _sparkles(Canvas canvas, Size size, {required int count}) {
    for (var i = 0; i < count; i++) {
      final t = (phase * 0.3 + i * 0.08) % 1.0;
      canvas.drawCircle(
        Offset(
          size.width * ((i * 0.13 + t * 0.25) % 1.0),
          size.height * (0.25 + (i % 5) * 0.1),
        ),
        1.0 + (i % 2) * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.10 + (i % 3) * 0.04),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LifePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.quality != quality;
}

// 兼容旧命名
typedef WorldPreviewSkyLayer = WorldPreviewHorizonSkyLayer;
typedef WorldPreviewWaterLayer = WorldPreviewOceanLayer;
typedef WorldPreviewRouteGlowLayer = WorldPreviewRouteLayer;
typedef WorldPreviewBirdLayer = WorldPreviewLifeLayer;
typedef WorldPreviewBoatLayer = WorldPreviewLifeLayer;
typedef WorldPreviewAmbientParticleLayer = WorldPreviewLifeLayer;
typedef WorldPreviewLightLayer = WorldPreviewHorizonSkyLayer;
