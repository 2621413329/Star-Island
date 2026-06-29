import 'dart:async';

import 'package:flame/components.dart';

import '../../engine/world_state.dart';
import '../../../common/island_contracts/decor_manager.dart';
import 'world_layer.dart';

/// 装饰层：通过 [DecorManager] 数据驱动加载 PNG 装饰。
class DecorLayer extends WorldLayer {
  DecorLayer({this.userId}) : super(layerPriority: 100);

  final String? userId;
  final DecorManager _manager = DecorManager();
  int _lastLevel = 0;
  Vector2? _loadedViewport;

  @override
  void onMount() {
    super.onMount();
    _manager.setUserId(userId);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x < 1 || size.y < 1) return;
    final prev = _loadedViewport;
    if (prev != null &&
        (prev.x - size.x).abs() < 1 &&
        (prev.y - size.y).abs() < 1 &&
        _manager.hasActiveDecor) {
      return;
    }
    if (_lastLevel > 0) {
      unawaited(_reloadDecor(_lastLevel, force: true));
    }
  }

  @override
  void onWorldStateChanged(WorldState worldState) {
    final level = _resolveUserLevel(worldState);
    final previousLevel = _lastLevel;
    _lastLevel = level;
    if (sceneSize.x < 1 || sceneSize.y < 1) return;
    if (level == previousLevel &&
        _manager.hasActiveDecor &&
        _loadedViewport != null &&
        _loadedViewport == sceneSize) {
      return;
    }
    unawaited(_reloadDecor(level));
  }

  Future<void> _reloadDecor(int level, {bool force = false}) async {
    if (!isMounted) return;
    if (sceneSize.x < 1 || sceneSize.y < 1) return;
    if (force) {
      _manager.invalidateCache();
    }
    await _manager.loadDecor(
      game: game,
      islandWorld: game,
      userLevel: level,
      viewportSize: sceneSize,
    );
    _loadedViewport = sceneSize.clone();
  }

  int _resolveUserLevel(WorldState worldState) {
    if (worldState.anchors.any((anchor) => anchor.type == 'story_island')) {
      return 0;
    }
    if (worldState.buildings.any(
      (building) => building.definitionId.startsWith('story_island_'),
    )) {
      return 0;
    }
    if (worldState.characters.isEmpty) return 1;
    return worldState.characters.first.level;
  }

  @override
  void onRemove() {
    _manager.dispose();
    super.onRemove();
  }
}
