import 'dart:math' as math;
import 'dart:ui';

class ProjectedPath {
  const ProjectedPath({
    required this.center,
    required this.left,
    required this.right,
  });

  final List<Offset> center;
  final List<Offset> left;
  final List<Offset> right;
}

class PathProjection {
  const PathProjection();

  ProjectedPath project({
    required Offset start,
    required Offset end,
    required double baseWidth,
    required Size sceneSize,
  }) {
    final control = Offset(
      (start.dx + end.dx) * 0.5,
      (start.dy + end.dy) * 0.5 - sceneSize.height * 0.035,
    );
    final center = <Offset>[];
    final left = <Offset>[];
    final right = <Offset>[];

    for (var i = 0; i <= 18; i++) {
      final t = i / 18;
      final p = _quadratic(start, control, end, t);
      final tangent = _quadraticTangent(start, control, end, t);
      final normal = _normal(tangent);
      final perspective =
          0.62 + (p.dy / sceneSize.height).clamp(0.0, 1.0) * 0.68;
      final width = baseWidth * perspective;
      center.add(p);
      left.add(p + normal * width);
      right.add(p - normal * width);
    }
    return ProjectedPath(center: center, left: left, right: right);
  }

  Offset _quadratic(Offset a, Offset c, Offset b, double t) {
    final mt = 1 - t;
    return a * (mt * mt) + c * (2 * mt * t) + b * (t * t);
  }

  Offset _quadraticTangent(Offset a, Offset c, Offset b, double t) {
    return (c - a) * (2 * (1 - t)) + (b - c) * (2 * t);
  }

  Offset _normal(Offset v) {
    final len = math.sqrt(v.dx * v.dx + v.dy * v.dy);
    if (len <= 0.001) return const Offset(0, 1);
    return Offset(-v.dy / len, v.dx / len);
  }
}
