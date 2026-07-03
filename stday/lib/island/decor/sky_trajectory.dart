import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'decor_config.dart';

/// 天空装饰运动类型。
enum SkyMotionKind {
  /// 水平漂移 + 轻微上下摆动（云）。
  cloudDrift,

  /// 以锚点为中心的椭圆绕飞（鸟）。
  birdOrbit,

  /// 以锚点为中心的 8 字轨迹（蝶）。
  butterflyLoop,

  /// 锚点附近随机游走 + 明暗闪烁（萤火虫）。
  fireflyWander,

  /// 地面装饰：不参与天空轨迹（仅本地 grass_sway 等）。
  groundFixed,
}

/// 单个天空装饰的轨迹参数（归一化半径相对视口宽/高）。
class SkyTrajectoryDefinition {
  const SkyTrajectoryDefinition({
    required this.kind,
    this.orbitRadiusX = 0.14,
    this.orbitRadiusY = 0.06,
    this.orbitWobble = 0.12,
    this.orbitDurationSeconds = 18,
    this.driftSpeedMin = 10,
    this.driftSpeedMax = 18,
    this.verticalBobAmplitude = 0,
    this.loopRadiusPx = 48,
    this.loopDurationSeconds = 9,
    this.wanderRadiusPx = 36,
    this.orientAlongPath = true,
  });

  final SkyMotionKind kind;
  final double orbitRadiusX;
  final double orbitRadiusY;
  final double orbitWobble;
  final double orbitDurationSeconds;
  final double driftSpeedMin;
  final double driftSpeedMax;
  final double verticalBobAmplitude;
  final double loopRadiusPx;
  final double loopDurationSeconds;
  final double wanderRadiusPx;
  final bool orientAlongPath;
}

/// 主岛天空装饰轨迹目录：每只鸟/蝶/云/萤火虫独立参数。
class SkyTrajectoryCatalog {
  SkyTrajectoryCatalog._();

  static const _byId = <String, SkyTrajectoryDefinition>{
    'cloud_01': SkyTrajectoryDefinition(
      kind: SkyMotionKind.cloudDrift,
      driftSpeedMin: 8,
      driftSpeedMax: 13,
      verticalBobAmplitude: 3,
    ),
    'cloud_02': SkyTrajectoryDefinition(
      kind: SkyMotionKind.cloudDrift,
      driftSpeedMin: 11,
      driftSpeedMax: 17,
      verticalBobAmplitude: 4,
    ),
    'cloud_03': SkyTrajectoryDefinition(
      kind: SkyMotionKind.cloudDrift,
      driftSpeedMin: 6,
      driftSpeedMax: 11,
      verticalBobAmplitude: 2.5,
    ),
    'cloud_04': SkyTrajectoryDefinition(
      kind: SkyMotionKind.cloudDrift,
      driftSpeedMin: 9,
      driftSpeedMax: 14,
      verticalBobAmplitude: 3.5,
    ),
    'rainbow_cloud_01': SkyTrajectoryDefinition(
      kind: SkyMotionKind.cloudDrift,
      driftSpeedMin: 5,
      driftSpeedMax: 9,
      verticalBobAmplitude: 5,
    ),
    'bird_01': SkyTrajectoryDefinition(
      kind: SkyMotionKind.birdOrbit,
      orbitRadiusX: 0.20,
      orbitRadiusY: 0.075,
      orbitWobble: 0.14,
      orbitDurationSeconds: 20,
    ),
    'bird_02': SkyTrajectoryDefinition(
      kind: SkyMotionKind.birdOrbit,
      orbitRadiusX: 0.13,
      orbitRadiusY: 0.05,
      orbitWobble: 0.10,
      orbitDurationSeconds: 14,
    ),
    'bird_03': SkyTrajectoryDefinition(
      kind: SkyMotionKind.birdOrbit,
      orbitRadiusX: 0.15,
      orbitRadiusY: 0.055,
      orbitWobble: 0.11,
      orbitDurationSeconds: 16,
    ),
    'seagull_group_01': SkyTrajectoryDefinition(
      kind: SkyMotionKind.birdOrbit,
      orbitRadiusX: 0.26,
      orbitRadiusY: 0.09,
      orbitWobble: 0.08,
      orbitDurationSeconds: 24,
    ),
    'butterfly_01': SkyTrajectoryDefinition(
      kind: SkyMotionKind.butterflyLoop,
      loopRadiusPx: 52,
      loopDurationSeconds: 10,
    ),
    'firefly_01': SkyTrajectoryDefinition(
      kind: SkyMotionKind.fireflyWander,
      wanderRadiusPx: 42,
    ),
  };

  static bool hasDedicatedTrajectory(String decorId) => _byId.containsKey(decorId);

  static SkyTrajectoryDefinition resolve(DecorConfig config) {
    return _byId[config.id] ?? _fallbackFor(config);
  }

  static SkyTrajectoryDefinition _fallbackFor(DecorConfig config) {
    if (DecorConfigs.isMainIslandGroundDecor(config)) {
      return const SkyTrajectoryDefinition(kind: SkyMotionKind.groundFixed);
    }
    return switch (config.animationType) {
      'cloud_float' => const SkyTrajectoryDefinition(
          kind: SkyMotionKind.cloudDrift,
        ),
      'bird_fly' => const SkyTrajectoryDefinition(
          kind: SkyMotionKind.birdOrbit,
        ),
      'butterfly_fly' => const SkyTrajectoryDefinition(
          kind: SkyMotionKind.butterflyLoop,
        ),
      'firefly' => const SkyTrajectoryDefinition(
          kind: SkyMotionKind.fireflyWander,
        ),
      _ => const SkyTrajectoryDefinition(kind: SkyMotionKind.cloudDrift),
    };
  }
}

/// 由归一化锚点与视口尺寸生成可复用的 [Path]。
class SkyTrajectoryBuilder {
  SkyTrajectoryBuilder._();

  static Path buildEllipseOrbit({
    required Vector2 center,
    required Vector2 viewportSize,
    required SkyTrajectoryDefinition definition,
    double startAngle = 0,
    int segments = 64,
  }) {
    final rx = viewportSize.x * definition.orbitRadiusX;
    final ry = viewportSize.y * definition.orbitRadiusY;
    final wobble = definition.orbitWobble;
    final path = Path();
    for (var i = 0; i <= segments; i++) {
      final t = startAngle + (i / segments) * math.pi * 2;
      final x = center.x + math.cos(t) * rx;
      final y =
          center.y + math.sin(t) * ry + math.sin(t * 3) * ry * wobble;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path buildFigureEight({
    required Vector2 center,
    required double radius,
    int segments = 72,
  }) {
    final path = Path();
    for (var i = 0; i <= segments; i++) {
      final t = (i / segments) * math.pi * 2;
      final x = center.x + math.sin(t) * radius;
      final y = center.y + math.sin(t * 2) * radius * 0.55;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}
