import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../engine/world_state.dart';
import 'layers/grass_foreground_layer.dart';
import 'layers/decor_layer.dart';
import 'layers/building_layer.dart';
import 'layers/character_layer.dart';
import 'layers/effect_layer.dart';
import 'layers/island_layer.dart';
import 'layers/main_island_debug_overlay_layer.dart';
import 'layers/ocean_layer.dart';
import 'layers/sky_layers.dart';
import 'layers/ui_overlay_layer.dart';
import 'layers/world_layer.dart';
import '../island/painted_island_asset.dart';
import 'split_world_view.dart';
import 'world_paint_pass.dart';
import 'world_render_probe.dart';

/// 成长世界主场景：按 Layer 分层渲染，禁止单 Stack 堆叠所有元素。
class WorldScene extends FlameGame implements WorldPaintHost {
  WorldScene({
    required WorldState initialState,
    this.compact = false,
    this.companionStyle = 'mindscape',
    this.userId,
    this.islandOnly = false,
    this.enableDecor = true,
    this.decorMaxUnlockLevel,
    this.showBuildings = true,
    this.showCharacters = true,
    this.showDebugOverlay = false,
    this.onCharacterTap,
    this.onBuildingTap,
    this.centerBoardCamera = false,
    String? highlightedEventId,
    double initialViewZoom = 1,
    double initialViewRotation = 0,
  })  : _state = initialState,
        _pendingHighlight = highlightedEventId,
        _viewZoom = initialViewZoom.clamp(0.65, 5.0),
        _viewRotation = initialViewRotation,
        super();

  WorldState _state;
  final bool compact;
  final String companionStyle;
  final String? userId;
  final bool islandOnly;
  final bool enableDecor;
  final int? decorMaxUnlockLevel;
  final bool showBuildings;
  final bool showCharacters;
  final bool showDebugOverlay;
  double _viewZoom = 1;
  double _viewRotation = 0;
  Offset _viewPan = Offset.zero;

  /// 角色点击回调：(characterId, linkedEventId, nearbyBuildingId)
  final void Function(
    String characterId,
    String? linkedEventId,
    String? nearbyBuildingId,
  )? onCharacterTap;

  final void Function(BuildingSnapshot building)? onBuildingTap;

  /// 详情页岛面绕视口中心缩放。取景器若再偏向地标，点击会跟着放大比例漂开。
  final bool centerBoardCamera;

  @override
  double get plateScale =>
      centerBoardCamera ? PaintedIslandAsset.detailScale : 1;

  late final EffectLayer _effectLayer;
  late final CharacterLayer _characterLayer;
  late final BuildingLayer _buildingLayer;
  bool _ready = false;
  String? _pendingHighlight;
  final List<void Function()> _retainedListeners = [];
  final List<void Function()> _islandListeners = [];
  final List<void Function()> _transformListeners = [];

  @override
  WorldPaintPass paintPass = WorldPaintPass.full;

  @override
  bool suppressFullPaint = false;

  @override
  double get heroFootDy {
    if (_state.characters.isEmpty) return 0.625;
    final protagonist = _state.characters.where((c) => c.id == 'protagonist');
    if (protagonist.isNotEmpty) return protagonist.first.normalizedPos.dy;
    return _state.characters.first.normalizedPos.dy;
  }

  @override
  double get boardZoom => _viewZoom;

  @override
  double get boardRotation => _viewRotation;

  @override
  Offset get boardPan => _viewPan;

  @override
  void addRetainedFrameListener(void Function() listener) {
    _retainedListeners.add(listener);
  }

  @override
  void removeRetainedFrameListener(void Function() listener) {
    _retainedListeners.remove(listener);
  }

  @override
  void addIslandFrameListener(void Function() listener) {
    _islandListeners.add(listener);
  }

  @override
  void removeIslandFrameListener(void Function() listener) {
    _islandListeners.remove(listener);
  }

  @override
  void addBoardTransformListener(void Function() listener) {
    _transformListeners.add(listener);
  }

  @override
  void removeBoardTransformListener(void Function() listener) {
    _transformListeners.remove(listener);
  }

  void _notify(List<void Function()> listeners) {
    for (final listener in List<void Function()>.of(listeners)) {
      listener();
    }
  }

  @override
  void invalidateRetainedFrame() {
    WorldRenderProbe.noteInvalidation(islandOnly: false);
    _notify(_retainedListeners);
    _notify(_islandListeners);
  }

  @override
  void invalidateIslandFrame() {
    WorldRenderProbe.noteInvalidation(islandOnly: true);
    _notify(_islandListeners);
  }

  void _notifyBoardTransform() {
    WorldRenderProbe.noteCameraTransform();
    _notify(_transformListeners);
  }

  WorldState get worldState => _state;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void update(double dt) {
    if (WorldRenderControls.freezeMotion) dt = 0;
    if (!WorldRenderProbe.enabled) {
      super.update(dt);
      return;
    }
    final watch = Stopwatch()..start();
    super.update(dt);
    WorldRenderProbe.noteUpdate(watch.elapsedMicroseconds);
  }

  @override
  void render(Canvas canvas) {
    if (suppressFullPaint && paintPass == WorldPaintPass.full) {
      WorldRenderProbe.noteSuppressedFullPaint();
      return;
    }
    if (!WorldRenderProbe.enabled) {
      super.render(canvas);
      return;
    }
    final watch = Stopwatch()..start();
    super.render(canvas);
    WorldRenderProbe.noteRender(paintPass.name, watch.elapsedMicroseconds);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.anchor = Anchor.center;
    _publishView(contentDirty: true);
  }

  /// 天空、海面和岛面共用这一套缩放和平移。
  void setViewTransform({
    double? zoom,
    double? rotationRadians,
    Offset? pan,
  }) {
    if (zoom != null) {
      _viewZoom = zoom.clamp(0.65, 5.0);
    }
    if (rotationRadians != null) {
      _viewRotation = rotationRadians;
    }
    if (pan != null) {
      _viewPan = pan;
    }
    _publishView(contentDirty: false);
  }

  void _publishView({required bool contentDirty}) {
    if (size.x > 0 && size.y > 0) {
      final focus = centerBoardCamera ? size / 2 : _focusPosition(size);
      final zoom = _viewZoom == 0 ? 1.0 : _viewZoom;
      camera.viewfinder.position =
          focus - Vector2(_viewPan.dx / zoom, _viewPan.dy / zoom);
    }
    camera.viewfinder.zoom = _viewZoom;
    camera.viewfinder.angle = _viewRotation;
    if (contentDirty || WorldRenderControls.rebakeOnCamera) {
      invalidateRetainedFrame();
    } else {
      _notifyBoardTransform();
    }
  }

  @override
  void withNeutralViewfinder(void Function() action) {
    final view = camera.viewfinder;
    final zoom = view.zoom;
    final angle = view.angle;
    final position = view.position.clone();
    view.zoom = 1;
    view.angle = 0;
    if (size.x > 0 && size.y > 0) {
      view.position = size / 2;
    }
    try {
      action();
    } finally {
      view.zoom = zoom;
      view.angle = angle;
      view.position = position;
    }
  }

  Vector2 _focusPosition(Vector2 viewportSize) {
    final center = viewportSize / 2;
    WorldAnchorSnapshot? focusAnchor;
    for (final anchor in _state.anchors) {
      if (anchor.cameraFocus) {
        focusAnchor = anchor;
        break;
      }
    }
    if (focusAnchor == null) return center;
    final anchor = Vector2(
      focusAnchor.position.dx * viewportSize.x,
      focusAnchor.position.dy * viewportSize.y,
    );
    return center + (anchor - center) * 0.22;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
    _publishView(contentDirty: false);
    _effectLayer = EffectLayer();
    _characterLayer = CharacterLayer(
      companionStyle: companionStyle,
      compact: compact,
      onCharacterTap: onCharacterTap,
    );
    _buildingLayer = BuildingLayer(onBuildingTap: onBuildingTap);
    final decorLayer = enableDecor
        ? DecorLayer(userId: userId, decorMaxUnlockLevel: decorMaxUnlockLevel)
        : null;
    final layers = islandOnly
        ? <WorldLayer>[
            IslandLayer(compact: compact),
            if (decorLayer != null) decorLayer,
            if (showBuildings) _buildingLayer,
            if (showCharacters) _characterLayer,
            if (showDebugOverlay && kDebugMode) MainIslandDebugOverlayLayer(),
          ]
        : <WorldLayer>[
            SkyLayer(),
            CloudLayer(),
            DistantLayer(),
            OceanLayer(),
            IslandLayer(compact: compact),
            if (decorLayer != null) decorLayer,
            if (showBuildings) _buildingLayer,
            GrassForegroundLayer(),
            if (showCharacters) _characterLayer,
            _effectLayer,
            UIOverlayLayer(),
            if (showDebugOverlay && kDebugMode) MainIslandDebugOverlayLayer(),
          ];
    for (final layer in layers) {
      await add(layer);
      layer.applyWorldState(_state);
    }
    _ready = true;
    _effectLayer.setHighlight(_pendingHighlight);
    invalidateRetainedFrame();
  }

  void applyWorldState(WorldState state, {String? highlightedEventId}) {
    _state = state;
    _pendingHighlight = highlightedEventId;
    if (!_ready) return;
    for (final layer in children.whereType<WorldLayer>()) {
      layer.applyWorldState(state);
    }
    _publishView(contentDirty: true);
    _effectLayer.setHighlight(highlightedEventId);
  }

  /// 详情页的点击坐标已经是缩放前的画面坐标，和贴图用的是同一套。
  @override
  void handleScreenTap(Offset screenPoint) {
    if (!_ready || size.x <= 0 || size.y <= 0) return;
    final point = Vector2(screenPoint.dx, screenPoint.dy);
    if (showBuildings && _buildingLayer.tryTapAt(point)) return;
    if (showCharacters) _characterLayer.tryTapAt(point);
  }

  void triggerPerformance(String? linkedEventId) {
    if (!_ready) return;
    _characterLayer.triggerPerformance(linkedEventId);
  }

  void triggerAllPerformances() {
    if (!_ready) return;
    _characterLayer.triggerAllPerformances();
  }
}

bool worldVisualIdentityChanged(WorldState a, WorldState b) {
  if (a.island.prosperityTier != b.island.prosperityTier) return true;
  if ((a.island.radius - b.island.radius).abs() > 0.0001) return true;
  if (a.buildings.length != b.buildings.length) return true;
  if (a.decorations.length != b.decorations.length) return true;
  final levelA = a.characters.isEmpty ? 1 : a.characters.first.level;
  final levelB = b.characters.isEmpty ? 1 : b.characters.first.level;
  if (levelA != levelB) return true;
  if (a.paths.length != b.paths.length) return true;
  if (a.effects.length != b.effects.length) return true;
  return false;
}

class WorldSceneWidget extends StatefulWidget {
  const WorldSceneWidget({
    super.key,
    required this.worldState,
    this.compact = false,
    this.companionStyle = 'mindscape',
    this.userId,
    this.highlightedEventId,
    this.enginePaused = false,
    this.islandOnly = false,
    this.enableDecor = true,
    this.decorMaxUnlockLevel,
    this.showBuildings = true,
    this.showCharacters = true,
    this.showDebugOverlay = false,
    this.initialViewZoom = 1,
    this.initialViewRotation = 0,
    this.retainStaticBoard = false,
    this.onCharacterTap,
    this.onBuildingTap,
  });

  final WorldState worldState;
  final bool compact;
  final String companionStyle;
  final String? userId;
  final String? highlightedEventId;
  final bool enginePaused;
  final bool islandOnly;
  final bool enableDecor;
  final int? decorMaxUnlockLevel;
  final bool showBuildings;
  final bool showCharacters;
  final bool showDebugOverlay;
  final double initialViewZoom;
  final double initialViewRotation;

  /// 主岛详情：岛体留在显卡里，只重画云、浪和角色。
  final bool retainStaticBoard;
  final void Function(
    String characterId,
    String? linkedEventId,
    String? nearbyBuildingId,
  )? onCharacterTap;
  final void Function(BuildingSnapshot building)? onBuildingTap;

  @override
  State<WorldSceneWidget> createState() => WorldSceneWidgetState();
}

class WorldSceneWidgetState extends State<WorldSceneWidget> {
  late WorldScene _game;

  @override
  void initState() {
    super.initState();
    _game = WorldScene(
      initialState: widget.worldState,
      compact: widget.compact,
      companionStyle: widget.companionStyle,
      userId: widget.userId,
      islandOnly: widget.islandOnly,
      enableDecor: widget.enableDecor,
      decorMaxUnlockLevel: widget.decorMaxUnlockLevel,
      showBuildings: widget.showBuildings,
      showCharacters: widget.showCharacters,
      showDebugOverlay: widget.showDebugOverlay,
      highlightedEventId: widget.highlightedEventId,
      onCharacterTap: widget.onCharacterTap,
      onBuildingTap: widget.onBuildingTap,
      centerBoardCamera: widget.retainStaticBoard,
      initialViewZoom: widget.initialViewZoom,
      initialViewRotation: widget.initialViewRotation,
    );
    _syncEnginePause();
  }

  bool get _useSplit =>
      widget.retainStaticBoard && !WorldRenderControls.forceFullPaint;

  void _syncEnginePause() {
    if (widget.enginePaused || _useSplit) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  @override
  void didUpdateWidget(covariant WorldSceneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enginePaused != widget.enginePaused ||
        oldWidget.retainStaticBoard != widget.retainStaticBoard) {
      _syncEnginePause();
    }
    if (identical(oldWidget.worldState, widget.worldState) &&
        oldWidget.highlightedEventId == widget.highlightedEventId &&
        oldWidget.compact == widget.compact &&
        oldWidget.islandOnly == widget.islandOnly &&
        oldWidget.enableDecor == widget.enableDecor &&
        oldWidget.decorMaxUnlockLevel == widget.decorMaxUnlockLevel &&
        oldWidget.showBuildings == widget.showBuildings &&
        oldWidget.showCharacters == widget.showCharacters &&
        oldWidget.showDebugOverlay == widget.showDebugOverlay &&
        oldWidget.companionStyle == widget.companionStyle &&
        oldWidget.retainStaticBoard == widget.retainStaticBoard) {
      return;
    }
    if (oldWidget.compact != widget.compact ||
        oldWidget.islandOnly != widget.islandOnly ||
        oldWidget.enableDecor != widget.enableDecor ||
        oldWidget.decorMaxUnlockLevel != widget.decorMaxUnlockLevel ||
        oldWidget.showBuildings != widget.showBuildings ||
        oldWidget.showCharacters != widget.showCharacters ||
        oldWidget.showDebugOverlay != widget.showDebugOverlay ||
        oldWidget.companionStyle != widget.companionStyle ||
        worldVisualIdentityChanged(oldWidget.worldState, widget.worldState) ||
        oldWidget.worldState.island.style.moodId !=
            widget.worldState.island.style.moodId ||
        oldWidget.worldState.island.style.styleKey !=
            widget.worldState.island.style.styleKey ||
        oldWidget.worldState.island.style.islandShape !=
            widget.worldState.island.style.islandShape ||
        oldWidget.worldState.island.style.biome !=
            widget.worldState.island.style.biome) {
      _game = WorldScene(
        initialState: widget.worldState,
        compact: widget.compact,
        companionStyle: widget.companionStyle,
        userId: widget.userId,
        islandOnly: widget.islandOnly,
        enableDecor: widget.enableDecor,
        showBuildings: widget.showBuildings,
        showCharacters: widget.showCharacters,
        showDebugOverlay: widget.showDebugOverlay,
        highlightedEventId: widget.highlightedEventId,
        onCharacterTap: widget.onCharacterTap,
        onBuildingTap: widget.onBuildingTap,
        centerBoardCamera: widget.retainStaticBoard,
        initialViewZoom: widget.initialViewZoom,
        initialViewRotation: widget.initialViewRotation,
      );
      _syncEnginePause();
      setState(() {});
      return;
    }
    _game.applyWorldState(
      widget.worldState,
      highlightedEventId: widget.highlightedEventId,
    );
  }

  void triggerPerformance(String? linkedEventId) =>
      _game.triggerPerformance(linkedEventId);

  void triggerAllPerformances() => _game.triggerAllPerformances();

  void setViewTransform({
    double? zoom,
    double? rotationRadians,
    Offset? pan,
  }) {
    _game.setViewTransform(
      zoom: zoom,
      rotationRadians: rotationRadians,
      pan: pan,
    );
  }

  @visibleForTesting
  WorldScene get debugScene => _game;

  @override
  Widget build(BuildContext context) {
    if (_useSplit) {
      return SplitWorldView(key: ObjectKey(_game), game: _game);
    }
    return RepaintBoundary(
      child: GameWidget(game: _game),
    );
  }
}
