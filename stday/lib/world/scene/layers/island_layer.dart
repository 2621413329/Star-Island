import 'dart:ui';

import '../../../common/island_contracts/decor_config.dart';
import '../../../common/island_contracts/decor_placement_resolver.dart';
import '../../engine/world_state.dart';
import '../../island/island_renderer.dart';
import 'world_layer.dart';

class IslandLayer extends WorldLayer {
  IslandLayer({required this.compact}) : super(layerPriority: -50);

  final bool compact;
  late final IslandRenderer _renderer = IslandRenderer(compact: compact);
  Map<String, Offset> _decorPositions = const {};

  @override
  void update(double dt) {
    super.update(dt);
    _renderer.update(dt);
  }

  @override
  void onWorldStateChanged(WorldState worldState) {
    final level =
        worldState.characters.isEmpty ? 1 : worldState.characters.first.level;
    _decorPositions =
        const DecorPlacementResolver().resolve(DecorConfigs.unlockedAt(level));
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    _renderer.render(
      canvas,
      Size(s.x, s.y),
      state.island,
      state.environment,
      worldState: state,
      decorPositions: _decorPositions,
    );
  }
}
