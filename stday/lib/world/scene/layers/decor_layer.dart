import 'dart:async';

import 'package:flame/components.dart';

import '../../engine/world_state.dart';
import '../../../common/island_contracts/decor_manager.dart';
import 'world_layer.dart';

/// 装饰层：通过 [DecorManager] 数据驱动加载 PNG 装饰。
class DecorLayer extends WorldLayer {
  DecorLayer({this.userId, this.decorMaxUnlockLevel}) : super(layerPriority: 0);

  final String? userId;

  /// 预览等场景下限制装饰最高解锁等级（如 Lv3）；null 表示不限制。
  final int? decorMaxUnlockLevel;
  final DecorManager _manager = DecorManager();
  int _lastLevel = 0;
  Vector2? _loadedViewport;
  double _lastIslandRadius = 0;
  List<BuildingSnapshot> _lastBuildings = const [];

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
      unawaited(_reloadDecor(
        _lastLevel,
        buildings: _lastBuildings,
        islandRadius: _lastIslandRadius,
        force: true,
      ));
    }
  }

  @override
  void onWorldStateChanged(WorldState worldState) {
    final level = _resolveUserLevel(worldState);
    final previousLevel = _lastLevel;
    final islandRadius = worldState.island.radius;
    _lastLevel = level;
    _lastBuildings = worldState.buildings;
    if (sceneSize.x < 1 || sceneSize.y < 1) return;
    if (level == previousLevel &&
        (islandRadius - _lastIslandRadius).abs() < 0.0001 &&
        _manager.hasActiveDecor &&
        _loadedViewport != null &&
        _loadedViewport == sceneSize) {
      return;
    }
    unawaited(_reloadDecor(
      level,
      buildings: worldState.buildings,
      islandRadius: islandRadius,
    ));
  }

  Future<void> _reloadDecor(
    int level, {
    required List<BuildingSnapshot> buildings,
    required double islandRadius,
    bool force = false,
  }) async {
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
      buildings: buildings,
      islandRadius: islandRadius,
    );
    _loadedViewport = sceneSize.clone();
    _lastIslandRadius = islandRadius;
  }

  int _resolveUserLevel(WorldState worldState) {
    var level = 1;
    if (worldState.characters.isNotEmpty) {
      level = worldState.characters.first.level;
    }
    final cap = decorMaxUnlockLevel;
    if (cap != null && level > cap) return cap;
    return level;
  }

  @override
  void onRemove() {
    _manager.dispose();
    super.onRemove();
  }
}
