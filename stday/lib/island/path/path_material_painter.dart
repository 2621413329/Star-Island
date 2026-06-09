import 'dart:ui';

import 'package:flutter/material.dart' show Alignment, LinearGradient;

import 'path_projection.dart';

class PathMaterialPainter {
  const PathMaterialPainter();

  void paint(
    Canvas canvas, {
    required ProjectedPath path,
    required String material,
  }) {
    if (path.left.isEmpty || path.right.isEmpty) return;
    final surface = Path()..moveTo(path.left.first.dx, path.left.first.dy);
    for (final p in path.left.skip(1)) {
      surface.lineTo(p.dx, p.dy);
    }
    for (final p in path.right.reversed) {
      surface.lineTo(p.dx, p.dy);
    }
    surface.close();

    final bounds = surface.getBounds();
    canvas.drawPath(
      surface.shift(const Offset(0, 1.5)),
      Paint()..color = const Color(0xFF314D4F).withValues(alpha: 0.09),
    );
    canvas.drawPath(
      surface,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _colors(material),
        ).createShader(bounds),
    );

    final edgePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.20)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_polyline(path.left), edgePaint);
    canvas.drawPath(_polyline(path.right), edgePaint);

    if (material == 'stone' || material == 'gold') {
      _paintPebbles(canvas, path, material);
    }
  }

  List<Color> _colors(String material) {
    return switch (material) {
      'gold' => [
          const Color(0xFFEFD58A).withValues(alpha: 0.80),
          const Color(0xFFD9AA4D).withValues(alpha: 0.62),
        ],
      'stone' => [
          const Color(0xFFE1D9C9).withValues(alpha: 0.78),
          const Color(0xFFC8BEAA).withValues(alpha: 0.66),
        ],
      'flower' => [
          const Color(0xFFF6D5DF).withValues(alpha: 0.72),
          const Color(0xFFDDB9C8).withValues(alpha: 0.58),
        ],
      'footprint' => [
          const Color(0xFFA2C78A).withValues(alpha: 0.42),
          const Color(0xFF82AE6E).withValues(alpha: 0.32),
        ],
      _ => [
          const Color(0xFFD2B07D).withValues(alpha: 0.70),
          const Color(0xFFB99162).withValues(alpha: 0.56),
        ],
    };
  }

  Path _polyline(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  void _paintPebbles(Canvas canvas, ProjectedPath path, String material) {
    final paint = Paint()
      ..color = (material == 'gold'
              ? const Color(0xFFFFF8D6)
              : const Color(0xFFF6F1E7))
          .withValues(alpha: 0.30);
    for (var i = 2; i < path.center.length; i += 4) {
      final p = path.center[i];
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 3.2, height: 1.8),
        paint,
      );
    }
  }
}
