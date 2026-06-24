import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show Color;

/// 在装饰/建筑根部绘制前景草叶，略微遮挡底部，营造「长在土地上」的层次。
class GrassSkirtPainter {
  const GrassSkirtPainter._();

  /// 装饰/建筑锚点处的局部草裙（画在物体之上）。
  static void drawAtAnchor(
    Canvas canvas, {
    required Offset anchor,
    required double width,
    required double coverHeight,
    required Color grass,
    required double time,
    required int seed,
    double density = 1.0,
  }) {
    if (width <= 0 || coverHeight <= 0) return;

    final spacing = (4.2 / density).clamp(3.0, 5.5);
    final left = anchor.dx - width * 0.58;
    final right = anchor.dx + width * 0.58;
    final groundY = anchor.dy;
    final topY = groundY - coverHeight;

    final stroke = Paint()..strokeCap = StrokeCap.round;
    final cols = ((right - left) / spacing).ceil();
    final rows = ((groundY - topY) / spacing).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final hash = seed + row * 6151 + col * 7919;
        final rng = math.Random(hash);
        final base = Offset(
          left + col * spacing + (rng.nextDouble() - 0.5) * spacing * 0.9,
          groundY - row * spacing * 0.55 - rng.nextDouble() * coverHeight * 0.35,
        );
        if (base.dx < left || base.dx > right) continue;

        final phase = base.dx * 0.022 + seed * 0.01;
        final wind = math.sin(time * 1.55 + phase) * 0.38;
        final bladeH = 5.0 + rng.nextDouble() * 7.5;
        final lean = wind + (rng.nextDouble() - 0.5) * 0.35;

        stroke
          ..strokeWidth = 0.65 + rng.nextDouble() * 0.55
          ..color = Color.lerp(
            grass,
            rng.nextBool() ? const Color(0xFF9CCC65) : const Color(0xFF558B2F),
            0.2 + rng.nextDouble() * 0.25,
          )!
              .withValues(alpha: 0.52 + rng.nextDouble() * 0.38);

        canvas.drawLine(
          base,
          base + Offset(lean * 3.2, -bladeH),
          stroke,
        );
      }
    }
  }

  /// 岛面近景草带：在装饰层之上绘制，增强整体纵深。
  static void drawForegroundBand(
    Canvas canvas, {
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required Color grass,
    required double time,
  }) {
    final spacing = (rx * 2 / 72).clamp(5.0, 7.0);
    final left = cx - rx * 0.95;
    final top = cy - ry * 0.35;
    final bottom = cy + ry * 0.92;
    final cols = ((rx * 1.9) / spacing).ceil();
    final rows = ((bottom - top) / spacing).ceil();
    final stroke = Paint()..strokeCap = StrokeCap.round;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final hash = row * 10007 + col * 4201 + 17;
        final rng = math.Random(hash);
        final base = Offset(
          left + col * spacing + (rng.nextDouble() - 0.5) * spacing * 0.75,
          top + row * spacing + (rng.nextDouble() - 0.5) * spacing * 0.5,
        );
        final dx = (base.dx - cx) / (rx * 0.96);
        final dy = (base.dy - cy) / (ry * 0.94);
        if (dx * dx + dy * dy > 1.0) continue;

        // 越靠近岛面前缘（下方）密度与高度略增
        final frontBias = ((base.dy - (cy - ry * 0.2)) / (ry * 1.1))
            .clamp(0.0, 1.0);
        if (rng.nextDouble() > 0.35 + frontBias * 0.45) continue;

        final phase = base.dx * 0.018 + base.dy * 0.012;
        final wind = math.sin(time * 1.45 + phase) * 0.3;
        final bladeH = 4.5 + frontBias * 5.5 + rng.nextDouble() * 3.0;

        stroke
          ..strokeWidth = 0.55 + rng.nextDouble() * 0.5
          ..color = Color.lerp(
            grass,
            hash.isEven ? const Color(0xFF81C784) : const Color(0xFF689F38),
            0.15 + rng.nextDouble() * 0.2,
          )!
              .withValues(alpha: 0.28 + frontBias * 0.32);

        canvas.drawLine(
          base,
          base + Offset(wind * 2.8, -bladeH),
          stroke,
        );
      }
    }
  }

  static bool isGroundDecorCategory(String categoryName) {
    return switch (categoryName) {
      'grass' ||
      'flower' ||
      'bush' ||
      'tree' ||
      'stone' ||
      'pond' ||
      'special' =>
        true,
      _ => false,
    };
  }
}
