import 'dart:async';

import '../../engine/world_state.dart';
import '../../../island/decor/decor_manager.dart';
import 'world_layer.dart';

/// 装饰层：通过 [DecorManager] 数据驱动加载 PNG 装饰。
class DecorLayer extends WorldLayer {
  DecorLayer() : super(layerPriority: 100);

  final DecorManager _manager = DecorManager();
  int _lastLevel = 0;

  @override
  void onWorldStateChanged(WorldState worldState) {
    final level = _resolveUserLevel(worldState);
    if (level == _lastLevel && _manager.hasActiveDecor) {
      return;
    }
    _lastLevel = level;
    unawaited(_reloadDecor(level));
  }

  Future<void> _reloadDecor(int level, {bool force = false}) async {
    if (!isMounted) return;
    if (force) {
      _manager.invalidateCache();
    }
    await _manager.loadDecor(
      game: game,
      islandWorld: game,
      userLevel: level,
      viewportSize: sceneSize,
    );
  }

  int _resolveUserLevel(WorldState worldState) {
    if (worldState.characters.isEmpty) return 1;
    return worldState.characters.first.level;
  }

  @override
  void onRemove() {
    _manager.dispose();
    super.onRemove();
  }
}
