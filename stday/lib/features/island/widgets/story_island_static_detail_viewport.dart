import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_companion.dart';
import '../../../data/models/story_island_models.dart';
import '../../../design_system/user_companion_view.dart';
import '../../../island/building/building_depth_scale.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../providers/app_providers.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_placement.dart';
import '../../../world/island/island_renderer.dart';
import '../../../world/preview/story_island_world_builder.dart';
import '../../../core/constants/story_island_layout.dart';

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
    this.onCompanionTap,
  });

  final StoryIslandModel island;
  final void Function(BuildingSnapshot building)? onBuildingTap;
  final VoidCallback? onCompanionTap;

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
        radius: StoryIslandLayout.detailIslandRadius,
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

          // 与主岛详情 GrowthWorldViewport 一致：正视、无外层俯视 Transform。
          // （建筑 PNG 自身已是 45° 等距画风；再叠 rotateX 会把岛面压扁。）
          final islandViewport = Size(
            size.width * 0.94,
            (size.height * 0.64).clamp(320.0, 520.0).toDouble(),
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
                          onTap: onCompanionTap,
                        ),
                    ],
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
    final horizon = size.height * 0.38;

    // Keep the static detail page visually aligned with GrowthWorldViewport:
    // same sky gradient, sun glow, ocean horizon and shimmer treatment.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(environment.skyTop, Colors.white, 0.16)!,
            Color.lerp(environment.skyBottom, Colors.white, 0.08)!,
            Color.lerp(environment.skyBottom, environment.sea, 0.30)!,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(rect),
    );

    _drawSunGlow(canvas, size);
    _drawClouds(canvas, size);
    _drawDistantMountains(canvas, size, horizon);
    _drawOcean(canvas, size, horizon);
    _drawIslandAmbientShadow(canvas, size);
  }

  void _drawSunGlow(Canvas canvas, Size size) {
    final sunCenter = Offset(
      size.width * environment.sunX,
      size.height * environment.sunY,
    );
    final radius = size.width * (0.07 + environment.sunIntensity * 0.05);
    final warmth = environment.lightWarmth.clamp(0.0, 1.0);
    if (environment.sunIntensity >= 0.55) {
      final rayPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFD54F),
          const Color(0xFFFFB74D),
          warmth,
        )!
            .withValues(
                alpha: (environment.sunIntensity - 0.45).clamp(0.0, 0.45))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      if (environment.sunIntensity >= 0.85) {
        for (var i = 0; i < 14; i++) {
          final angle = i * math.pi * 2 / 14;
          final vector = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(
            sunCenter + vector * (radius * 0.86),
            sunCenter + vector * (radius * 1.18),
            rayPaint,
          );
        }
      }
      canvas.drawCircle(
        sunCenter,
        radius * 0.62,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.98),
              Color.lerp(
                const Color(0xFFFFD54F),
                const Color(0xFFFF8A65),
                warmth,
              )!
                  .withValues(alpha: 0.78),
              const Color(0xFFFFA726).withValues(alpha: 0.18),
            ],
          ).createShader(
              Rect.fromCircle(center: sunCenter, radius: radius * 0.75)),
      );
    }
    canvas.drawCircle(
      sunCenter,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(
              const Color(0xFFFFF8E1),
              const Color(0xFFFFE0B2),
              warmth,
            )!
                .withValues(alpha: 0.36 + environment.sunIntensity * 0.28),
            const Color(0xFFFFD54F)
                .withValues(alpha: environment.sunIntensity >= 0.9 ? 0.18 : 0),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(
            Rect.fromCircle(center: sunCenter, radius: radius * 1.65)),
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
    final seaDeep = Color.lerp(environment.sea, const Color(0xFF0277BD), 0.34)!;
    canvas.drawRect(
      oceanRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [environment.sea, seaDeep],
        ).createShader(oceanRect),
    );

    final waveAmp = 4 + environment.waveIntensity * 8;
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (var i = 0; i < 22; i++) {
      final y = size.height * (0.38 + (i % 9) * 0.06) + math.sin(i) * waveAmp;
      final x = (i * 47.0) % (size.width + 80) - 40;
      final len = 20 + (i % 4) * 16;
      wavePaint.color = Colors.white
          .withValues(alpha: 0.08 + 0.08 * environment.waveIntensity);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + len, y + math.sin(i) * 5),
        wavePaint,
      );
    }
  }

  void _drawDistantMountains(Canvas canvas, Size size, double horizon) {
    final baseY = horizon + size.height * 0.015;
    final backPaint = Paint()
      ..color = Color.lerp(
        environment.skyBottom,
        const Color(0xFF6F8C93),
        0.26,
      )!
          .withValues(alpha: 0.24);
    final frontPaint = Paint()
      ..color = Color.lerp(
        environment.skyBottom,
        const Color(0xFF4F7478),
        0.34,
      )!
          .withValues(alpha: 0.22);

    final back = Path()
      ..moveTo(-size.width * 0.08, baseY)
      ..quadraticBezierTo(
        size.width * 0.12,
        horizon - size.height * 0.11,
        size.width * 0.27,
        baseY,
      )
      ..quadraticBezierTo(
        size.width * 0.46,
        horizon - size.height * 0.18,
        size.width * 0.64,
        baseY,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        horizon - size.height * 0.10,
        size.width * 1.08,
        baseY,
      )
      ..lineTo(size.width * 1.08, horizon + size.height * 0.10)
      ..lineTo(-size.width * 0.08, horizon + size.height * 0.10)
      ..close();
    canvas.drawPath(back, backPaint);

    final front = Path()
      ..moveTo(-size.width * 0.02, baseY + 6)
      ..quadraticBezierTo(
        size.width * 0.19,
        horizon - size.height * 0.07,
        size.width * 0.38,
        baseY + 6,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        horizon - size.height * 0.12,
        size.width * 0.76,
        baseY + 5,
      )
      ..quadraticBezierTo(
        size.width * 0.93,
        horizon - size.height * 0.06,
        size.width * 1.04,
        baseY + 6,
      )
      ..lineTo(size.width * 1.04, horizon + size.height * 0.08)
      ..lineTo(-size.width * 0.02, horizon + size.height * 0.08)
      ..close();
    canvas.drawPath(front, frontPaint);
  }

  void _drawIslandAmbientShadow(Canvas canvas, Size size) {
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
    this.onTap,
  });

  final CharacterSnapshot character;
  final Size viewportSize;
  final UserCompanion companion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 副岛详情略小于主岛 cozy 比例，避免压过建筑；脚点对齐岛面站位。
    final size = (viewportSize.width * 0.112 * character.scale)
        .clamp(36.0, 84.0)
        .toDouble();
    final boxH = size * 1.15;
    final left = character.normalizedPos.dx * viewportSize.width - size / 2;
    // 脚底对齐 normalizedPos（岛面），与主岛详情正视相机一致。
    final top = character.normalizedPos.dy * viewportSize.height - boxH;

    Widget child = Align(
      alignment: Alignment.bottomCenter,
      child: UserCompanionView(
        companion: companion,
        size: size,
        showAura: false,
      ),
    );
    if (onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: child,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: boxH,
      child: child,
    );
  }
}

class _StoryIslandGroundPainter extends CustomPainter {
  _StoryIslandGroundPainter({required this.worldState});

  final WorldState worldState;
  // 与主岛详情同一套非 compact 岛形（正视，无外层俯视 Transform）。
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
      height = math.min(height, _maxHeightForFoot(building.anchor, viewportSize));
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

  /// 按脚点到岛缘上沿的距离限制立面高度，避免整栋楼画到岛外天空。
  static double _maxHeightForFoot(Offset foot, Size viewportSize) {
    final islandRadius = StoryIslandLayout.detailIslandRadius;
    final scale = IslandPlacement.effectiveIslandRadius(islandRadius);
    final clamped = IslandPlacement.clampToGrowthIsland(
      foot,
      inset: 0.72,
      islandRadius: islandRadius,
    );
    // 贴地椭圆很扁；俯视下可视岛面更高，用建筑表面纵向拉伸估算上沿。
    final visualRy = IslandPlacement.growthRadiusY *
        IslandPlacement.buildingSurfaceVerticalScale *
        scale;
    final islandTopY =
        (IslandPlacement.center.dy - visualRy * 0.92) * viewportSize.height;
    final footY = clamped.dy * viewportSize.height;
    final skyAllowance = viewportSize.height * 0.08;
    return (footY - islandTopY + skyAllowance).clamp(48.0, 156.0).toDouble();
  }

  static double _targetHeight(BuildingSnapshot building, Size viewportSize) {
    final viewportScale = (viewportSize.width / 390).clamp(0.86, 1.08);
    final normalized = math.max(building.size.dx, building.size.dy);
    final base = normalized * viewportSize.shortestSide * viewportScale;
    final ringScale = switch (building.type) {
      final t when t.contains('outer') => 0.90,
      final t when t.contains('middle') => 0.95,
      final t when t.contains('inner') => 1.0,
      final t when t.contains('center') => 1.06,
      _ => 0.94,
    };
    return (base *
            ringScale *
            BuildingDepthScale.forAnchorDy(building.anchor.dy) *
            StoryIslandLayout.detailBuildingVisualScale)
        .clamp(_minHeight(building), 156.0)
        .toDouble();
  }

  static double _minHeight(BuildingSnapshot building) {
    return building.type.contains('center') ? 36.0 : 28.0;
  }

  static Rect _candidateRect(
    BuildingSnapshot building,
    Size viewportSize,
    double height,
  ) {
    final islandRadius = StoryIslandLayout.detailIslandRadius;
    final foot = IslandPlacement.clampToGrowthIsland(
      building.anchor,
      inset: 0.72,
      islandRadius: islandRadius,
    );
    final anchor = Offset(
      foot.dx * viewportSize.width,
      foot.dy * viewportSize.height,
    );
    final width = (height * 0.92).clamp(48.0, 168.0).toDouble();
    final rect = Rect.fromLTWH(
      anchor.dx - width / 2,
      anchor.dy - height,
      width,
      height,
    );
    return _keepFootOnIsland(rect, foot, viewportSize, islandRadius);
  }

  /// 保持建筑脚点在岛面椭圆内；只水平微调，避免把整栋楼推进水面。
  static Rect _keepFootOnIsland(
    Rect rect,
    Offset normalizedFoot,
    Size viewportSize,
    double islandRadius,
  ) {
    if (IslandPlacement.isOnGrowthIsland(
      normalizedFoot,
      inset: 0.72,
      islandRadius: islandRadius,
    )) {
      // 立面可少量向上伸入天空，但左右不要越出岛缘过多。
      final halfW = rect.width / (2 * viewportSize.width);
      final left = IslandPlacement.clampToGrowthIsland(
        Offset(normalizedFoot.dx - halfW, normalizedFoot.dy),
        inset: 0.68,
        islandRadius: islandRadius,
      );
      final right = IslandPlacement.clampToGrowthIsland(
        Offset(normalizedFoot.dx + halfW, normalizedFoot.dy),
        inset: 0.68,
        islandRadius: islandRadius,
      );
      final centerX = (left.dx + right.dx) / 2;
      final dx = (centerX - normalizedFoot.dx) * viewportSize.width;
      return rect.shift(Offset(dx, 0));
    }
    final clamped = IslandPlacement.clampToGrowthIsland(
      normalizedFoot,
      inset: 0.72,
      islandRadius: islandRadius,
    );
    return rect.shift(
      Offset(
        (clamped.dx - normalizedFoot.dx) * viewportSize.width,
        (clamped.dy - normalizedFoot.dy) * viewportSize.height,
      ),
    );
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
