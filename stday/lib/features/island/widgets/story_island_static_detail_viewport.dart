import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/story_island_models.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_renderer.dart';
import '../../../world/preview/story_island_world_builder.dart';
import '../../../world/preview/world_preview_camera.dart';

/// Lightweight story-island detail renderer.
///
/// The full Flame scene is unnecessarily expensive for sub-island detail pages:
/// this keeps the island/building interaction while avoiding a continuously
/// ticking game loop on Android devices.
class StoryIslandStaticDetailViewport extends ConsumerWidget {
  const StoryIslandStaticDetailViewport({
    super.key,
    required this.island,
    this.onBuildingTap,
  });

  final StoryIslandModel island;
  final void Function(BuildingSnapshot building)? onBuildingTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(islandWorldProvider);
    final sourceWorld =
        StoryIslandWorldBuilder.detail(base: base, island: island);
    final world = WorldState(
      island: IslandState(
        shapeKey: sourceWorld.island.shapeKey,
        style: sourceWorld.island.style,
        elevation: sourceWorld.island.elevation,
        prosperityTier: sourceWorld.island.prosperityTier,
        radius: 0.82,
      ),
      characters: const [],
      buildings: sourceWorld.buildings,
      flora: sourceWorld.flora,
      environment: sourceWorld.environment,
      zones: sourceWorld.zones,
      decorations: sourceWorld.decorations,
      paths: sourceWorld.paths,
      effects: sourceWorld.effects,
      anchors: sourceWorld.anchors,
      companionGender: sourceWorld.companionGender,
      schemaVersion: sourceWorld.schemaVersion,
    );

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 390,
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : 640,
          );

          final islandViewport = Size(
            size.width * 0.94,
            (size.height * 0.58).clamp(300.0, 460.0).toDouble(),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEAF7FF),
                      Color(0xFFF7FBFF),
                    ],
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: islandViewport.width,
                  height: islandViewport.height,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: WorldPreviewCamera.islandTransform(),
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          painter: _StoryIslandGroundPainter(worldState: world),
                        ),
                        for (final placement
                            in _StoryIslandBuildingLayout.resolve(
                          world.buildings,
                          islandViewport,
                        ))
                          _StoryIslandBuildingImage(
                            placement: placement,
                            onTap: onBuildingTap == null
                                ? null
                                : () => onBuildingTap!(placement.building),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryIslandGroundPainter extends CustomPainter {
  _StoryIslandGroundPainter({required this.worldState});

  final WorldState worldState;
  static final _renderer = IslandRenderer(compact: true);

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.render(
      canvas,
      size,
      worldState.island,
      worldState.environment,
      worldState: worldState,
    );
  }

  @override
  bool shouldRepaint(covariant _StoryIslandGroundPainter oldDelegate) {
    return oldDelegate.worldState.island.radius != worldState.island.radius ||
        oldDelegate.worldState.buildings.length !=
            worldState.buildings.length ||
        oldDelegate.worldState.environment.sunY != worldState.environment.sunY;
  }
}

class _StoryIslandBuildingImage extends StatelessWidget {
  const _StoryIslandBuildingImage({
    required this.placement,
    this.onTap,
  });

  final _StoryIslandBuildingPlacement placement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final building = placement.building;
    final sprite = building.sprite;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (placement.rect.width * dpr).round().clamp(48, 256);

    Widget child = sprite == null
        ? _StoryIslandBuildingFallback(level: building.level)
        : Image.asset(
            'assets/images/$sprite',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.low,
            cacheWidth: cacheW,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) =>
                _StoryIslandBuildingFallback(level: building.level),
          );

    if (onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: child,
      );
    }

    return Positioned.fromRect(rect: placement.rect, child: child);
  }
}

class _StoryIslandBuildingPlacement {
  const _StoryIslandBuildingPlacement({
    required this.building,
    required this.rect,
  });

  final BuildingSnapshot building;
  final Rect rect;
}

class _StoryIslandBuildingLayout {
  const _StoryIslandBuildingLayout._();

  static List<_StoryIslandBuildingPlacement> resolve(
    List<BuildingSnapshot> buildings,
    Size viewportSize,
  ) {
    final sorted = [...buildings]
      ..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
    final placed = <_StoryIslandBuildingPlacement>[];
    final occupied = <Rect>[];

    for (final building in sorted) {
      var height = _targetHeight(building, viewportSize);
      Rect rect;
      while (true) {
        rect = _candidateRect(building, viewportSize, height);
        final collision = occupied.any(
          (other) => other.inflate(3).overlaps(rect.inflate(3)),
        );
        if (!collision || height <= _minHeight(building)) break;
        height *= 0.88;
      }

      placed.add(_StoryIslandBuildingPlacement(building: building, rect: rect));
      occupied.add(rect);
    }
    return placed;
  }

  static double _targetHeight(BuildingSnapshot building, Size viewportSize) {
    final viewportScale = (viewportSize.width / 390).clamp(0.86, 1.08);
    final normalized = math.max(building.size.dx, building.size.dy);
    final base = normalized * viewportSize.shortestSide * viewportScale;
    final ringScale = switch (building.type) {
      final t when t.contains('outer') => 0.78,
      final t when t.contains('middle') => 0.86,
      final t when t.contains('inner') => 0.92,
      final t when t.contains('center') => 1.0,
      _ => 0.84,
    };
    return (base * ringScale).clamp(_minHeight(building), 64.0).toDouble();
  }

  static double _minHeight(BuildingSnapshot building) {
    return building.type.contains('center') ? 24.0 : 18.0;
  }

  static Rect _candidateRect(
    BuildingSnapshot building,
    Size viewportSize,
    double height,
  ) {
    final anchor = Offset(
      building.anchor.dx * viewportSize.width,
      building.anchor.dy * viewportSize.height,
    );
    final width = (height * 0.92).clamp(22.0, 72.0).toDouble();
    final rect = Rect.fromLTWH(
      anchor.dx - width / 2,
      anchor.dy - height,
      width,
      height,
    );
    return _keepInsideIslandViewport(rect, viewportSize);
  }

  static Rect _keepInsideIslandViewport(Rect rect, Size viewportSize) {
    final safeLeft = viewportSize.width * 0.12;
    final safeRight = viewportSize.width * 0.88;
    final safeTop = viewportSize.height * 0.24;
    final safeBottom = viewportSize.height * 0.74;
    final dx = rect.left < safeLeft
        ? safeLeft - rect.left
        : rect.right > safeRight
            ? safeRight - rect.right
            : 0.0;
    final dy = rect.top < safeTop
        ? safeTop - rect.top
        : rect.bottom > safeBottom
            ? safeBottom - rect.bottom
            : 0.0;
    return rect.shift(Offset(dx, dy));
  }
}

class _StoryIslandBuildingFallback extends StatelessWidget {
  const _StoryIslandBuildingFallback({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B5B4D),
          ),
        ),
      ),
    );
  }
}
