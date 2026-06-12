import 'dart:ui';

import 'package:flutter/material.dart' show RadialGradient;

import '../config/growth_island_config_models.dart';

class ProceduralBuildingRenderer {
  const ProceduralBuildingRenderer();

  void render(
    Canvas canvas, {
    required BuildingConfig config,
    required Offset base,
    required double scale,
    required Color accent,
    required Color sea,
    required Color grass,
    required Color sand,
  }) {
    switch (config.type) {
      case 'stone':
        _drawStone(canvas, base, scale, sand);
      case 'house':
        _drawHouse(canvas, base, scale, config.upgradeLevel, accent);
      case 'clocktower':
        _drawTower(canvas, base, scale, accent);
      case 'academy':
        _drawAcademy(canvas, base, scale, accent, grass);
      case 'lighthouse':
      case 'lighthouse_base':
        _drawLighthouse(canvas, base, scale, accent, sea);
      case 'library':
      case 'gallery':
        _drawLibrary(canvas, base, scale, accent, grass);
      case 'plaza':
      case 'fountain':
        _drawPlaza(canvas, base, scale, accent, sand);
      case 'pier':
        _drawPier(canvas, base, scale);
      default:
        _drawSmallBuilding(canvas, base, scale, accent, grass);
    }
  }

  void _drawStone(Canvas canvas, Offset base, double scale, Color sand) {
    final rect = Rect.fromCenter(
      center: base + Offset(0, -8 * scale),
      width: 22 * scale,
      height: 16 * scale,
    );
    canvas.drawOval(
      rect,
      Paint()..color = Color.lerp(sand, const Color(0xFFB0BEC5), 0.42)!,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF78909C).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );
  }

  void _drawHouse(
    Canvas canvas,
    Offset base,
    double scale,
    int upgradeLevel,
    Color accent,
  ) {
    final bodyW = (38 + upgradeLevel * 6) * scale;
    final bodyH = (28 + upgradeLevel * 4) * scale;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -18 * scale),
        width: bodyW,
        height: bodyH,
      ),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFFF4E7D2).withValues(alpha: 0.95),
    );
    final roof = Path()
      ..moveTo(base.dx - bodyW * 0.58, base.dy - bodyH)
      ..lineTo(base.dx, base.dy - bodyH - 18 * scale)
      ..lineTo(base.dx + bodyW * 0.58, base.dy - bodyH)
      ..close();
    canvas.drawPath(
      roof,
      Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.86),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: base + Offset(0, -12 * scale),
        width: 9 * scale,
        height: 14 * scale,
      ),
      Paint()..color = accent.withValues(alpha: 0.55),
    );
  }

  void _drawTower(Canvas canvas, Offset base, double scale, Color accent) {
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -34 * scale),
        width: 18 * scale,
        height: 58 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(
      tower,
      Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      base + Offset(0, -62 * scale),
      8 * scale,
      Paint()..color = accent.withValues(alpha: 0.65),
    );
  }

  void _drawAcademy(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color grass,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -24 * scale),
        width: 64 * scale,
        height: 34 * scale,
      ),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFFE8DED0).withValues(alpha: 0.96),
    );
    final roof = Path()
      ..moveTo(base.dx - 38 * scale, base.dy - 42 * scale)
      ..lineTo(base.dx, base.dy - 66 * scale)
      ..lineTo(base.dx + 38 * scale, base.dy - 42 * scale)
      ..close();
    canvas.drawPath(
      roof,
      Paint()..color = const Color(0xFF7A5D45).withValues(alpha: 0.9),
    );
    for (final dx in [-18.0, 0.0, 18.0]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: base + Offset(dx * scale, -24 * scale),
          width: 8 * scale,
          height: 16 * scale,
        ),
        Paint()
          ..color = Color.lerp(grass, accent, 0.35)!.withValues(alpha: 0.58),
      );
    }
  }

  void _drawLighthouse(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sea,
  ) {
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -28 * scale),
        width: 16 * scale,
        height: 44 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(tower, Paint()..color = sea.withValues(alpha: 0.65));
    final glow = base + Offset(0, -54 * scale);
    canvas.drawCircle(
      glow,
      10 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF9C4).withValues(alpha: 0.95),
            accent.withValues(alpha: 0.35),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: 16 * scale)),
    );
  }

  void _drawLibrary(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color grass,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -18 * scale),
        width: 38 * scale,
        height: 28 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.92),
    );
    final roof = Path()
      ..moveTo(base.dx - 22 * scale, base.dy - 32 * scale)
      ..lineTo(base.dx, base.dy - 48 * scale)
      ..lineTo(base.dx + 22 * scale, base.dy - 32 * scale)
      ..close();
    canvas.drawPath(
      roof,
      Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.88),
    );
    canvas.drawCircle(
      base + Offset(14 * scale, -38 * scale),
      3 * scale,
      Paint()..color = accent.withValues(alpha: 0.5),
    );
  }

  void _drawPlaza(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sand,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, -6 * scale),
        width: 52 * scale,
        height: 14 * scale,
      ),
      Paint()..color = sand.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      base + Offset(0, -10 * scale),
      4 * scale,
      Paint()..color = accent.withValues(alpha: 0.55),
    );
  }

  void _drawPier(Canvas canvas, Offset base, double scale) {
    final wood = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.72)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = base.dy - i * 7 * scale;
      canvas.drawLine(
        Offset(base.dx - 22 * scale, y),
        Offset(base.dx + 22 * scale, y + 2 * scale),
        wood,
      );
    }
  }

  void _drawSmallBuilding(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color grass,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -16 * scale),
        width: 30 * scale,
        height: 24 * scale,
      ),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = Color.lerp(grass, const Color(0xFFF5F0E6), 0.72)!,
    );
    canvas.drawCircle(
      base + Offset(10 * scale, -28 * scale),
      3 * scale,
      Paint()..color = accent.withValues(alpha: 0.62),
    );
  }
}
