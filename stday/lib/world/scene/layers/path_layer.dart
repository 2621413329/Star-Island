import 'dart:ui';

import '../../../island/path/path_material_painter.dart';
import '../../../island/path/path_projection.dart';
import 'world_layer.dart';

class PathLayer extends WorldLayer {
  PathLayer() : super(layerPriority: -35);

  final PathProjection _projection = const PathProjection();
  final PathMaterialPainter _painter = const PathMaterialPainter();

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final size = sceneSize;
    for (final path in state.paths) {
      final start = Offset(path.start.dx * size.x, path.start.dy * size.y);
      final end = Offset(path.end.dx * size.x, path.end.dy * size.y);
      final projected = _projection.project(
        start: start,
        end: end,
        baseWidth: path.width,
        sceneSize: Size(size.x, size.y),
      );
      _painter.paint(
        canvas,
        path: projected,
        material: path.pathType,
      );
    }
  }
}
