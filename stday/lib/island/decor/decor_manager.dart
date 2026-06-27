import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'animated_decor_component.dart';
import 'decor_config.dart';
import 'decor_placement_resolver.dart';
import 'decor_position_store.dart';
import 'decor_scale_resolver.dart';

/// 岛屿装饰管理器：预加载、等级过滤、创建并挂载 Flame 组件。
class DecorManager {
  final Map<String, Sprite> _spriteCache = {};
  final List<Component> _activeComponents = [];
  final Map<String, double> _randomScaleById = {};
  final DecorScaleResolver _scaleResolver = const DecorScaleResolver();
  int _loadedLevel = 0;
  Vector2 _lastViewport = Vector2.zero();
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
  }) async {
    if (!_viewportReady(viewportSize)) return;

    if (userLevel == _loadedLevel &&
        viewportSize == _lastViewport &&
        _activeComponents.isNotEmpty) {
      return;
    }

    _loadedLevel = userLevel;
    _lastViewport = viewportSize.clone();

    final unlocked = DecorConfigs.unlockedAt(userLevel);
    const resolver = DecorPlacementResolver();
    final store = DecorPositionStore(userId: _userId);
    final stored = await store.loadAll();
    final positions = <String, Offset>{};
    final occupied = <Rect>[];

    final sorted = [...unlocked]..sort((a, b) {
        return a.unlockLevel.compareTo(b.unlockLevel);
      });

    for (final config in sorted) {
      if (resolver.isSkyDecor(config)) {
        positions[config.id] = Offset(config.x, config.y);
        continue;
      }

      final saved = stored[config.id];
      if (saved != null) {
        positions[config.id] = saved;
        occupied.add(resolver.paddedOccupancyFor(config, saved));
        continue;
      }

      final seed = Object.hash(
        _userId ?? 'guest',
        config.id,
        config.unlockLevel,
        userLevel,
      );
      final position = resolver.resolveOne(
        config,
        occupied,
        randomSeed: seed,
      );
      positions[config.id] = position;
      occupied.add(resolver.paddedOccupancyFor(config, position));
      await store.save(config.id, position);
    }

    await _preloadSprites(game, unlocked);

    for (final component in _activeComponents) {
      component.removeFromParent();
    }
    _activeComponents.clear();

    for (final config in unlocked) {
      final sprite = _spriteCache[config.id];
      if (sprite == null) continue;

      final instance = _resolveInstance(config);
      final position = positions[config.id] ?? Offset(config.x, config.y);
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
