import 'dart:ui';

import '../engine/world_state.dart';
import 'lawn_obstacle_mask.dart';
import 'realistic_lawn_renderer.dart';

/// Growth Island 2.0 平地草坪：程序化写实草簇渲染，严格限制在石质边缘以内。
class GrowthWorldGroundPainter {
  const GrowthWorldGroundPainter({
    required this.compact,
    required this.time,
    required this.environment,
    this.pass = LawnRenderPass.background,
    this.obstacleMask,
    this.clipPath,
  });

  final bool compact;
  final double time;
  final MoodEnvironmentState environment;
  final LawnRenderPass pass;
  final LawnObstacleMask? obstacleMask;
  final Path? clipPath;

  void paint(Canvas canvas, Size size, IslandState island) {
    final style = island.style;
    final islandScale = island.radius.clamp(0.85, 1.25);
    final cx = size.width * 0.5;
    final cy = size.height * (compact ? 0.56 : 0.54);
    final compactScale = compact ? 1.414 : 1.0;
    final rx = size.width *
        0.50 *
        (compact ? 0.952 : 1.0) *
        compactScale *
        islandScale *
        0.90;
    final ry = size.height *
        0.125 *
        (compact ? 1.19 : 1.0) *
        compactScale *
        islandScale;

    _drawLawnUndertone(canvas, style, cx, cy, rx, ry);
    _drawFullLawn(canvas, style, cx, cy, rx, ry);
    _drawAmbientShading(canvas, size, style, cx, cy, rx, ry);
    _drawSoftHills(canvas, size, style, tier, seed: 7);
    _drawMossPatches(canvas, size, style, seed: 19);
    _drawPebbles(canvas, size, seed: 91);
    _drawWildflowers(canvas, size, style, tier, seed: 31);
    _drawLeafAccents(canvas, size, style, seed: 67);
    _drawEdgeTransition(canvas, size, style, cx, cy, rx, ry);
    _drawGrowthLife(canvas, size, style, tier, cx, cy);
  }

  bool _insideIsland(
    Offset p,
    double cx,
    double cy,
    double rx,
    double ry, {
    double inset = 0.97,
  }) {
    final dx = (p.dx - cx) / (rx * inset);
    final dy = (p.dy - cy) / (ry * inset);
    return dx * dx + dy * dy <= 1.0;
  }

  /// 草坪底色：细密色点铺底，让岛面从一开始就有草坪质感。
  void _drawLawnUndertone(
    Canvas canvas,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    const spacing = 7.5;
    final left = cx - rx * 0.96;
    final top = cy - ry * 0.94;
    final cols = ((rx * 1.92) / spacing).ceil();
    final rows = ((ry * 1.88) / spacing).ceil();
    final dot = Paint();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final hash = row * 7919 + col * 6151;
        final rng = math.Random(hash);
        final p = Offset(
          left + col * spacing + (rng.nextDouble() - 0.5) * spacing * 0.75,
          top + row * spacing + (rng.nextDouble() - 0.5) * spacing * 0.75,
        );
        if (!_insideIsland(p, cx, cy, rx, ry)) continue;
        dot.color = Color.lerp(
          style.grass,
          hash.isEven ? const Color(0xFF9CCC65) : const Color(0xFF558B2F),
          0.12 + rng.nextDouble() * 0.18,
        )!.withValues(alpha: 0.10 + rng.nextDouble() * 0.10);
        canvas.drawCircle(p, 0.9 + rng.nextDouble() * 0.8, dot);
      }
    }
  }

  /// 全岛小草草坪：细密草叶铺满岛面，绘制在装饰层下方，不影响后续 PNG 装饰。
  void _drawFullLawn(
    Canvas canvas,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final spacing = (rx * 2 / 92).clamp(4.5, 6.0);
    final left = cx - rx * 0.96;
    final top = cy - ry * 0.94;
    final cols = ((rx * 1.92) / spacing).ceil();
    final rows = ((ry * 1.88) / spacing).ceil();
    final stroke = Paint()..strokeCap = StrokeCap.round;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final hash = row * 10007 + col * 6893;
        final rng = math.Random(hash);
        final base = Offset(
          left + col * spacing + (rng.nextDouble() - 0.5) * spacing * 0.82,
          top + row * spacing + (rng.nextDouble() - 0.5) * spacing * 0.82,
        );
        if (!_insideIsland(base, cx, cy, rx, ry)) continue;

        final phase = base.dx * 0.019 + base.dy * 0.024;
        final wind = math.sin(time * 1.5 + phase) * 0.32;
        final bladeCount = 2 + (hash % 2);
        final bladeHeight = 3.0 + rng.nextDouble() * 4.0;

        for (var b = 0; b < bladeCount; b++) {
          final lean = wind + (b - (bladeCount - 1) / 2) * 0.22;
          stroke
            ..strokeWidth = 0.5 + rng.nextDouble() * 0.45
            ..color = Color.lerp(
              style.grass,
              b.isEven ? const Color(0xFF81C784) : const Color(0xFF689F38),
              0.18 + rng.nextDouble() * 0.22,
            )!
                .withValues(alpha: 0.38 + rng.nextDouble() * 0.32);
          canvas.drawLine(
            base,
            base + Offset(lean * 2.4, -bladeHeight),
            stroke,
          );
        }
      }
    }
  }

  void _drawAmbientShading(
    Canvas canvas,
    Size size,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final warm = Rect.fromCenter(
      center: Offset(cx - rx * 0.12, cy - ry * 0.35),
      width: rx * 1.1,
      height: ry * 2.4,
    );
    canvas.drawOval(
      warm,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(warm),
    );
    final cool = Rect.fromCenter(
      center: Offset(cx + rx * 0.18, cy + ry * 0.25),
      width: rx * 0.95,
      height: ry * 2.1,
    );
    canvas.drawOval(
      cool,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(style.grass, const Color(0xFF1B5E20), 0.22)!
                .withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(cool),
    );
  }

  void _drawSoftHills(
    Canvas canvas,
    Size size,
    MoodIslandConfig style,
    int tier, {
    required int seed,
  }) {
    final rng = math.Random(seed);
    final count = 3 + tier.clamp(0, 5);
    for (var i = 0; i < count; i++) {
      final cx = size.width * (0.22 + rng.nextDouble() * 0.56);
      final cy = size.height * (0.46 + rng.nextDouble() * 0.14);
      final w = size.width * (0.10 + rng.nextDouble() * 0.14);
      final h = w * 0.28;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 2), width: w, height: h),
        Paint()
          ..color = Color.lerp(style.grass, const Color(0xFF1B5E20), 0.16)!
              .withValues(alpha: 0.10),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(style.grass, Colors.white, 0.38)!,
              style.grass,
              Color.lerp(style.grass, const Color(0xFF388E3C), 0.10)!,
            ],
          ).createShader(Rect.fromCenter(
            center: Offset(cx, cy),
            width: w,
            height: h,
          )),
      );
    }
  }

  void _drawMossPatches(Canvas canvas, Size size, MoodIslandConfig style,
      {required int seed}) {
    final rng = math.Random(seed);
    for (var i = 0; i < 14; i++) {
      final p = Offset(
        size.width * (0.20 + rng.nextDouble() * 0.60),
        size.height * (0.44 + rng.nextDouble() * 0.16),
      );
      final r = 4 + rng.nextDouble() * 9;
      canvas.drawOval(
        Rect.fromCenter(center: p, width: r * 2.2, height: r * 1.1),
        Paint()
          ..color = Color.lerp(
            style.grass,
            const Color(0xFF9CCC65),
            0.35,
          )!.withValues(alpha: 0.22 + rng.nextDouble() * 0.12),
      );
    }
  }

  void _drawPebbles(Canvas canvas, Size size, {required int seed}) {
    final rng = math.Random(seed);
    for (var i = 0; i < 22; i++) {
      final p = Offset(
        size.width * (0.20 + rng.nextDouble() * 0.60),
        size.height * (0.48 + rng.nextDouble() * 0.12),
      );
      final w = 2.5 + rng.nextDouble() * 4.5;
      canvas.drawOval(
        Rect.fromCenter(center: p, width: w, height: w * 0.65),
        Paint()
          ..color = Color.lerp(
            const Color(0xFFBCAAA4),
            const Color(0xFF90A4AE),
            rng.nextDouble(),
          )!
              .withValues(alpha: 0.35 + rng.nextDouble() * 0.25),
      );
    }
  }

  void _drawWildflowers(
    Canvas canvas,
    Size size,
    MoodIslandConfig style,
    int tier, {
    required int seed,
  }) {
    final rng = math.Random(seed);
    final palette = [
      style.flower,
      const Color(0xFFFFF59D),
      const Color(0xFFCE93D8),
      const Color(0xFF80DEEA),
      const Color(0xFFFFCC80),
    ];
    for (var c = 0; c < 6 + tier; c++) {
      final center = Offset(
        size.width * (0.22 + rng.nextDouble() * 0.56),
        size.height * (0.44 + rng.nextDouble() * 0.14),
      );
      final color = palette[rng.nextInt(palette.length)];
      for (var f = 0; f < 4 + rng.nextInt(4); f++) {
        final angle = rng.nextDouble() * math.pi * 2;
        final dist = 2 + rng.nextDouble() * 5;
        final petal = center +
            Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.55);
        canvas.drawCircle(
          petal,
          1.2 + rng.nextDouble() * 1.2,
          Paint()..color = color.withValues(alpha: 0.55 + rng.nextDouble() * 0.3),
        );
      }
      canvas.drawCircle(
        center,
        1.0,
        Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.75),
      );
    }
    for (var i = 0; i < 18 + tier * 2; i++) {
      final p = Offset(
        size.width * (0.18 + rng.nextDouble() * 0.64),
        size.height * (0.42 + rng.nextDouble() * 0.16),
      );
      canvas.drawCircle(
        p,
        1.0 + rng.nextDouble() * 1.4,
        Paint()
          ..color = palette[rng.nextInt(palette.length)]
              .withValues(alpha: 0.35 + rng.nextDouble() * 0.35),
      );
    }
  }

  void _drawLeafAccents(Canvas canvas, Size size, MoodIslandConfig style,
      {required int seed}) {
    final rng = math.Random(seed);
    for (var i = 0; i < 12; i++) {
      final p = Offset(
        size.width * (0.24 + rng.nextDouble() * 0.52),
        size.height * (0.45 + rng.nextDouble() * 0.12),
      );
      final rot = rng.nextDouble() * math.pi;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 5, height: 2.5),
        Paint()
          ..color = Color.lerp(style.grass, const Color(0xFF689F38), 0.2)!
              .withValues(alpha: 0.42),
      );
      canvas.restore();
    }
  }

  void _drawEdgeTransition(
    Canvas canvas,
    Size size,
    MoodIslandConfig style,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    for (var ring = 0; ring < 3; ring++) {
      final inset = 0.04 + ring * 0.06;
      final path = Path();
      for (var i = 0; i <= 96; i++) {
        final t = math.pi * 2 * i / 96;
        final wobble = 1 + math.sin(t * 3.0 + 0.6) * 0.012;
        final p = Offset(
          cx + math.cos(t) * rx * (1 - inset) * wobble,
          cy + math.sin(t) * ry * (1 - inset) * wobble,
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 0 ? 7 : 4
          ..color = (ring == 0
                  ? Color.lerp(style.grass, Colors.white, 0.32)!
                  : Color.lerp(style.grass, const Color(0xFF558B2F), 0.12)!)
              .withValues(alpha: ring == 0 ? 0.20 : 0.12),
      );
    }

    final edgeStroke = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    for (var i = 0; i < 48; i++) {
      final t = math.pi * 2 * i / 48 + 0.2;
      final wobble = 1 + math.sin(t * 3.0 + 0.6) * 0.012;
      final sway = math.sin(time * 1.5 + t * 2.2) * 2.5;
      final base = Offset(
        cx + math.cos(t) * rx * 0.94 * wobble,
        cy + math.sin(t) * ry * 0.94 * wobble,
      );
      final inward = Offset(
        cx + math.cos(t + sway * 0.002) * rx * 0.88 * wobble,
        cy + math.sin(t) * ry * 0.88 * wobble,
      );
      edgeStroke.color = Color.lerp(
        style.grass,
        const Color(0xFF7CB342),
        (i.isEven ? 0.15 : 0.35),
      )!.withValues(alpha: 0.35 + (i % 3) * 0.08);
      canvas.drawLine(base, inward, edgeStroke);
    }
  }

  void _drawGrowthLife(
    Canvas canvas,
    Size size,
    MoodIslandConfig style,
    int tier,
    double cx,
    double cy,
  ) {
    final pulse = 0.5 + 0.5 * math.sin(time * 1.2);
    final glowRect = Rect.fromCenter(
      center: Offset(cx, cy - size.height * 0.02),
      width: size.width * 0.28,
      height: size.height * 0.12,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(style.grass, style.flower, 0.35)!
                .withValues(alpha: 0.10 + pulse * 0.06),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );

    final rng = math.Random(17);
    for (var i = 0; i < 8 + tier * 2; i++) {
      final seed = i * 1.618 + time * 0.15;
      final x = size.width * (0.20 + (i * 0.071) % 0.60) +
          math.sin(seed) * 8;
      final y = size.height * (0.42 + (i * 0.047) % 0.16) +
          math.cos(seed * 1.3) * 6;
      canvas.drawCircle(
        Offset(x, y),
        1.0 + pulse * 0.8,
        Paint()
          ..color = const Color(0xFFFFF9C4)
              .withValues(alpha: 0.18 + pulse * 0.14),
      );
    }

    for (var i = 0; i < 6 + tier; i++) {
      final angle = rng.nextDouble() * math.pi * 2 + time * 0.25;
      final dist = 8 + rng.nextDouble() * 22;
      final origin = Offset(
        cx + math.cos(angle) * dist * 2.2,
        cy + math.sin(angle) * dist * 0.6,
      );
      final petal = Paint()
        ..color = Color.lerp(style.flower, Colors.white, 0.4)!
            .withValues(alpha: 0.22 + pulse * 0.12);
      canvas.drawOval(
        Rect.fromCenter(
          center: origin + Offset(math.cos(angle + 0.8) * 3, -2),
          width: 3.5,
          height: 2,
        ),
        petal,
      );
    }

    final wisp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;
    for (var i = 0; i < 4 + tier; i++) {
      final start = Offset(
        size.width * (0.28 + (i * 0.11) % 0.44),
        size.height * (0.50 + (i * 0.03) % 0.08),
      );
      wisp.color = Color.lerp(style.accent, style.grass, 0.5)!
          .withValues(alpha: 0.10 + pulse * 0.08);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx + 6,
          start.dy - 8,
          start.dx + 12,
          start.dy - 4,
        );
      canvas.drawPath(path, wisp);
    }
  }
}
