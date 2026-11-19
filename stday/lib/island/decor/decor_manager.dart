import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../world/engine/world_state.dart';
import '../../world/scene/world_paint_pass.dart';
import 'animated_decor_component.dart';
import 'decor_config.dart';
import 'decor_placement_resolver.dart';
import 'decor_scale_resolver.dart';
import '../../world/island/painted_island_asset.dart';
import '../../world/island/painted_island_pits.dart';

/// 岛屿装饰管理器：预加载、等级过滤、创建并挂载 Flame 组件。
class DecorManager {
  final Map<String, Sprite> _spriteCache = {};
  final List<Component> _activeComponents = [];
  final Map<String, double> _randomScaleById = {};
  final DecorScaleResolver _scaleResolver = const DecorScaleResolver();
  int _loadedLevel = 0;
  Vector2 _lastViewport = Vector2.zero();
  double _lastIslandRadius = 0;
  String? _userId;

  bool get hasActiveDecor => _activeComponents.isNotEmpty;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    invalidateCache();
  }

  void invalidateCache() {
    _loadedLevel = 0;
    _lastViewport = Vector2.zero();
  }

  bool _viewportReady(Vector2 viewportSize) =>
      viewportSize.x >= 1 && viewportSize.y >= 1;

  /// 加载并显示当前等级已解锁的装饰。
  Future<void> loadDecor({
    required FlameGame game,
    required Component islandWorld,
    required int userLevel,
    required Vector2 viewportSize,
    Iterable<BuildingSnapshot> buildings = const [],
    double islandRadius = 1.0,
  }) async {
    if (!_viewportReady(viewportSize)) return;

    if (userLevel == _loadedLevel &&
        viewportSize == _lastViewport &&
        (islandRadius - _lastIslandRadius).abs() < 0.0001 &&
        _activeComponents.isNotEmpty) {
      return;
    }

    _loadedLevel = userLevel;
    _lastViewport = viewportSize.clone();
    _lastIslandRadius = islandRadius;

    final unlocked = DecorConfigs.unlockedMainIslandAt(userLevel);
    final resolver = DecorPlacementResolver(islandRadius: islandRadius);
    final positions = <String, Offset>{};
    final viewport = Size(viewportSize.x, viewportSize.y);

    for (final config in unlocked) {
      if (resolver.isSkyDecor(config)) {
        positions[config.id] = Offset(config.x, config.y);
        continue;
      }
      positions[config.id] = PaintedIslandAsset.plateToViewportNorm(
        PaintedIslandPits.decor(config.id),
        viewport,
      );
    }

    await _preloadSprites(game, unlocked);

    for (final component in _activeComponents) {
      component.removeFromParent();
    }
    _activeComponents.clear();

    for (final config in unlocked) {
      final sprite = _spriteCache[config.id];
      if (sprite == null) continue;

      final resolved = positions[config.id];
      // 大树无合法落点：跳过渲染，绝不回退到配置默认坐标叠点。
      if (resolved == null && DecorPlacementResolver.isLargeTree(config)) {
        continue;
      }
      if (resolved == null) continue;
      final position = resolved;
      final instance = _resolveInstance(config);
      final Component decorComponent;
      if (instance.animated) {
        decorComponent = AnimatedDecorComponent(
          config: instance,
          sprite: sprite,
          viewportSize: viewportSize,
          userLevel: userLevel,
          scaleResolver: _scaleResolver,
          position: position,
        );
      } else {
        decorComponent = StaticDecorComponent(
          config: instance,
          sprite: sprite,
          viewportSize: viewportSize,
          userLevel: userLevel,
          scaleResolver: _scaleResolver,
          position: position,
        );
      }

      islandWorld.add(decorComponent);
      _activeComponents.add(decorComponent);
    }
    if (game is WorldPaintHost) {
      (game as WorldPaintHost).invalidateIslandFrame();
    }
  }

  DecorConfig _resolveInstance(DecorConfig template) {
    final randomScale = _randomScaleById.putIfAbsent(
      template.id,
      () => DecorScaleResolver.randomScaleFor(template.id),
    );
    return template.copyWith(randomScale: randomScale);
  }

  Future<void> _preloadSprites(
    FlameGame game,
    List<DecorConfig> configs,
  ) async {
    for (final config in configs) {
      if (_spriteCache.containsKey(config.id)) continue;
      try {
        final image = await game.images.load(config.assetPath);
        _spriteCache[config.id] = Sprite(image);
      } catch (_) {}
    }
  }

  void dispose() {
    for (final component in _activeComponents) {
      component.removeFromParent();
    }
    _activeComponents.clear();
    _spriteCache.clear();
    _randomScaleById.clear();
    _loadedLevel = 0;
    _lastViewport = Vector2.zero();
  }
}
