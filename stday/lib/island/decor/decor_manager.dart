import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../world/engine/world_state.dart';
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
    final store = DecorPositionStore(userId: _userId);
    final stored = await store.loadAll();
    final positions = <String, Offset>{};
    final buildingBlocks =
        DecorPlacementResolver.buildingBlockedRegions(buildings);
    final occupied = <Rect>[...buildingBlocks];

    final sorted = [...unlocked]..sort((a, b) {
        // 大树优先占环岛缘，避免被草/花先占满后无处可落。
        final aTree = DecorPlacementResolver.isLargeTree(a);
        final bTree = DecorPlacementResolver.isLargeTree(b);
        if (aTree != bTree) return aTree ? -1 : 1;
        return a.unlockLevel.compareTo(b.unlockLevel);
      });

    for (final config in sorted) {
      if (resolver.isSkyDecor(config)) {
        positions[config.id] = Offset(config.x, config.y);
        continue;
      }

      final saved = stored[config.id];
      final isLargeTree = DecorPlacementResolver.isLargeTree(config);
      // 大树不复用旧缓存坐标（易聚堆）；始终按独占岸位重算。
      if (!isLargeTree &&
          saved != null &&
          resolver.isValidGroundPosition(config, saved, occupied,
              buildings: buildings) &&
          !occupied.any(
            (rect) => rect.overlaps(resolver.paddedOccupancyFor(config, saved)),
          )) {
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
      if (isLargeTree) {
        final position = resolver.resolveLargeTree(
          config,
          occupied,
          randomSeed: seed,
          buildings: buildings,
        );
        // 大树：无合法环岛点则跳过，绝不回退叠点。
        if (position == null) continue;
        positions[config.id] = position;
        occupied.add(resolver.paddedOccupancyFor(config, position));
        await store.save(config.id, position);
        continue;
      }

      final position = resolver.resolveOneOrNull(
        config,
        occupied,
        randomSeed: seed,
        buildings: buildings,
      );
      if (position == null) continue;
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
