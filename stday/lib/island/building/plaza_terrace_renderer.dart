import 'dart:ui';

import 'package:flutter/material.dart' show Color, RadialGradient;

/// 主岛广场台地：阶梯 + 立柱，解决扁平椭圆问题（#5）。
class PlazaTerraceRenderer {
  PlazaTerraceRenderer._();

  static bool isPlazaBuilding(String? buildingId) {
    return buildingId == 'story_plaza' || buildingId == 'companion_plaza';
  }

  static void draw(
    Canvas canvas, {
    required Offset base,
    required double scale,
    required Color accent,
    required Color sand,
  }) {
    final shadow = Paint()
      ..color = const Color(0xFF546E7A).withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, 2 * scale),
        width: 68 * scale,
        height: 18 * scale,
      ),
      shadow,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, -2 * scale),
        width: 62 * scale,
        height: 20 * scale,
      ),
      Paint()..color = sand.withValues(alpha: 0.82),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base + Offset(0, -10 * scale),
          width: 48 * scale,
          height: 12 * scale,
        ),
        Radius.circular(4 * scale),
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFECEFF1).withValues(alpha: 0.96),
            sand.withValues(alpha: 0.88),
          ],
        ).createShader(
          Rect.fromCenter(
            center: base + Offset(0, -10 * scale),
            width: 48 * scale,
            height: 12 * scale,
          ),
        ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base + Offset(0, -18 * scale),
          width: 34 * scale,
          height: 8 * scale,
        ),
        Radius.circular(3 * scale),
      ),
      Paint()..color = const Color(0xFFF5F5F5).withValues(alpha: 0.94),
    );

    for (final dx in [-18.0, 18.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: base + Offset(dx * scale, -24 * scale),
            width: 7 * scale,
            height: 24 * scale,
          ),
          Radius.circular(2 * scale),
        ),
        Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.92),
      );
    }

    canvas.drawCircle(
      base + Offset(0, -14 * scale),
      4.5 * scale,
      Paint()..color = accent.withValues(alpha: 0.58),
    );
  }
}
