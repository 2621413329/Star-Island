import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_companion.dart';
import '../../../data/models/story_island_models.dart';
import '../../../design_system/user_companion_view.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../providers/app_providers.dart';
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
    final companion = ref.watch(userCompanionProvider);
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
      characters: sourceWorld.characters,
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
              CustomPaint(
                painter: _StoryIslandAtmospherePainter(
                  environment: world.environment,
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
                        for (final character in world.characters)
                          _StoryIslandCompanionImage(
                            character: character,
                            viewportSize: islandViewport,
                            companion: companion,
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

class _StoryIslandAtmospherePainter extends CustomPainter {
  const _StoryIslandAtmospherePainter({required this.environment});

  final MoodEnvironmentState environment;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyBottom = size.height * 0.45;
    final horizon = size.height * 0.38;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(environment.skyTop, Colors.white, 0.20)!,
            Color.lerp(environment.skyBottom, Colors.white, 0.12)!,
            Color.lerp(environment.sea, Colors.white, 0.36)!,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(rect),
    );

    _drawSunGlow(canvas, size);
    _drawClouds(canvas, size);
    _drawOcean(canvas, size, horizon);
    _drawIslandAmbientShadow(canvas, size, skyBottom);
  }

  void _drawSunGlow(Canvas canvas, Size size) {
    final sunCenter = Offset(
      size.width * environment.sunX.clamp(0.12, 0.88),
      size.height * environment.sunY.clamp(0.10, 0.34),
    );
    final radius = size.shortestSide * (0.16 + environment.sunIntensity * 0.08);
    final warmth = environment.lightWarmth.clamp(0.0, 1.0);
    canvas.drawCircle(
      sunCenter,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white
                .withValues(alpha: 0.38 + environment.sunIntensity * 0.18),
            Color.lerp(
                    const Color(0xFFFFF3C4), const Color(0xFFFFD4A3), warmth)!
                .withValues(alpha: 0.24),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: radius)),
    );
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.30);
    final shadowPaint = Paint()
      ..color = environment.skyBottom.withValues(alpha: 0.08);
    final cloudSeeds = [
      (Offset(size.width * 0.18, size.height * 0.18), size.width * 0.18),
      (Offset(size.width * 0.72, size.height * 0.16), size.width * 0.15),
      (Offset(size.width * 0.48, size.height * 0.28), size.width * 0.11),
    ];

    for (final entry in cloudSeeds) {
      final center = entry.$1;
      final width = entry.$2;
      _drawCloud(canvas, center + const Offset(0, 3), width, shadowPaint);
      _drawCloud(canvas, center, width, cloudPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: width * 0.30),
      paint,
    );
    canvas.drawCircle(
        center + Offset(-width * 0.22, -width * 0.05), width * 0.16, paint);
    canvas.drawCircle(
        center + Offset(width * 0.02, -width * 0.11), width * 0.20, paint);
    canvas.drawCircle(
        center + Offset(width * 0.25, -width * 0.03), width * 0.14, paint);
  }

  void _drawOcean(Canvas canvas, Size size, double horizon) {
    final oceanRect =
        Rect.fromLTWH(0, horizon, size.width, size.height - horizon);
    final seaDeep = Color.lerp(environment.sea, const Color(0xFF4AA8E8), 0.28)!;
    canvas.drawRect(
      oceanRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            environment.sea.withValues(alpha: 0.18),
            seaDeep.withValues(alpha: 0.30),
            const Color(0xFFEAF7FF).withValues(alpha: 0.24),
          ],
        ).createShader(oceanRect),
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1;
    for (var i = 0; i < 8; i++) {
      final y = horizon + size.height * (0.08 + i * 0.065);
      final path = Path()..moveTo(size.width * 0.06, y);
      for (var x = size.width * 0.06; x <= size.width * 0.94; x += 18) {
        final dy = math.sin(x * 0.025 + i * 0.8) * (1.5 + i * 0.15);
        path.lineTo(x, y + dy);
      }
      wavePaint.color = Colors.white.withValues(alpha: 0.11 - i * 0.008);
      canvas.drawPath(path, wavePaint);
    }
  }

  void _drawIslandAmbientShadow(Canvas canvas, Size size, double skyBottom) {
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final glowRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.92,
      height: size.height * 0.28,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.30),
            environment.sea.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );

    final mistRect =
        Rect.fromLTWH(0, skyBottom, size.width, size.height - skyBottom);
    canvas.drawRect(
      mistRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.00),
            Colors.white.withValues(alpha: 0.22),
          ],
        ).createShader(mistRect),
    );
  }

  @override
  bool shouldRepaint(covariant _StoryIslandAtmospherePainter oldDelegate) {
    return oldDelegate.environment.skyTop != environment.skyTop ||
        oldDelegate.environment.skyBottom != environment.skyBottom ||
        oldDelegate.environment.sea != environment.sea ||
        oldDelegate.environment.sunX != environment.sunX ||
        oldDelegate.environment.sunY != environment.sunY ||
        oldDelegate.environment.sunIntensity != environment.sunIntensity;
  }
}

class _StoryIslandCompanionImage extends StatelessWidget {
  const _StoryIslandCompanionImage({
    required this.character,
    required this.viewportSize,
    required this.companion,
  });

  final CharacterSnapshot character;
  final Size viewportSize;
  final UserCompanion companion;

  @override
  Widget build(BuildContext context) {
    final size = (viewportSize.width * 0.15 * character.scale)
        .clamp(42.0, 72.0)
        .toDouble();
    final left = character.normalizedPos.dx * viewportSize.width - size / 2;
    final top = character.normalizedPos.dy * viewportSize.height - size * 0.92;

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size * 1.15,
      child: UserCompanionView(
        companion: companion,
        size: size,
        showAura: false,
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
