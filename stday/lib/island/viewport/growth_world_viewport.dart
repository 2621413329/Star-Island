import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/device_profile.dart';
import '../../core/growth/growth_system.dart';
import '../../core/models/mood_island_config.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/providers/island_world_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/world_state_provider.dart';
import '../../world/engine/world_state.dart';
import '../../world/rendering/world_state_cache.dart';
import '../3d/island_3d_config.dart';
import '../3d/island_3d_support.dart';
import '../3d/viewport/island_3d_viewport_stub.dart'
    if (dart.library.io) '../3d/viewport/island_3d_viewport.dart';
import '../../world/scene/island_gesture_surface.dart';
import '../../world/scene/world_scene.dart';

/// Growth Island 2.0 唯一岛屿渲染入口。
class GrowthWorldViewport extends ConsumerStatefulWidget {
  const GrowthWorldViewport({
    super.key,
    this.moodId,
    this.palette,
    this.companionStyle,
    this.moments = const [],
    this.islandConfig,
    this.summary,
    this.worldState,
    this.useIslandWorldProvider = false,
    this.scale = 1.0,
    this.compact = false,
    this.enginePaused = false,
    this.interactive = true,
    this.force2D = false,
    this.onCharacterInteraction,
  });

  final String? moodId;
  final MoodPalette? palette;
  final MoodIslandConfig? islandConfig;
  final String? companionStyle;
  final List<DailyMomentModel> moments;
  final GrowthSummary? summary;

  /// 外部注入的世界快照；优先于内部构建。
  final WorldState? worldState;

  /// 为 true 时从 [islandWorldProvider] 读取（岛屿首页）。
  final bool useIslandWorldProvider;
  final double scale;
  final bool compact;
  final bool enginePaused;
  final bool interactive;

  /// 视觉验收和低端设备兜底时强制使用 Flame 2D 渲染。
  final bool force2D;

  final void Function(
    DailyMomentModel moment,
    String? nearbyBuildingId,
    String characterId,
  )? onCharacterInteraction;

  @override
  GrowthWorldViewportState createState() => GrowthWorldViewportState();
}

class GrowthWorldViewportState extends ConsumerState<GrowthWorldViewport> {
  final GlobalKey<WorldSceneWidgetState> _sceneKey = GlobalKey();
  final WorldStateCache _stateCache = WorldStateCache();
  Timer? _highlightTimer;
  String? _highlightedEventId;
  double _viewZoom = 1;
  double _viewRotation = 0;
  bool _force2DFallback = false;

  void playMoment(String momentId) {
    _highlightMoment(momentId);
    _sceneKey.currentState?.triggerPerformance(momentId);
  }

  void resetIslandView() {
    _viewZoom = 1;
    _viewRotation = 0;
    _sceneKey.currentState?.setViewTransform(zoom: 1, rotationRadians: 0);
    if (mounted) setState(() {});
  }

  void _highlightMoment(String momentId) {
    _highlightTimer?.cancel();
    if (mounted) setState(() => _highlightedEventId = momentId);
    _highlightTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _highlightedEventId = null);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _stateCache.clear();
    super.dispose();
  }

  WorldState _resolveWorldState() {
    if (widget.worldState != null) return widget.worldState!;
    if (widget.useIslandWorldProvider) {
      return ref.watch(islandWorldProvider);
    }

    final summary = widget.summary ??
        ref.watch(growthSummaryProvider).valueOrNull ??
        GrowthSummary.guest();
    final islandStyle = widget.islandConfig ??
        ref.read(islandStyleResolverProvider).resolve(moodId: widget.moodId);
    final companionStyle =
        widget.companionStyle ?? ref.read(userCompanionProvider).renderStyle;
    final gender = ref.read(profileProvider).valueOrNull?.gender;

    return _stateCache.resolve(
      buildService: ref.read(islandBuildServiceProvider),
      engine: ref.read(growthWorldEngineProvider),
      summary: summary,
      todayMood: widget.moodId,
      moments: widget.moments,
      islandStyle: islandStyle,
      companionStyle: companionStyle,
      companionGender: gender,
      compact: widget.compact,
      highlightedEventId: _highlightedEventId,
    );
  }

  void _handleCharacterTap(
    String characterId,
    String? linkedEventId,
    String? nearbyBuildingId,
  ) {
    if (linkedEventId == null || widget.onCharacterInteraction == null) return;
    DailyMomentModel? moment;
    for (final m in widget.moments) {
      if (m.id == linkedEventId) {
        moment = m;
        break;
      }
    }
    if (moment == null) return;
    widget.onCharacterInteraction!(
      moment,
      nearbyBuildingId,
      characterId,
    );
  }

  void _applyViewTransform(double zoom, double rotation) {
    _viewZoom = zoom;
    _viewRotation = rotation;
    _sceneKey.currentState?.setViewTransform(
      zoom: zoom,
      rotationRadians: rotation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldState = _resolveWorldState();
    final companion = ref.read(userCompanionProvider);
    final renderStyle = widget.companionStyle ?? companion.renderStyle;
    final device = DeviceProfile.fromContext(context);
    final compact = widget.compact || device.preferCompactIsland;

    final use3D = !widget.force2D &&
        !_force2DFallback &&
        Island3DSupport.shouldUse3D(
          prefer3D: Island3DConfig.prefer3D,
          profile: device,
        );

    Widget content;
    if (use3D) {
      content = Island3DViewport(
        worldState: worldState,
        companionStyle: renderStyle,
        compact: compact,
        scale: widget.scale,
        onLoadFailed: () {
          if (mounted) setState(() => _force2DFallback = true);
        },
      );
    } else {
      final scene = WorldSceneWidget(
        key: _sceneKey,
        worldState: worldState,
        compact: compact,
        companionStyle: renderStyle,
        highlightedEventId: _highlightedEventId,
        enginePaused: widget.enginePaused,
        onCharacterTap:
            widget.onCharacterInteraction != null ? _handleCharacterTap : null,
        initialViewZoom: _viewZoom,
        initialViewRotation: _viewRotation,
      );

      content = widget.interactive
          ? IslandGestureSurface(
              enabled: !widget.enginePaused,
              onTransform: _applyViewTransform,
              child: scene,
            )
          : scene;
    }

    if (widget.compact) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: content,
      );
    }

    if (use3D) {
      return content;
    }

    return Transform.scale(
      scale: widget.scale,
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}
