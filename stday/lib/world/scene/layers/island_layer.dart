import 'dart:ui';

import '../../island/island_renderer.dart';
import 'world_layer.dart';

class IslandLayer extends WorldLayer {
  IslandLayer({required this.compact}) : super(layerPriority: -50);

  final bool compact;
  late final IslandRenderer _renderer = IslandRenderer(compact: compact);

  @override
  void update(double dt) {
    super.update(dt);
    _renderer.update(dt);
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    _renderer.render(canvas, Size(s.x, s.y), state.island, state.environment);
  }
}
