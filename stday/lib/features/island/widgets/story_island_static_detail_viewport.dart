import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/story_island_models.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_renderer.dart';
import '../../../world/preview/story_island_world_builder.dart';

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
    final world = StoryIslandWorldBuilder.detail(base: base, island: island);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 390,
            constraints.maxHeight.isFinite ? constraints.maxHeight : 640,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _StoryIslandGroundPainter(worldState: world),
              ),
              for (final building in world.buildings)
                _StoryIslandBuildingImage(
                  building: building,
                  viewportSize: size,
                  onTap: onBuildingTap == null
                      ? null
                      : () => onBuildingTap!(building),
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
  static final _renderer = IslandRenderer(compact: false);

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
    required this.building,
    required this.viewportSize,
    this.onTap,
  });

  final BuildingSnapshot building;
  final Size viewportSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sprite = building.sprite;
    final anchor = Offset(
      building.anchor.dx * viewportSize.width,
      building.anchor.dy * viewportSize.height,
    );
    final scale = (viewportSize.width / 390).clamp(0.85, 1.15).toDouble();
    final base = math.max(
          building.size.dx * viewportSize.width,
          building.size.dy * viewportSize.height,
        ) *
        scale *
        1.05;
    final height = base.clamp(24.0, 92.0);
    final width = (height * 1.0).clamp(24.0, 120.0);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (width * dpr).round().clamp(48, 256);

    final rect = Rect.fromLTWH(
      anchor.dx - width / 2,
      anchor.dy - height,
      width,
      height,
    );

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

    return Positioned.fromRect(rect: rect, child: child);
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
