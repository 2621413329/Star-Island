import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../engine/world_state.dart';

/// 世界渲染层基类；通过 priority 控制 z 序。
abstract class WorldLayer extends Component with HasGameReference<FlameGame> {
  WorldLayer({required this.layerPriority});

  final int layerPriority;

  @override
  int get priority => layerPriority;

  WorldState? _state;

  WorldState get state => _state!;

  Vector2 get sceneSize => game.size;

  void applyWorldState(WorldState worldState) {
    _state = worldState;
    onWorldStateChanged(worldState);
  }

  void onWorldStateChanged(WorldState worldState) {}
}
