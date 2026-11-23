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
import '../../world/scene/building_tap_geometry.dart';

/// 岛屿装饰管理器：预加载、等级过滤、创建并挂载 Flame 组件。
class DecorManager {
  final Map<String, Sprite> _spriteCache = {};
  final List<Component> _activeComponents = [];
  final Map<String, double> _randomScaleById = {};
  final DecorScaleResolver _scaleResolver = const DecorScaleResolver();
  int _loadedLevel = 0;
  Vector2 _lastViewport = Vector2.zero();
  double _lastIslandRadius = 0;
  double _lastPlateScale = 1;
  bool _lastPaintedPlate = false;
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
    _lastPlateScale = 1;
    _lastPaintedPlate = false;
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
    double plateScale = 1,
    bool layoutOnPaintedPlate = false,
  }) async {
    if (!_viewportReady(viewportSize)) return;

    if (userLevel == _loadedLevel &&
        viewportSize == _lastViewport &&
        (islandRadius - _lastIslandRadius).abs() < 0.0001 &&
        (plateScale - _lastPlateScale).abs() < 0.0001 &&
        _lastPaintedPlate == layoutOnPaintedPlate &&
        _activeComponents.isNotEmpty) {
      return;
    }

    _loadedLevel = userLevel;
    _lastViewport = viewportSize.clone();
    _lastIslandRadius = islandRadius;
    _lastPlateScale = plateScale;
    _lastPaintedPlate = layoutOnPaintedPlate;

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
        scale: plateScale,
      );
    }

    await _preloadSprites(game, unlocked);

    for (final component in _activeComponents) {
      component.removeFromParent();
    }
    _activeComponents.clear();

    final buildingRects = <Rect>[
      for (final building in buildings)
        mainIslandBuildingTapRect(
          definitionId: building.definitionId,
          plateAnchor: building.anchor,
          sceneSize: viewport,
          plateScale: plateScale,
        ).inflate(8),
    ];

    for (final config in unlocked) {
      final sprite = _spriteCache[config.id];
      if (sprite == null) continue;

      final resolved = positions[config.id];
      // 大树无合法落点：跳过渲染，绝不回退到配置默认坐标叠点。
      if (resolved == null && DecorPlacementResolver.isLargeTree(config)) {
        continue;
      }
      if (resolved == null) continue;
      final instance = _resolveInstance(config);
      final Offset position;
      if (instance.category == DecorCategory.cloud && layoutOnPaintedPlate) {
        position = _cloudInOpenSky(
          config: instance,
          sprite: sprite,
          viewport: viewport,
          userLevel: userLevel,
          plateScale: plateScale,
        );
      } else if (instance.category == DecorCategory.tree &&
          layoutOnPaintedPlate) {
        final separated = _shiftTreeOffBuildings(
          config: instance,
          position: resolved,
          viewport: viewport,
          userLevel: userLevel,
          sprite: sprite,
          buildingRects: buildingRects,
        );
        if (separated == null) continue;
        position = separated;
      } else {
        position = resolved;
      }
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

  /// 云的脚点落在岛坯上方的开阔天空里，身体不伸进顶栏，也不压到岛上。
  Offset _cloudInOpenSky({
    required DecorConfig config,
    required Sprite sprite,
    required Size viewport,
    required int userLevel,
    required double plateScale,
  }) {
    final size = _scaleResolver.computeSize(
      config: config,
      userLevel: userLevel,
      spriteSrcSize: sprite.srcSize,
      viewportHeight: viewport.height,
    );
    final top = PaintedIslandAsset.openSkyTop(viewport, scale: plateScale);
    final bottom =
        PaintedIslandAsset.openSkyBottom(viewport, scale: plateScale);
    final minFoot = top + size.y;
    final slot = (config.x * 0.73) % 1;
    final foot = bottom <= minFoot
        ? bottom
        : minFoot + (bottom - minFoot) * slot;
    return Offset(config.x, foot / viewport.height);
  }

  /// 树冠和建筑立面重叠时，把树推向左右岸。推到岸边仍重叠就不再画这棵树。
  Offset? _shiftTreeOffBuildings({
    required DecorConfig config,
    required Offset position,
    required Size viewport,
    required int userLevel,
    required Sprite sprite,
    required List<Rect> buildingRects,
  }) {
    if (buildingRects.isEmpty) return position;
    var norm = position;
    final minX = viewport.width * 0.10;
    final maxX = viewport.width * 0.90;
    for (var step = 0; step < 12; step++) {
      final size = _scaleResolver.computeSize(
        config: config,
        userLevel: userLevel,
        spriteSrcSize: sprite.srcSize,
        viewportHeight: viewport.height,
        normalizedAnchorY: norm.dy,
      );
      final foot = Offset(norm.dx * viewport.width, norm.dy * viewport.height);
      final rect = Rect.fromLTWH(
        foot.dx - size.x / 2,
        foot.dy - size.y,
        size.x,
        size.y,
      );
      Rect? hit;
      for (final building in buildingRects) {
        if (rect.overlaps(building)) {
          hit = building;
          break;
        }
      }
      if (hit == null) return norm;
      final nextX = foot.dx + (foot.dx < hit.center.dx ? -26 : 26);
      if (nextX < minX || nextX > maxX) return null;
      norm = Offset(nextX / viewport.width, norm.dy);
    }
    return null;
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
