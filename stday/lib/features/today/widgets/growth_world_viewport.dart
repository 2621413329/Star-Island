import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/character_mood.dart';
import '../../../core/models/mood_island_config.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../data/models/profile_models.dart';
import '../../../design_system/companion_avatar.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/world_state_provider.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/rendering/world_state_cache.dart';
import '../../../world/scene/island_gesture_surface.dart';
import '../../../world/scene/world_scene.dart';

/// 成长世界视口：双指缩放、单指旋转；角色与岛屿同相机变换。
class GrowthWorldViewport extends ConsumerStatefulWidget {
  const GrowthWorldViewport({
    super.key,
    required this.moodId,
    required this.palette,
    required this.companionStyle,
    required this.moments,
    this.islandConfig,
    this.scale = 1.0,
    this.compact = false,
    this.enginePaused = false,
    this.interactive = true,
    this.onCompanionTap,
    this.onCharacterInteraction,
  });

  final String? moodId;
  final MoodPalette palette;
  final MoodIslandConfig? islandConfig;
  final String companionStyle;
  final List<DailyMomentModel> moments;
  final double scale;
  final bool compact;
  final bool enginePaused;
  final bool interactive;

  final void Function(DailyMomentModel moment, CompanionAvatarState? state)?
      onCompanionTap;

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

  void playMoment(String momentId) {
    _highlightMoment(momentId);
    _sceneKey.currentState?.triggerPerformance(momentId);
  }

  void playAllMoments() {
    for (final m in widget.moments.take(15)) {
      _highlightMoment(m.id);
    }
    _sceneKey.currentState?.triggerAllPerformances();
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
    final engine = ref.read(growthWorldEngineProvider);
    final islandStyle = widget.islandConfig ??
        MoodIslandRegistry.defaults().resolve(widget.moodId);
    return _stateCache.resolve(
      engine: engine,
      mood: CharacterMood.fromString(widget.moodId),
      moments: widget.moments,
      islandStyle: islandStyle,
      companionStyle: widget.companionStyle,
      companionGender: ref.read(profileProvider).valueOrNull?.gender,
      compact: widget.compact,
      highlightedEventId: _highlightedEventId,
    );
  }

  void _handleCharacterTap(
    String characterId,
    String? linkedEventId,
    String? nearbyBuildingId,
  ) {
    if (linkedEventId == null) return;
    DailyMomentModel? moment;
    for (final m in widget.moments) {
      if (m.id == linkedEventId) {
        moment = m;
        break;
      }
    }
    if (moment == null) return;
    widget.onCompanionTap?.call(moment, null);
    widget.onCharacterInteraction?.call(moment, nearbyBuildingId, characterId);
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
    final renderStyle = widget.companionStyle == 'chibi'
        ? 'mindscape'
        : widget.companionStyle;

    final scene = WorldSceneWidget(
      key: _sceneKey,
      worldState: worldState,
      compact: widget.compact,
      companionStyle: renderStyle,
      highlightedEventId: _highlightedEventId,
      enginePaused: widget.enginePaused,
      onCharacterTap: _handleCharacterTap,
      initialViewZoom: _viewZoom,
      initialViewRotation: _viewRotation,
    );

    return Transform.scale(
      scale: widget.scale,
      alignment: Alignment.topCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.compact ? 20 : 28),
        child: widget.interactive
            ? IslandGestureSurface(
                enabled: !widget.enginePaused,
                onTransform: _applyViewTransform,
                child: scene,
              )
            : scene,
      ),
    );
  }
}
