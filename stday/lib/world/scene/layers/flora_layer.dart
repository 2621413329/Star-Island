import 'dart:math' as math;

import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, LinearGradient, RadialGradient;

import '../../engine/world_state.dart';

import '../../rendering/cozy_tree_renderer.dart';

import 'world_layer.dart';

class FloraLayer extends WorldLayer {
  FloraLayer() : super(layerPriority: -10);

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;

    if (state.decorations.isNotEmpty) return;

    final s = sceneSize;

    final wind = state.environment.windStrength;

    final biome = _biomeKey;

    for (final f in state.flora) {
      final p = Offset(f.position.dx * s.x, f.position.dy * s.y);

      switch (f.kind) {
        case FloraKind.tree:
          _drawThemedTree(canvas, p, f.growth, wind, biome, f.floraId);

        case FloraKind.flower:
          if (biome != 'volcanic_ridge' && biome != 'storm_lighthouse') {
            _drawFlowers(canvas, p, f.growth, state.island.style.flower);
          } else {
            _drawStoneCluster(canvas, p, f.growth, biome);
          }

        case FloraKind.bush:
          _drawThemedBush(
              canvas, p, f.growth, state.island.style.grass, biome, f.floraId);

        case FloraKind.grass:
          _drawThemedGrassTuft(canvas, p, wind, biome);
      }
    }
  }

  String get _biomeKey {
    if (state.island.style.biome == 'growth_world') return 'growth_world';

    return switch (state.island.style.biome) {
      'sunny' => 'dream_coast',
      'soft' => 'green_peak',
      'mist' => 'zen_pool',
      'drizzle' => 'storm_lighthouse',
      'windy' => 'volcanic_ridge',
      _ => state.island.style.biome,
    };
  }

  void _drawThemedTree(
    Canvas canvas,
    Offset base,
    double growth,
    double wind,
    String biome,
    String floraId,
  ) {
    switch (biome) {
      case 'green_peak':
        _drawPineTree(canvas, base, growth, wind);

      case 'zen_pool':
        _drawBonsaiTree(canvas, base, growth, wind);

      case 'storm_lighthouse':
        _drawBareTree(canvas, base, growth, wind);

      case 'volcanic_ridge':
        _drawCharredTree(canvas, base, growth, wind);

      case 'dream_coast':
        _drawCoastPalm(canvas, base, growth, wind);

      case 'growth_world':
        if (floraId.startsWith('pine')) {
          CozyTreeRenderer.drawPine(canvas, base, growth, wind, _time);
        } else {
          CozyTreeRenderer.drawPuffy(canvas, base, growth, wind, _time);
        }

      default:
        _drawMemoryTree(canvas, base, growth, wind);
    }
  }

  void _drawMemoryTree(Canvas canvas, Offset base, double growth, double wind) {
    final sway = math.sin(_time * 1.4 + base.dx * 0.01) * (4 + wind * 8);

    final scale = 0.7 + growth * 0.35;

    final glowCenter = base + Offset(sway, -42 * scale);

    canvas.drawCircle(
      glowCenter,
      34 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFB3E5FC).withValues(alpha: 0.18),
            const Color(0xFF9575CD).withValues(alpha: 0.08),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: 34 * scale)),
    );

    final trunk = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF455A64).withValues(alpha: 0.72),
          const Color(0xFFE1F5FE).withValues(alpha: 0.56),
        ],
      ).createShader(Rect.fromCenter(
          center: base + Offset(0, -24 * scale),
          width: 20 * scale,
          height: 54 * scale))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;

    final top = base + Offset(sway, -50 * scale);

    canvas.drawLine(base, top, trunk);

    final branch = Paint()
      ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;

    for (var i = -3; i <= 3; i++) {
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + i * 10.0 * scale,
          top.dy - (14 + i.abs() * 2) * scale,
          top.dx + i * 20.0 * scale,
          top.dy + (6 - i.abs()) * scale,
        );

      canvas.drawPath(path, branch);

      final crystal = top + Offset(i * 20.0 * scale, (6 - i.abs()) * scale);

      _drawCrystalLeaf(
          canvas, crystal, scale * (0.75 + growth * 0.35), i.isEven);
    }
  }

  void _drawCoastPalm(Canvas canvas, Offset base, double growth, double wind) {
    final scale = 0.72 + growth * 0.32;

    final sway = math.sin(_time * 1.1 + base.dx * 0.01) * (3 + wind * 5);

    final top = base + Offset(sway, -44 * scale);

    final trunk = Paint()
      ..color = const Color(0xFFC59B6D).withValues(alpha: 0.7)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(base, top, trunk);

    final leaf = Paint()
      ..color = const Color(0xFF4DBE88).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    for (var i = -3; i <= 3; i++) {
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + i * 14 * scale,
          top.dy - 14 * scale,
          top.dx + i * 24 * scale,
          top.dy + 7 * scale,
        );

      canvas.drawPath(path, leaf);
    }
  }

  void _drawPineTree(Canvas canvas, Offset base, double growth, double wind) {
    final scale = 0.72 + growth * 0.34;

    final sway = math.sin(_time * 0.9 + base.dx * 0.01) * (1.5 + wind * 2.5);

    final trunk = Paint()
      ..color = const Color(0xFF6D4C41).withValues(alpha: 0.6)
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(base, base + Offset(sway, -44 * scale), trunk);

    final greens = [
      const Color(0xFF2E7D32),
      const Color(0xFF388E3C),
      const Color(0xFF66BB6A),
    ];

    for (var i = 0; i < 3; i++) {
      final y = base.dy - (20 + i * 12) * scale;

      final w = (28 - i * 5) * scale;

      final p = Path()
        ..moveTo(base.dx + sway, y - 18 * scale)
        ..lineTo(base.dx - w, y + 8 * scale)
        ..lineTo(base.dx + w, y + 8 * scale)
        ..close();

      canvas.drawPath(p, Paint()..color = greens[i].withValues(alpha: 0.58));
    }
  }

  void _drawBonsaiTree(Canvas canvas, Offset base, double growth, double wind) {
    final scale = 0.7 + growth * 0.28;

    final trunk = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx - 10 * scale, base.dy - 22 * scale,
          base.dx + 7 * scale, base.dy - 36 * scale);

    canvas.drawPath(path, trunk);

    for (final offset in const [
      Offset(-10, -30),
      Offset(8, -38),
      Offset(18, -24)
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base + Offset(offset.dx * scale, offset.dy * scale),
          width: 22 * scale,
          height: 12 * scale,
        ),
        Paint()..color = const Color(0xFF8FAF88).withValues(alpha: 0.58),
      );
    }
  }

  void _drawBareTree(Canvas canvas, Offset base, double growth, double wind) {
    final scale = 0.72 + growth * 0.25;

    final stroke = Paint()
      ..color = const Color(0xFF455A64).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    final top =
        base + Offset(math.sin(_time + base.dx) * wind * 2, -42 * scale);

    canvas.drawLine(base, top, stroke);

    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        top + Offset(0, 8 * scale),
        top + Offset(i * 12.0 * scale, (-8 - i.abs() * 4) * scale),
        stroke..strokeWidth = 1.3 * scale,
      );
    }
  }

  void _drawCharredTree(
      Canvas canvas, Offset base, double growth, double wind) {
    final scale = 0.68 + growth * 0.24;

    final stroke = Paint()
      ..color = const Color(0xFF2B1B17).withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(base, base + Offset(0, -36 * scale), stroke);

    canvas.drawLine(
        base + Offset(0, -22 * scale),
        base + Offset(-13 * scale, -35 * scale),
        stroke..strokeWidth = 1.6 * scale);

    canvas.drawLine(base + Offset(0, -26 * scale),
        base + Offset(12 * scale, -42 * scale), stroke);

    canvas.drawCircle(
      base + Offset(3 * scale, -8 * scale),
      2.3 * scale,
      Paint()..color = const Color(0xFFFF7043).withValues(alpha: 0.55),
    );
  }

  void _drawCrystalLeaf(Canvas canvas, Offset center, double scale, bool cool) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 7 * scale)
      ..lineTo(center.dx + 5 * scale, center.dy)
      ..lineTo(center.dx, center.dy + 8 * scale)
      ..lineTo(center.dx - 5 * scale, center.dy)
      ..close();

    final color = cool ? const Color(0xFFB3E5FC) : const Color(0xFFE1BEE7);

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.58));

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawFlowers(Canvas canvas, Offset center, double growth, Color color) {
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + _time * 0.2;

      final r = 8 + growth * 6;

      final p = center +
          Offset(math.cos(angle) * r * 0.5, math.sin(angle) * r * 0.35);

      final breathe = 1 + math.sin(_time * 2.5 + i) * 0.15 * growth;

      canvas.drawCircle(p, (3 + i % 2) * breathe,
          Paint()..color = color.withValues(alpha: 0.65));
    }
  }

  void _drawThemedBush(
    Canvas canvas,
    Offset base,
    double growth,
    Color color,
    String biome,
    String floraId,
  ) {
    if (biome == 'growth_world' && floraId.startsWith('rock')) {
      CozyTreeRenderer.drawRock(canvas, base, growth);

      return;
    }

    if (biome == 'volcanic_ridge' || biome == 'storm_lighthouse') {
      _drawStoneCluster(canvas, base, growth, biome);

      return;
    }

    _drawBush(canvas, base, growth, color);
  }

  void _drawBush(Canvas canvas, Offset base, double growth, Color color) {
    final r = 14 * growth;

    final pulse = 1 + math.sin(_time * 1.4 + base.dx * 0.01) * 0.08;

    final glow = Color.lerp(color, const Color(0xFFB3E5FC), 0.45)!;

    canvas.drawCircle(base + const Offset(-6, -4), r * 0.7 * pulse,
        Paint()..color = glow.withValues(alpha: 0.45));

    canvas.drawCircle(base + const Offset(8, -6), r * 0.65 * pulse,
        Paint()..color = color.withValues(alpha: 0.42));

    canvas.drawCircle(base + const Offset(0, -10), r * 0.8 * pulse,
        Paint()..color = glow.withValues(alpha: 0.5));

    canvas.drawCircle(base + const Offset(2, -13), 2.2 * pulse,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.72));
  }

  void _drawThemedGrassTuft(
      Canvas canvas, Offset base, double wind, String biome) {
    final grassColor = switch (biome) {
      'dream_coast' => const Color(0xFF6EE7B7),
      'green_peak' => const Color(0xFF66BB6A),
      'zen_pool' => const Color(0xFFB0BEC5),
      'storm_lighthouse' => const Color(0xFF78909C),
      'volcanic_ridge' => const Color(0xFFFF7043),
      'growth_world' => const Color(0xFF81C784),
      _ => const Color(0xFFB2EBF2),
    };

    final paint = Paint()
      ..color =
          grassColor.withValues(alpha: biome == 'volcanic_ridge' ? 0.42 : 0.64)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var i = -2; i <= 2; i++) {
      final sway = math.sin(_time * 2 + i + wind * 3) * (3 + wind * 4);

      canvas.drawLine(
        base,
        base + Offset(i * 4.0 + sway, -10 - i.abs() * 2),
        paint,
      );
    }
  }

  void _drawStoneCluster(
      Canvas canvas, Offset base, double growth, String biome) {
    final color = biome == 'volcanic_ridge'
        ? const Color(0xFF3E2723)
        : const Color(0xFF607D8B);

    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base + Offset((i - 1) * 7.0, -3.0 - i * 1.5),
          width: (12 + i * 2) * growth,
          height: (7 + i) * growth,
        ),
        Paint()..color = color.withValues(alpha: 0.48 + i * 0.08),
      );
    }
  }
}
