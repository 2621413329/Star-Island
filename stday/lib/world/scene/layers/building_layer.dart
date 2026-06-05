import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Colors, LinearGradient, RadialGradient;

import '../../../core/models/mood_island_config.dart';
import 'world_layer.dart';

class BuildingLayer extends WorldLayer {
  BuildingLayer() : super(layerPriority: -20);

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
    final style = state.island.style;
    for (final b in state.buildings) {
      final anchor = Offset(b.anchor.dx * s.x, b.anchor.dy * s.y);
      _drawProp(
        canvas,
        anchor: anchor,
        propId: b.definitionId,
        level: b.level,
        style: style,
        sceneW: s.x,
        unlockFx: b.playUnlockFx,
      );
    }
  }

  void _drawProp(
    Canvas canvas, {
    required Offset anchor,
    required String propId,
    required int level,
    required MoodIslandConfig style,
    required double sceneW,
    required bool unlockFx,
  }) {
    final scale = (sceneW / 390).clamp(0.85, 1.15);
    final bob = math.sin(_time * 0.8 + anchor.dx * 0.01) * 1.2;
    final base = anchor + Offset(0, bob);
    final accent = style.accent;
    final grass = style.grass;
    final sea = style.sea;
    final flower = style.flower;
    final sand = style.sand;

    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, 4 * scale),
        width: 38 * scale,
        height: 9 * scale,
      ),
      Paint()..color = const Color(0xFF2B4B5A).withValues(alpha: 0.14),
    );

    switch (propId) {
      case 'prop_sun_beach':
        _drawSunBeach(canvas, base, scale, accent, sea, flower);
      case 'prop_green_rest':
        _drawGreenRest(canvas, base, scale, grass, accent);
      case 'prop_zen_stones':
        _drawZenStones(canvas, base, scale, sand, accent, sea);
      case 'prop_warm_lamp':
        _drawWarmLamp(canvas, base, scale, accent, sea);
      case 'prop_lava_vent':
        _drawLavaVent(canvas, base, scale, accent, sand);
      case 'growth_tree':
        _drawGrowthTree(canvas, base, scale, level, accent);
      default:
        break;
    }

    if (unlockFx) {
      canvas.drawCircle(
        anchor,
        26 * scale,
        Paint()
          ..color = accent.withValues(alpha: 0.18 + 0.08 * math.sin(_time * 4)),
      );
    }
  }

  /// 开心：沙滩遮阳伞 + 小球
  void _drawSunBeach(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sea,
    Color flower,
  ) {
    final pole = base + Offset(0, -4 * scale);
    canvas.drawLine(
      pole,
      pole + Offset(0, -34 * scale),
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.75)
        ..strokeWidth = 2.2 * scale
        ..strokeCap = StrokeCap.round,
    );
    final canopy = Path()
      ..moveTo(pole.dx, pole.dy - 34 * scale)
      ..quadraticBezierTo(
        pole.dx - 28 * scale,
        pole.dy - 20 * scale,
        pole.dx - 26 * scale,
        pole.dy - 6 * scale,
      )
      ..lineTo(pole.dx + 26 * scale, pole.dy - 6 * scale)
      ..quadraticBezierTo(
        pole.dx + 28 * scale,
        pole.dy - 20 * scale,
        pole.dx,
        pole.dy - 34 * scale,
      )
      ..close();
    canvas.drawPath(
      canopy,
      Paint()
        ..shader = LinearGradient(
          colors: [
            flower.withValues(alpha: 0.85),
            accent.withValues(alpha: 0.75),
          ],
        ).createShader(Rect.fromLTWH(
            pole.dx - 30 * scale, pole.dy - 36 * scale, 60 * scale, 32 * scale)),
    );
    canvas.drawCircle(
      pole + Offset(22 * scale, -8 * scale),
      5 * scale,
      Paint()..color = sea.withValues(alpha: 0.8),
    );
    _drawSunIcon(canvas, pole + Offset(-18 * scale, -42 * scale), 9 * scale, accent);
  }

  void _drawSunIcon(Canvas canvas, Offset c, double r, Color accent) {
    canvas.drawCircle(c, r, Paint()..color = accent.withValues(alpha: 0.9));
    final ray = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        c + Offset(math.cos(a) * (r + 2), math.sin(a) * (r + 2)),
        c + Offset(math.cos(a) * (r + 7), math.sin(a) * (r + 7)),
        ray,
      );
    }
  }

  /// 开心/平静（calm）：野餐垫 + 小树
  void _drawGreenRest(
    Canvas canvas,
    Offset base,
    double scale,
    Color grass,
    Color accent,
  ) {
    final mat = Rect.fromCenter(
      center: base + Offset(0, -8 * scale),
      width: 44 * scale,
      height: 22 * scale,
    );
    canvas.drawOval(
      mat,
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      mat,
      Paint()
        ..color = grass.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
    final trunk = base + Offset(0, -18 * scale);
    canvas.drawLine(
      trunk,
      trunk + Offset(0, -16 * scale),
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.7)
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      trunk + Offset(0, -22 * scale),
      11 * scale,
      Paint()..color = grass.withValues(alpha: 0.75),
    );
  }

  /// 平静/思考：叠石 + 水纹
  void _drawZenStones(
    Canvas canvas,
    Offset base,
    double scale,
    Color sand,
    Color accent,
    Color sea,
  ) {
    final stones = [
      (8.0, 0.0),
      (6.0, -10.0),
      (4.5, -18.0),
    ];
    for (final (r, dy) in stones) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base + Offset(0, dy * scale),
          width: r * 2 * scale,
          height: r * 1.3 * scale,
        ),
        Paint()..color = Color.lerp(sand, const Color(0xFF90A4AE), 0.35)!,
      );
    }
    final ring = Paint()
      ..color = sea.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base + Offset(0, 6 * scale),
          width: (18 + i * 8) * scale,
          height: (7 + i * 3) * scale,
        ),
        ring,
      );
    }
    canvas.drawCircle(
      base + Offset(14 * scale, -24 * scale),
      3 * scale,
      Paint()..color = accent.withValues(alpha: 0.5),
    );
  }

  /// 低落：暖光小灯塔（可辨认，非玻璃卡片）
  void _drawWarmLamp(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sea,
  ) {
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -22 * scale),
        width: 14 * scale,
        height: 32 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(
      tower,
      Paint()..color = sea.withValues(alpha: 0.55),
    );
    final glow = base + Offset(0, -40 * scale);
    canvas.drawCircle(
      glow,
      8 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF9C4).withValues(alpha: 0.95),
            accent.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: 14 * scale)),
    );
    canvas.drawCircle(
      glow,
      4 * scale,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.9),
    );
  }

  /// 生气：岩石气孔 + 热气
  void _drawLavaVent(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sand,
  ) {
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base +
              Offset((i - 1) * 12.0 * scale, -4 * scale - (i % 2) * 3),
          width: 18 * scale,
          height: 10 * scale,
        ),
        Paint()..color = Color.lerp(sand, const Color(0xFF3E2723), 0.5)!,
      );
    }
    final steam = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final p = base + Offset(i * 8.0 * scale, -14 * scale);
      final wobble = math.sin(_time * 2 + i) * 3 * scale;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(
            p.dx + i * 4 * scale + wobble,
            p.dy - 12 * scale,
            p.dx + i * 2 * scale,
            p.dy - 24 * scale,
          ),
        steam,
      );
    }
  }

  void _drawGrowthTree(
    Canvas canvas,
    Offset base,
    double scale,
    int level,
    Color accent,
  ) {
    final height = (48 + level * 6) * scale;
    canvas.drawLine(
      base + Offset(0, -4 * scale),
      base + Offset(0, -height),
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.72)
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      base + Offset(0, -height),
      (10 + level * 2) * scale,
      Paint()..color = accent.withValues(alpha: 0.55),
    );
  }
}
