import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, RadialGradient;
import '../../island/decor/decor_config.dart';
import '../../island/decor/decor_placement_resolver.dart';
import 'growth_world_ground_painter.dart';
import 'lawn_obstacle_mask.dart';
import '../engine/world_state.dart';
import 'island_shape_profile.dart';

/// 3D 岛屿渲染：水面贴地岛、石质边缘、平地草坪与动态光影。
class IslandRenderer {
  IslandRenderer({required this.compact});

  final bool compact;
  double _time = 0;

  void update(double dt) => _time += dt;

  Path _buildTopPath(
    IslandShapeProfile profile,
    Size size,
    IslandState island, {
    double lift = 0,
  }) {
    final path = profile.buildTopPath(size, lift: lift, compact: compact);
    final radius = island.radius.clamp(0.6, 1.25);
    if (radius == 1) return path;
    final center =
        Offset(size.width * 0.5, size.height * (compact ? 0.56 : 0.54));
    final tx = center.dx * (1 - radius);
    final ty = center.dy * (1 - radius);
    return path.transform(Float64List.fromList([
      radius,
      0,
      0,
      0,
      0,
      radius,
      0,
      0,
      0,
      0,
      1,
      0,
      tx,
      ty,
      0,
      1,
    ]));
  }

  void render(
    Canvas canvas,
    Size size,
    IslandState island,
    MoodEnvironmentState env, {
    WorldState? worldState,
    Map<String, Offset>? decorPositions,
  }) {
    final profile = IslandShapeProfile.resolve(island.style);
    final isGrowth = _biomeKey(island) == 'growth_world';
    final tierBoost = isGrowth ? 1.0 : 1.0 + island.prosperityTier * 0.06;
    final thicknessScale = compact ? 1.18 : 1.0;
    final thickness = isGrowth
        ? size.height * 0.034 * thicknessScale
        : size.height *
            island.elevation *
            thicknessScale *
            tierBoost;

    if (isGrowth) {
      _drawSideWall(canvas, size, profile, island, thickness);
      _drawShadow(canvas, size, profile, island, thickness);
      _drawGrowthWorldWaterContact(canvas, size, profile, island, env);
    } else {
      _drawReflection(canvas, size, profile, island, env, thickness);
      _drawSideWall(canvas, size, profile, island, thickness);
      _drawShadow(canvas, size, profile, island, thickness);
    }
    _drawTopSurface(
      canvas,
      size,
      profile,
      island,
      env,
      worldState: worldState,
      decorPositions: decorPositions,
    );
    if (isGrowth) {
      _drawGrowthWorldStoneRim(canvas, size, profile, island);
    } else {
      _drawRimHighlight(canvas, size, profile, island);
    }
  }

  void _drawGrowthWorldWaterContact(
    Canvas canvas,
    Size size,
    IslandShapeProfile profile,
    IslandState island,
    MoodEnvironmentState env,
  ) {
    final path = _buildTopPath(profile, size, island);
    final bounds = path.getBounds();

    // 水面与岛缘的深色过渡带，强化岛水分界。
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(env.sea, const Color(0xFF2E6E85), 0.35)!
            .withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 7.5 : 9.0
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.6 : 2.0,
    );

    final metrics = path.computeMetrics().first;
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.16);
    for (var i = 0; i < 3; i++) {
      final phase = (_time * 0.16 + i * 0.34) % 1;
      final tan = metrics.getTangentForOffset(
        metrics.length * (0.18 + i * 0.27 + phase * 0.08),
      )!;
      final p = tan.position;
      final outward = Offset(-tan.vector.dy, tan.vector.dx);
      canvas.drawOval(
        Rect.fromCenter(
          center: p + outward * (10 + phase * 6),
          width: 18 + phase * 10,
          height: 7 + phase * 4,
        ),
        ripplePaint..color = Colors.white.withValues(alpha: (1 - phase) * 0.20),
      );
    }

    final contactRect = Rect.fromCenter(
      center: Offset(bounds.center.dx, bounds.bottom + 2),
      width: bounds.width * 0.88,
      height: bounds.height * 0.10,
    );
    canvas.drawOval(
      contactRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.10),
            env.sea.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(contactRect),
    );
  }

  void _drawReflection(Canvas canvas, Size size, IslandShapeProfile profile,
      IslandState island, MoodEnvironmentState env, double thickness) {
    canvas.save();
    canvas.translate(0, thickness * 0.6);
    canvas.scale(1, -0.38);
    final path = _buildTopPath(profile, size, island);
    final rect = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            island.style.grass.withValues(alpha: 0.22),
            env.sea.withValues(alpha: 0.05),
          ],
        ).createShader(rect),
    );
    canvas.restore();

    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.12);
    for (var i = 0; i < 3; i++) {
      final phase = (_time * 0.15 + i * 0.28) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center:
              Offset(size.width * 0.5, size.height * 0.63 + thickness * 0.3),
          width: size.width * (0.5 + phase * 0.28),
          height: size.height * (0.18 + phase * 0.1),
        ),
        ripplePaint..color = Colors.white.withValues(alpha: (1 - phase) * 0.18),
      );
    }
  }

  void _drawSideWall(Canvas canvas, Size size, IslandShapeProfile profile,
      IslandState island, double thickness) {
    final top = _buildTopPath(profile, size, island);

    final topMetrics = top.computeMetrics().first;
    const steps = 48;
    final center =
        Offset(size.width * 0.5, size.height * (compact ? 0.58 : 0.56));
    final serene = _biomeKey(island) == 'serene_lagoon' ||
        _biomeKey(island) == 'growth_world';
    final isGrowth = _biomeKey(island) == 'growth_world';
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isGrowth
            ? [
                const Color(0xFFECEFF1),
                const Color(0xFFB0BEC5),
                const Color(0xFF90A4AE),
              ]
            : serene
                ? [
                    Color.lerp(island.style.sand, Colors.white, 0.45)!,
                    Color.lerp(island.style.sand, island.style.sea, 0.22)!,
                    Color.lerp(
                        island.style.sea, const Color(0xFF7AA8B0), 0.38)!,
                  ]
                : [
                    Color.lerp(
                        island.style.sand, const Color(0xFFB0BEC5), 0.18)!,
                    Color.lerp(
                        island.style.sand, const Color(0xFF8D6E63), 0.45)!,
                    Color.lerp(
                        island.style.sand, const Color(0xFF3E2723), 0.58)!,
                  ],
      ).createShader(Offset.zero & size);

    final taper = isGrowth ? 0.72 : 0.58;

    for (var i = 0; i < steps; i++) {
      final t0 = i / steps;
      final t1 = (i + 1) / steps;
      final p0 =
          topMetrics.getTangentForOffset(topMetrics.length * t0)!.position;
      final p1 =
          topMetrics.getTangentForOffset(topMetrics.length * t1)!.position;
      final b0 = _taperPoint(p0, center, thickness, taper);
      final b1 = _taperPoint(p1, center, thickness, taper);
      final quad = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(b1.dx, b1.dy)
        ..lineTo(b0.dx, b0.dy)
        ..close();
      canvas.drawPath(quad, wallPaint);

      if (i % 7 == 0) {
        canvas.drawLine(
          Offset(p0.dx, p0.dy),
          Offset(b0.dx, b0.dy),
          Paint()
            ..color =
                (serene ? const Color(0xFF90A4AE) : const Color(0xFF5D4037))
                    .withValues(alpha: serene ? 0.18 : 0.25)
            ..strokeWidth = 1,
        );
      }
      if (i % 5 == 0) {
        final mid = Offset((p0.dx + b0.dx) * 0.5, (p0.dy + b0.dy) * 0.5);
        canvas.drawLine(
          Offset(mid.dx - 8, mid.dy),
          Offset(mid.dx + 8, mid.dy + 1.5),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.12)
            ..strokeWidth = 0.8,
        );
      }
    }

    if (isGrowth) {
      return;
    }

    final bottomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(island.style.sand, const Color(0xFF546E7A), 0.5)!
              .withValues(alpha: 0.72),
          const Color(0xFF263238).withValues(alpha: 0.66),
        ],
      ).createShader(Rect.fromCenter(
          center: center + Offset(0, thickness),
          width: size.width * 0.42,
          height: thickness * 2));
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, thickness * 0.98),
        width: size.width * (isGrowth ? 0.24 : (compact ? 0.26 : 0.32)),
        height: thickness * (isGrowth ? 0.42 : 0.34),
      ),
      bottomPaint,
    );
  }

  Offset _taperPoint(Offset p, Offset center, double thickness, double factor) {
    return Offset(
      center.dx + (p.dx - center.dx) * factor,
      center.dy + (p.dy - center.dy) * factor + thickness,
    );
  }

  void _drawShadow(Canvas canvas, Size size, IslandShapeProfile profile,
      IslandState island, double thickness) {
    final isGrowth = _biomeKey(island) == 'growth_world';
    final shadowLift = isGrowth ? thickness * 0.58 : thickness * 1.2;
    final shadow = _buildTopPath(profile, size, island, lift: shadowLift);
    canvas.drawPath(
      shadow,
      Paint()
        ..color =
            const Color(0xFF004D63).withValues(alpha: isGrowth ? 0.18 : 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isGrowth ? 12 : 18),
    );
    final deepShadow = _buildTopPath(profile, size, island,
        lift: isGrowth ? thickness * 0.92 : thickness * 1.65);
    canvas.drawPath(
      deepShadow,
      Paint()
        ..color =
            const Color(0xFF002B3A).withValues(alpha: isGrowth ? 0.10 : 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isGrowth ? 18 : 24),
    );
  }

  void _drawTopSurface(
    Canvas canvas,
    Size size,
    IslandShapeProfile profile,
    IslandState island,
    MoodEnvironmentState env, {
    WorldState? worldState,
    Map<String, Offset>? decorPositions,
  }) {
    final grass = _buildTopPath(profile, size, island);
    final isGrowth = _biomeKey(island) == 'growth_world';
    final grassInset = isGrowth
        ? profile.buildInsetPath(size, compact: compact, inset: 0.10)
        : grass;

    if (!isGrowth) {
      final lower =
          _buildTopPath(profile, size, island, lift: size.height * 0.012);
      final beach =
          _buildTopPath(profile, size, island, lift: size.height * 0.006);
      canvas.drawPath(
          lower,
          Paint()
            ..color =
                Color.lerp(island.style.sand, const Color(0xFF8D6E63), 0.22)!);
      canvas.drawPath(beach, Paint()..shader = _topSurfaceShader(island, size));
    } else {
      final bounds = grass.getBounds();
      canvas.drawPath(
        grass,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(
              -env.lightDirection.dx * 0.25,
              -env.lightDirection.dy * 0.25,
            ),
            radius: 1.0,
            colors: [
              Color.lerp(island.style.grass, const Color(0xFF4CAF50), 0.12)!,
              island.style.grass,
              Color.lerp(island.style.grass, const Color(0xFF2E7D32), 0.18)!,
            ],
            stops: const [0.0, 0.62, 1.0],
          ).createShader(bounds),
      );
    }

    canvas.save();
    canvas.clipPath(grassInset);
    if (isGrowth) {
      _drawGrowthWorldGround(
        canvas,
        size,
        island,
        env,
        grassInset: grassInset,
        worldState: worldState,
        decorPositions: decorPositions,
      );
    } else if (!_isRuggedMood(island)) {
      _drawMoodGround(canvas, size, island);
      _drawInnerBeach(canvas, size, island);
      _drawLivingZones(canvas, size, island);
      final grassRect = _grassRectFor(size, island);
      canvas.drawOval(
        grassRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(island.style.grass, Colors.white, 0.42)!,
              island.style.grass,
              Color.lerp(island.style.grass, const Color(0xFF2E7D32), 0.2)!,
            ],
          ).createShader(grassRect),
      );
      if (island.prosperityTier >= 2) _drawRaisedPlateaus(canvas, size, island);
    } else {
      _drawMoodGround(canvas, size, island);
    }
    if (!isGrowth) {
      _drawBiomeSignature(canvas, size, island);
    }
    if (!isGrowth) {
      _drawGrassSparkles(canvas, size, grass, island);
    }
    if (!isGrowth) {
      _drawMemoryContours(canvas, size, island);
    }
    canvas.restore();
  }

  void _drawGrowthWorldGround(
    Canvas canvas,
    Size size,
    IslandState island,
    MoodEnvironmentState env, {
    required Path grassInset,
    WorldState? worldState,
    Map<String, Offset>? decorPositions,
  }) {
    LawnObstacleMask? mask;
    if (worldState != null) {
      mask = LawnObstacleMask.fromWorldState(
        worldState,
        sceneHeight: size.height,
        decorPositionOverrides: decorPositions,
      );
    }
    GrowthWorldGroundPainter(
      compact: compact,
      time: _time,
      environment: env,
      pass: LawnRenderPass.background,
      obstacleMask: mask,
      clipPath: grassInset,
    ).paint(canvas, size, island);
  }

  void _drawGrowthWorldStoneRim(Canvas canvas, Size size,
      IslandShapeProfile profile, IslandState island) {
    final path = _buildTopPath(profile, size, island);
    const stoneOuter = Color(0xFF9E8E7E);
    const stoneInner = Color(0xFFBDB0A2);
    const stoneHighlight = Color(0xFFE8E0D6);

    canvas.drawPath(
      path,
      Paint()
        ..color = stoneOuter.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 8.5 : 10.0
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stoneInner.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 5.5 : 6.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stoneHighlight.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.6 : 2.0,
    );
  }

  void _drawProsperityBridge(Canvas canvas, Size size, IslandState island) {
    final paint = Paint()
      ..color = Color.lerp(island.style.sand, Colors.white, 0.35)!
          .withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 3.5 : 4.5
      ..strokeCap = StrokeCap.round;
    final bridge = Path()
      ..moveTo(size.width * 0.38, size.height * 0.54)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.46,
        size.width * 0.62,
        size.height * 0.54,
      );
    canvas.drawPath(bridge, paint);
    canvas.drawPath(
      bridge,
      Paint()
        ..color = island.style.accent
            .withValues(alpha: 0.15 + math.sin(_time * 1.1).abs() * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  Shader _topSurfaceShader(IslandState island, Size size) {
    final colors = switch (_biomeKey(island)) {
      'volcanic_ridge' => [
          const Color(0xFF5D4037),
          const Color(0xFF3E2723),
          const Color(0xFF211513),
        ],
      'storm_lighthouse' => [
          const Color(0xFFD4D0C7),
          const Color(0xFF8D9AA1),
          const Color(0xFF546E7A),
        ],
      'zen_pool' => [
          const Color(0xFFF2F0E8),
          const Color(0xFFD8D6CC),
          const Color(0xFFB0BEC5),
        ],
      'green_peak' => [
          const Color(0xFFE8F5E9),
          island.style.grass,
          const Color(0xFF4F8F56),
        ],
      'serene_lagoon' => [
          Color.lerp(island.style.sand, Colors.white, 0.52)!,
          island.style.sand,
          Color.lerp(island.style.sea, island.style.sand, 0.42)!,
        ],
      _ => [
          Color.lerp(island.style.sand, Colors.white, 0.38)!,
          island.style.sand,
          Color.lerp(island.style.sea, island.style.sand, 0.55)!,
        ],
    };
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(Offset.zero & size);
  }

  bool _isRuggedMood(IslandState island) =>
      _biomeKey(island) == 'volcanic_ridge' ||
      _biomeKey(island) == 'storm_lighthouse';

  Rect _grassRectFor(Size size, IslandState island) {
    if (_biomeKey(island) == 'green_peak') {
      return Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 0.58,
        height: size.height * 0.28,
      );
    }
    if (_biomeKey(island) == 'zen_pool') {
      return Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.59),
        width: size.width * 0.34,
        height: size.height * 0.16,
      );
    }
    if (_biomeKey(island) == 'serene_lagoon') {
      return Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.56),
        width: size.width * 0.52,
        height: size.height * 0.26,
      );
    }
    return Rect.fromLTWH(size.width * 0.2, size.height * 0.33, size.width * 0.6,
        size.height * 0.34);
  }

  void _drawMoodGround(Canvas canvas, Size size, IslandState island) {
    switch (_biomeKey(island)) {
      case 'serene_lagoon':
        _drawSereneLagoonGround(canvas, size, island);
      case 'dream_coast':
        _drawBeachBands(canvas, size, island);
      case 'green_peak':
        _drawForestMass(canvas, size, island);
      case 'zen_pool':
        _drawStoneGardenBase(canvas, size, island);
      case 'storm_lighthouse':
        _drawStormRockBase(canvas, size, island);
      case 'volcanic_ridge':
        _drawVolcanoBase(canvas, size, island);
      default:
        break;
    }
  }

  void _drawSereneLagoonGround(Canvas canvas, Size size, IslandState island) {
    final shore = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, 0.15),
        radius: 0.62,
        colors: [
          Color.lerp(island.style.sand, Colors.white, 0.62)!
              .withValues(alpha: 0.72),
          island.style.sand.withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.6),
        width: size.width * 0.28,
        height: size.height * 0.12,
      ),
      shore,
    );
    final pool = Rect.fromCenter(
      center: Offset(size.width * 0.56, size.height * 0.57),
      width: size.width * 0.22,
      height: size.height * 0.09,
    );
    canvas.drawOval(
      pool,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.58),
            island.style.sea.withValues(alpha: 0.32),
            Colors.transparent,
          ],
        ).createShader(pool),
    );
  }

  void _drawBeachBands(Canvas canvas, Size size, IslandState island) {
    final water = Paint()
      ..shader = RadialGradient(
        colors: [
          island.style.sea.withValues(alpha: 0.42),
          island.style.sea.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.36, size.height * 0.62),
        width: size.width * 0.32,
        height: size.height * 0.14,
      ),
      water,
    );
  }

  void _drawForestMass(Canvas canvas, Size size, IslandState island) {
    final forest = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.05, -0.2),
        radius: 0.72,
        colors: [
          Color.lerp(island.style.grass, Colors.white, 0.4)!
              .withValues(alpha: 0.7),
          island.style.grass.withValues(alpha: 0.66),
          const Color(0xFF2E5E36).withValues(alpha: 0.48),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 0.62,
        height: size.height * 0.28,
      ),
      forest,
    );
  }

  void _drawStoneGardenBase(Canvas canvas, Size size, IslandState island) {
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final stone = Paint()
      ..color = const Color(0xFFE8E5DA).withValues(alpha: 0.58);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.46,
        height: size.height * 0.2,
      ),
      stone,
    );
    final line = Paint()
      ..color = const Color(0xFF90A4AE).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width * (0.14 + i * 0.05),
          height: size.height * (0.055 + i * 0.018),
        ),
        line,
      );
    }
  }

  void _drawStormRockBase(Canvas canvas, Size size, IslandState island) {
    final rock = Paint()
      ..color = const Color(0xFF455A64).withValues(alpha: 0.52);
    for (var i = 0; i < 7; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * (0.28 + i * 0.075),
              size.height * (0.54 + (i % 3) * 0.035)),
          width: size.width * (0.14 + (i % 2) * 0.04),
          height: size.height * 0.065,
        ),
        rock,
      );
    }
  }

  void _drawVolcanoBase(Canvas canvas, Size size, IslandState island) {
    final cracks = Paint()
      ..color = island.style.accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final paths = [
      Path()
        ..moveTo(size.width * 0.34, size.height * 0.58)
        ..lineTo(size.width * 0.45, size.height * 0.54)
        ..lineTo(size.width * 0.53, size.height * 0.62),
      Path()
        ..moveTo(size.width * 0.54, size.height * 0.46)
        ..lineTo(size.width * 0.6, size.height * 0.55)
        ..lineTo(size.width * 0.72, size.height * 0.58),
      Path()
        ..moveTo(size.width * 0.4, size.height * 0.65)
        ..lineTo(size.width * 0.52, size.height * 0.6)
        ..lineTo(size.width * 0.63, size.height * 0.67),
    ];
    for (final p in paths) {
      canvas.drawPath(p, cracks);
    }
  }

  void _drawInnerBeach(Canvas canvas, Size size, IslandState island) {
    final shore = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.55, 0.12),
        radius: 0.55,
        colors: [
          Color.lerp(island.style.sand, Colors.white, 0.55)!
              .withValues(alpha: 0.78),
          island.style.sand.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.59),
        width: size.width * 0.25,
        height: size.height * 0.12,
      ),
      shore,
    );
  }

  void _drawBiomeSignature(Canvas canvas, Size size, IslandState island) {
    switch (_biomeKey(island)) {
      case 'dream_coast':
        _drawDreamCoast(canvas, size, island);
      case 'green_peak':
        _drawGreenPeak(canvas, size, island);
      case 'zen_pool':
        _drawZenPool(canvas, size, island);
      case 'storm_lighthouse':
        _drawStormLighthouse(canvas, size, island);
      case 'volcanic_ridge':
        _drawVolcanicRidge(canvas, size, island);
      case 'serene_lagoon':
        _drawSereneLagoon(canvas, size, island);
      default:
        break;
    }
  }

  void _drawSereneLagoon(Canvas canvas, Size size, IslandState island) {
    for (var i = 0; i < 4; i++) {
      final c = Offset(
        size.width * (0.34 + i * 0.08),
        size.height * (0.5 - (i % 2) * 0.02),
      );
      canvas.drawCircle(
        c + const Offset(0, -14),
        3.5,
        Paint()
          ..color = Color.lerp(island.style.flower, Colors.white, 0.35)!
              .withValues(alpha: 0.55),
      );
      canvas.drawLine(
        c,
        c + const Offset(0, -12),
        Paint()
          ..color = island.style.accent.withValues(alpha: 0.42)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  String _biomeKey(IslandState island) {
    if (island.style.biome == 'growth_world') return 'growth_world';
    return switch (island.style.biome) {
      'sunny' => 'dream_coast',
      'soft' => 'green_peak',
      'mist' => 'zen_pool',
      'drizzle' => 'storm_lighthouse',
      'windy' => 'volcanic_ridge',
      _ => island.style.biome,
    };
  }

  void _drawDreamCoast(Canvas canvas, Size size, IslandState island) {
    final lagoon = Rect.fromCenter(
      center: Offset(size.width * 0.34, size.height * 0.62),
      width: size.width * 0.2,
      height: size.height * 0.08,
    );
    canvas.drawOval(
      lagoon,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.62),
            island.style.sea.withValues(alpha: 0.34),
            Colors.transparent,
          ],
        ).createShader(lagoon),
    );
    final accent = Paint()
      ..color = island.style.accent.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final c = Offset(
          size.width * (0.28 + i * 0.06), size.height * (0.52 - i * 0.015));
      canvas.drawLine(c, c + Offset(0, -18 - i * 4), accent);
      canvas.drawCircle(
          c + Offset(0, -22 - i * 4),
          4.5,
          Paint()
            ..color = Color.lerp(island.style.flower, Colors.white, 0.25)!
                .withValues(alpha: 0.62));
    }
  }

  void _drawGreenPeak(Canvas canvas, Size size, IslandState island) {
    final peak = Path()
      ..moveTo(size.width * 0.28, size.height * 0.58)
      ..lineTo(size.width * 0.43, size.height * 0.38)
      ..lineTo(size.width * 0.57, size.height * 0.58)
      ..close();
    canvas.drawPath(
      peak,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.62),
            island.style.grass.withValues(alpha: 0.62),
            const Color(0xFF355E3B).withValues(alpha: 0.5),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      peak,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.3),
    );
    final waterfall = Path()
      ..moveTo(size.width * 0.43, size.height * 0.43)
      ..cubicTo(size.width * 0.44, size.height * 0.5, size.width * 0.39,
          size.height * 0.54, size.width * 0.41, size.height * 0.61);
    canvas.drawPath(
      waterfall,
      Paint()
        ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.74)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawZenPool(Canvas canvas, Size size, IslandState island) {
    final pool = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.57),
      width: size.width * 0.2,
      height: size.height * 0.09,
    );
    canvas.drawOval(
      pool,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.66),
            island.style.sea.withValues(alpha: 0.38),
            const Color(0xFF5C6BC0).withValues(alpha: 0.08),
          ],
        ).createShader(pool),
    );
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(pool.inflate(i * 8.0),
          ring..color = Colors.white.withValues(alpha: 0.28 - i * 0.05));
    }
    canvas.drawCircle(Offset(size.width * 0.37, size.height * 0.58), 9,
        Paint()..color = const Color(0xFF607D8B).withValues(alpha: 0.46));
  }

  void _drawStormLighthouse(Canvas canvas, Size size, IslandState island) {
    final rocks = Paint()
      ..color = const Color(0xFF455A64).withValues(alpha: 0.44);
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * (0.38 + i * 0.07),
              size.height * (0.58 - (i % 2) * 0.035)),
          width: size.width * 0.1,
          height: size.height * 0.045,
        ),
        rocks,
      );
    }
    final base = Offset(size.width * 0.7, size.height * 0.56);
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: base + const Offset(0, -18), width: 16, height: 42),
      const Radius.circular(4),
    );
    canvas.drawRRect(
        tower, Paint()..color = Colors.white.withValues(alpha: 0.72));
    canvas.drawRRect(
        tower,
        Paint()
          ..color = island.style.accent.withValues(alpha: 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1);
    canvas.drawCircle(base + const Offset(0, -43), 6,
        Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.72));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.46, size.height * 0.42),
          width: size.width * 0.24,
          height: size.height * 0.07),
      Paint()..color = const Color(0xFF607D8B).withValues(alpha: 0.22),
    );
  }

  void _drawVolcanicRidge(Canvas canvas, Size size, IslandState island) {
    final volcano = Path()
      ..moveTo(size.width * 0.34, size.height * 0.61)
      ..lineTo(size.width * 0.5, size.height * 0.36)
      ..lineTo(size.width * 0.68, size.height * 0.61)
      ..close();
    canvas.drawPath(
      volcano,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6D4C41).withValues(alpha: 0.88),
            const Color(0xFF3E2723).withValues(alpha: 0.78),
          ],
        ).createShader(Offset.zero & size),
    );
    final lava = Paint()
      ..color = island.style.accent.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.39),
        Offset(size.width * 0.46, size.height * 0.6), lava);
    canvas.drawLine(Offset(size.width * 0.52, size.height * 0.42),
        Offset(size.width * 0.6, size.height * 0.6), lava..strokeWidth = 2);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.37),
          width: 28,
          height: 10),
      Paint()..color = const Color(0xFFFF7043).withValues(alpha: 0.78),
    );
  }

  void _drawRaisedPlateaus(Canvas canvas, Size size, IslandState island) {
    final plateauPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(island.style.grass, Colors.white, 0.52)!
              .withValues(alpha: 0.62),
          island.style.grass.withValues(alpha: 0.5),
          Color.lerp(island.style.grass, const Color(0xFF455A64), 0.22)!
              .withValues(alpha: 0.48),
        ],
      ).createShader(Offset.zero & size);
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final left = Path()
      ..moveTo(size.width * 0.29, size.height * 0.53)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.46,
          size.width * 0.49, size.height * 0.51)
      ..quadraticBezierTo(size.width * 0.43, size.height * 0.59,
          size.width * 0.31, size.height * 0.6)
      ..close();
    final right = Path()
      ..moveTo(size.width * 0.53, size.height * 0.49)
      ..quadraticBezierTo(size.width * 0.66, size.height * 0.43,
          size.width * 0.74, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.69, size.height * 0.61,
          size.width * 0.55, size.height * 0.59)
      ..close();
    for (final p in [left, right]) {
      canvas.drawPath(p.shift(const Offset(0, 3)),
          Paint()..color = const Color(0xFF355461).withValues(alpha: 0.12));
      canvas.drawPath(p, plateauPaint);
      canvas.drawPath(p, stroke);
    }
  }

  void _drawLivingZones(Canvas canvas, Size size, IslandState island) {
    final lagoonRect = Rect.fromCenter(
      center: Offset(size.width * 0.58, size.height * 0.55),
      width: size.width * 0.18,
      height: size.height * 0.08,
    );
    canvas.drawOval(
      lagoonRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.5),
            island.style.sea.withValues(alpha: 0.24),
            island.style.accent.withValues(alpha: 0.08),
          ],
        ).createShader(lagoonRect),
    );

    final quietGarden = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.53),
        width: size.width * 0.18,
        height: size.height * 0.075,
      ),
      Radius.circular(size.height * 0.04),
    );
    canvas.drawRRect(
      quietGarden,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(island.style.grass, Colors.white, 0.5)!
                .withValues(alpha: 0.48),
            island.style.grass.withValues(alpha: 0.22),
          ],
        ).createShader(quietGarden.outerRect),
    );
  }

  void _drawBuiltPaths(Canvas canvas, Size size, IslandState island) {
    final pathPaint = Paint()
      ..color = Color.lerp(island.style.sand, Colors.white, 0.28)!
          .withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 4.0 : 5.5
      ..strokeCap = StrokeCap.round;
    final mainPath = Path()
      ..moveTo(size.width * 0.32, size.height * 0.62)
      ..cubicTo(size.width * 0.42, size.height * 0.55, size.width * 0.5,
          size.height * 0.6, size.width * 0.58, size.height * 0.53)
      ..cubicTo(size.width * 0.63, size.height * 0.49, size.width * 0.68,
          size.height * 0.5, size.width * 0.73, size.height * 0.47);
    canvas.drawPath(mainPath, pathPaint);
    canvas.drawPath(
      mainPath,
      Paint()
        ..color = island.style.accent
            .withValues(alpha: 0.18 + math.sin(_time * 1.3).abs() * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawMicroStructures(Canvas canvas, Size size, IslandState island) {
    final nodes = [
      Offset(size.width * 0.34, size.height * 0.55),
      Offset(size.width * 0.49, size.height * 0.58),
      Offset(size.width * 0.64, size.height * 0.51),
      Offset(size.width * 0.72, size.height * 0.58),
    ];
    for (var i = 0; i < nodes.length; i++) {
      final p = nodes[i];
      final w = (compact ? 14.0 : 18.0) + i % 2 * 4;
      final h = compact ? 8.0 : 10.0;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: w, height: h),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect.shift(const Offset(0, 3)),
        Paint()..color = const Color(0xFF2F4858).withValues(alpha: 0.12),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.62),
              island.style.accent.withValues(alpha: 0.26),
              const Color(0xFF5C6BC0).withValues(alpha: 0.16),
            ],
          ).createShader(rect.outerRect),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = Colors.white.withValues(alpha: 0.36),
      );
    }
  }

  void _drawGrassSparkles(
      Canvas canvas, Size size, Path clip, IslandState island) {
    for (var i = 0; i < 28; i++) {
      final angle = -math.pi * 0.86 + (math.pi * 1.72) * (i / 27);
      final ring = i.isEven ? 0.55 : 0.35;
      final p = Offset(
        size.width * 0.5 + math.cos(angle) * size.width * 0.22 * ring,
        size.height * 0.56 + math.sin(angle) * size.height * 0.14 * ring,
      );
      final breathe = 1 + math.sin(_time * 2 + i) * 0.25;
      canvas.drawCircle(
        p,
        (1.2 + (i % 3) * 0.5) * breathe,
        Paint()
          ..color =
              Color.lerp(island.style.flower, Colors.white, (i % 5) * 0.12)!
                  .withValues(alpha: 0.6),
      );
    }
  }

  void _drawMemoryContours(Canvas canvas, Size size, IslandState island) {
    final center = Offset(size.width * 0.5, size.height * 0.56);
    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final phase = math.sin(_time * 0.5 + i) * 0.04;
      final rect = Rect.fromCenter(
        center: center +
            Offset((i - 1.5) * size.width * 0.018,
                (i - 1.5) * size.height * 0.008),
        width: size.width * (0.18 + i * 0.085 + phase),
        height: size.height * (0.075 + i * 0.035),
      );
      contour.color = Color.lerp(island.style.accent, Colors.white, 0.45)!
          .withValues(alpha: 0.16 + i * 0.035);
      canvas.drawOval(rect, contour);
    }

    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.31, size.height * 0.59)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.48,
        size.width * 0.58,
        size.height * 0.66,
        size.width * 0.72,
        size.height * 0.53,
      );
    canvas.drawPath(path, pathPaint);
  }

  void _drawRimHighlight(Canvas canvas, Size size, IslandShapeProfile profile,
      IslandState island) {
    final grass = _buildTopPath(profile, size, island);
    canvas.drawPath(
      grass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }
}
