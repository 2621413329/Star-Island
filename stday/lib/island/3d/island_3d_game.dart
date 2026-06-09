import 'dart:async';
import 'dart:ui' show Color;

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/game.dart';

import '../../world/engine/world_state.dart';
import 'island_3d_camera.dart';
import 'island_3d_world_builder.dart';

/// flame_3d 岛屿主场景。
class Island3DGame extends FlameGame3D<World3D, Island3DCamera> {
  Island3DGame({
    required WorldState initialState,
    required this.companionStyle,
    this.compact = false,
  })  : _state = initialState,
        super(
          world: World3D(clearColor: const Color(0xFFE8F4F8)),
          camera: Island3DCamera(compact: compact),
        );

  WorldState _state;
  final String companionStyle;
  final bool compact;

  WorldState get worldState => _state;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    await _rebuildWorld();
  }

  Future<void> applyWorldState(WorldState state) async {
    if (_state.island.prosperityTier == state.island.prosperityTier &&
        _state.flora.length == state.flora.length &&
        _state.characters.length == state.characters.length &&
        _state.buildings.length == state.buildings.length) {
      _state = state;
      return;
    }
    _state = state;
    await _rebuildWorld();
  }

  Future<void> _rebuildWorld() async {
    world.removeAll(world.children);
    final nodes = await Island3DWorldBuilder.build(
      state: _state,
      compact: compact,
    );
    world.addAll(nodes);
  }
}
