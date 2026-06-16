import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../engine/world_state.dart';
import 'layers/building_layer.dart';
import 'layers/character_layer.dart';
import 'layers/decoration_layer.dart';
import 'layers/effect_layer.dart';
import 'layers/flora_layer.dart';
import 'layers/island_layer.dart';
import 'layers/ocean_layer.dart';
import 'layers/sky_layers.dart';
import 'layers/ui_overlay_layer.dart';
import 'layers/world_layer.dart';

/// 成长世界主场景：按 Layer 分层渲染，禁止单 Stack 堆叠所有元素。
class WorldScene extends FlameGame {
  WorldScene({
    required WorldState initialState,
    this.compact = false,
    this.companionStyle = 'mindscape',
    this.onCharacterTap,
    this.onBuildingTap,
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
  double _viewZoom = 1;
  double _viewRotation = 0;

  /// 角色点击回调：(characterId, linkedEventId, nearbyBuildingId)
  final void Function(
    String characterId,
    String? linkedEventId,
    String? nearbyBuildingId,
  )? onCharacterTap;

  final void Function(BuildingSnapshot building)? onBuildingTap;

  late final EffectLayer _effectLayer;
  late final CharacterLayer _characterLayer;
  late final BuildingLayer _buildingLayer;
  bool _ready = false;
  String? _pendingHighlight;

  WorldState get worldState => _state;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = _focusPosition(size);
    _applyViewTransform();
  }

  /// 双指缩放 + 单指旋转（绕视口中心），岛屿/小人/建筑同步变换。
  void setViewTransform({double? zoom, double? rotationRadians}) {
    if (zoom != null) {
      _viewZoom = zoom.clamp(0.65, 5.0);
    }
    if (rotationRadians != null) {
      _viewRotation = rotationRadians;
    }
    _applyViewTransform();
  }

  void _applyViewTransform() {
    if (size.x > 0 && size.y > 0) {
      camera.viewfinder.position = _focusPosition(size);
    }
    camera.viewfinder.zoom = _viewZoom;
    camera.viewfinder.angle = _viewRotation;
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
    camera.viewfinder.position = _focusPosition(size);
    _applyViewTransform();
    _effectLayer = EffectLayer();
    _characterLayer = CharacterLayer(
      companionStyle: companionStyle,
      onCharacterTap: onCharacterTap,
    );
    _buildingLayer = BuildingLayer(onBuildingTap: onBuildingTap);
    final layers = <WorldLayer>[
      SkyLayer(),
      CloudLayer(),
      DistantLayer(),
      OceanLayer(),
      IslandLayer(compact: compact),
      DecorationLayer(),
      _buildingLayer,
      DecorationLayer(treesOnly: true),
      FloraLayer(),
      _characterLayer,
      _effectLayer,
      UIOverlayLayer(),
    ];
    for (final layer in layers) {
      await add(layer);
      layer.applyWorldState(_state);
    }
    _ready = true;
    _effectLayer.setHighlight(_pendingHighlight);
  }

  void applyWorldState(WorldState state, {String? highlightedEventId}) {
    _state = state;
    _pendingHighlight = highlightedEventId;
    if (!_ready) return;
    for (final layer in children.whereType<WorldLayer>()) {
      layer.applyWorldState(state);
    }
    _applyViewTransform();
    _effectLayer.setHighlight(highlightedEventId);
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
    this.highlightedEventId,
    this.enginePaused = false,
    this.initialViewZoom = 1,
    this.initialViewRotation = 0,
    this.onCharacterTap,
    this.onBuildingTap,
  });

  final WorldState worldState;
  final bool compact;
  final String companionStyle;
  final String? highlightedEventId;
  final bool enginePaused;
  final double initialViewZoom;
  final double initialViewRotation;
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
      highlightedEventId: widget.highlightedEventId,
      onCharacterTap: widget.onCharacterTap,
      onBuildingTap: widget.onBuildingTap,
      initialViewZoom: widget.initialViewZoom,
      initialViewRotation: widget.initialViewRotation,
    );
    _syncEnginePause();
  }

  void _syncEnginePause() {
    if (widget.enginePaused) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  @override
  void didUpdateWidget(covariant WorldSceneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enginePaused != widget.enginePaused) {
      _syncEnginePause();
    }
    if (oldWidget.compact != widget.compact ||
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
        highlightedEventId: widget.highlightedEventId,
        onCharacterTap: widget.onCharacterTap,
        onBuildingTap: widget.onBuildingTap,
        initialViewZoom: widget.initialViewZoom,
        initialViewRotation: widget.initialViewRotation,
      );
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

  void setViewTransform({double? zoom, double? rotationRadians}) {
    _game.setViewTransform(zoom: zoom, rotationRadians: rotationRadians);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GameWidget(game: _game),
    );
  }
}
