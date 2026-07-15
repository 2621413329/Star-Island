import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../world/scene/scene_depth_priority.dart';
import 'decor_config.dart';
import 'decor_scale_resolver.dart';
import 'sky_trajectory.dart';

/// 动态装饰组件：云朵漂浮、鸟类绕飞、蝴蝶 8 字、萤火虫游走。
class AnimatedDecorComponent extends SpriteComponent {
  AnimatedDecorComponent({
    required DecorConfig config,
    required Sprite sprite,
    required Vector2 viewportSize,
    required int userLevel,
    DecorScaleResolver? scaleResolver,
    Offset? position,
  })  : _config = config,
        _viewportSize = viewportSize,
        _userLevel = userLevel,
        _scaleResolver = scaleResolver ?? const DecorScaleResolver(),
        _random = math.Random(config.id.hashCode),
        _trajectory = SkyTrajectoryCatalog.resolve(config),
        super(
          sprite: sprite,
          anchor: Anchor.bottomCenter,
          priority: DecorConfigs.isMainIslandSkyDecor(config)
              ? SceneDepthPriority.sky(position?.dy ?? config.y)
              : SceneDepthPriority.ground(position?.dy ?? config.y),
          position: Vector2(
            (position?.dx ?? config.x) * viewportSize.x,
            (position?.dy ?? config.y) * viewportSize.y,
          ),
        ) {
    opacity = config.opacity;
    angle = config.rotation;
    final resolved = Offset(position?.dx ?? config.x, position?.dy ?? config.y);
    _applyBaseSize(sprite, normalizedY: resolved.dy);
    _origin = Vector2(
      resolved.dx * viewportSize.x,
      resolved.dy * viewportSize.y,
    );
    _aerialTarget = _origin.clone();
    _aerialSpeed = _trajectory.kind == SkyMotionKind.butterflyLoop ? 24 : 40;
    _cloudSpeed = _trajectory.driftSpeedMin +
        _random.nextDouble() *
            (_trajectory.driftSpeedMax - _trajectory.driftSpeedMin);
    _cloudBobPhase = _random.nextDouble() * math.pi * 2;
  }

  final DecorConfig _config;
  final Vector2 _viewportSize;
  final int _userLevel;
  final DecorScaleResolver _scaleResolver;
  final math.Random _random;
  final SkyTrajectoryDefinition _trajectory;

  late final Vector2 _origin;
  late Vector2 _aerialTarget;
  late double _cloudSpeed;
  late double _cloudBobPhase;
  double _windPhase = 0;
  double _aerialSpeed = 36;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applyAnimation();
  }

  void _applyBaseSize(Sprite sprite, {required double normalizedY}) {
    size = _scaleResolver.computeSize(
      config: _config,
      userLevel: _userLevel,
      spriteSrcSize: sprite.srcSize,
      viewportHeight: _viewportSize.y,
      normalizedAnchorY:
          DecorConfigs.isMainIslandSkyDecor(_config) ? null : normalizedY,
    );
  }

  void _applyAnimation() {
    if (!DecorConfigs.isMainIslandSkyDecor(_config)) return;

    switch (_trajectory.kind) {
      case SkyMotionKind.birdOrbit:
      case SkyMotionKind.butterflyLoop:
        _pickAerialTarget();
        break;
      case SkyMotionKind.fireflyWander:
        _startFirefly();
        break;
      case SkyMotionKind.cloudDrift:
      case SkyMotionKind.groundFixed:
        break;
    }
  }

  void _pickAerialTarget() {
    if (_trajectory.kind == SkyMotionKind.butterflyLoop) {
      final radius =
          _trajectory.loopRadiusPx * (0.45 + _random.nextDouble() * 0.75);
      final angle = _random.nextDouble() * math.pi * 2;
      _aerialTarget = Vector2(
        _origin.x + math.cos(angle) * radius,
        _origin.y + math.sin(angle) * radius * 0.62,
      );
      _aerialSpeed = 18 + _random.nextDouble() * 16;
      return;
    }

    final radiusX = _viewportSize.x *
        _trajectory.orbitRadiusX *
        (0.35 + _random.nextDouble() * 0.8);
    final radiusY = _viewportSize.y *
        _trajectory.orbitRadiusY *
        (0.35 + _random.nextDouble() * 0.8);
    final angle = _random.nextDouble() * math.pi * 2;
    _aerialTarget = Vector2(
      _origin.x + math.cos(angle) * radiusX,
      _origin.y + math.sin(angle) * radiusY,
    );
    _aerialSpeed = 32 + _random.nextDouble() * 22;
  }

  void _updateAerialWander(double dt) {
    _windPhase += dt;
    var toTarget = _aerialTarget - position;
    if (toTarget.length < 8) {
      _pickAerialTarget();
      toTarget = _aerialTarget - position;
    }

    final drift = Vector2(
      math.sin(_windPhase * 1.9 + _config.id.hashCode * 0.01) *
          (_trajectory.kind == SkyMotionKind.butterflyLoop ? 10 : 16),
      math.cos(_windPhase * 2.4) *
          (_trajectory.kind == SkyMotionKind.butterflyLoop ? 8 : 12),
    );
    final step = (toTarget.normalized() * _aerialSpeed + drift) * dt;
    position += step;

    if (_trajectory.orientAlongPath && step.length > 0.001) {
      if (_trajectory.kind == SkyMotionKind.birdOrbit) {
        _applyBirdFlightPose(step);
      } else {
        angle = math.atan2(step.y, step.x) + math.pi / 2;
      }
    }
  }

  void _applyBirdFlightPose(Vector2 step) {
    final horizontalDirection = step.x >= 0 ? 1.0 : -1.0;
    scale.x = scale.x.abs() * horizontalDirection;

    final horizontalSpeed = math.max(step.x.abs(), 0.001);
    final pitch = math.atan2(step.y, horizontalSpeed).clamp(-0.30, 0.30);
    angle = _config.rotation + pitch.toDouble() * 0.45;
  }

  void _startFirefly() {
    add(
      OpacityEffect.to(
        0.35,
        EffectController(
          duration: 1.2,
          alternate: true,
          infinite: _config.loop,
        ),
      ),
    );
    _scheduleFireflyMove();
  }

  void _scheduleFireflyMove() {
    if (!isMounted) return;
    final target = _origin + _randomOffset(_trajectory.wanderRadiusPx);
    add(
      MoveEffect.to(
        target,
        EffectController(duration: 1.5 + _random.nextDouble() * 2),
        onComplete: _config.loop ? _scheduleFireflyMove : null,
      ),
    );
  }

  Vector2 _randomOffset(double radius) {
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = _random.nextDouble() * radius;
    return Vector2(math.cos(angle) * dist, math.sin(angle) * dist);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!DecorConfigs.isMainIslandSkyDecor(_config)) {
      if (_config.animationType == 'grass_sway') {
        _updateGrassSway(dt);
      }
      return;
    }
    switch (_trajectory.kind) {
      case SkyMotionKind.birdOrbit:
      case SkyMotionKind.butterflyLoop:
        _updateAerialWander(dt);
        return;
      case SkyMotionKind.cloudDrift:
        position.x += _cloudSpeed * dt;
        if (_trajectory.verticalBobAmplitude > 0) {
          _cloudBobPhase += dt * 0.9;
          position.y = _origin.y +
              math.sin(_cloudBobPhase) * _trajectory.verticalBobAmplitude;
        }
        if (position.x > _viewportSize.x + size.x) {
          position = Vector2(-size.x, _origin.y);
        }
        return;
      case SkyMotionKind.fireflyWander:
      case SkyMotionKind.groundFixed:
        return;
    }
  }

  void _updateGrassSway(double dt) {
    _windPhase += dt;
    final phase = _config.id.hashCode * 0.013;
    final speed = 1.25 + (_config.id.hashCode.abs() % 5) * 0.08;
    final gust = math.sin(_windPhase * speed + phase);
    final angleAmp = switch (_config.category) {
      DecorCategory.bush || DecorCategory.tree => 0.038,
      DecorCategory.flower => 0.042,
      _ => 0.045,
    };
    final bobAmp = switch (_config.category) {
      DecorCategory.bush || DecorCategory.tree => 0.5,
      DecorCategory.flower => 0.4,
      _ => 0.35,
    };
    angle = _config.rotation + gust * angleAmp;
    position.y = _origin.y + math.sin(_windPhase * 2.0 + phase) * bobAmp;
  }
}

/// 静态装饰组件。
class StaticDecorComponent extends SpriteComponent {
  StaticDecorComponent({
    required DecorConfig config,
    required Sprite sprite,
    required Vector2 viewportSize,
    required int userLevel,
    DecorScaleResolver? scaleResolver,
    Offset? position,
  }) : super(
          sprite: sprite,
          anchor: Anchor.bottomCenter,
          priority: DecorConfigs.isMainIslandSkyDecor(config)
              ? SceneDepthPriority.sky(position?.dy ?? config.y)
              : SceneDepthPriority.ground(position?.dy ?? config.y),
          position: Vector2(
            (position?.dx ?? config.x) * viewportSize.x,
            (position?.dy ?? config.y) * viewportSize.y,
          ),
        ) {
    opacity = config.opacity;
    angle = config.rotation;
    final resolver = scaleResolver ?? const DecorScaleResolver();
    final normalizedY = (position?.dy ?? config.y);
    size = resolver.computeSize(
      config: config,
      userLevel: userLevel,
      spriteSrcSize: sprite.srcSize,
      viewportHeight: viewportSize.y,
      normalizedAnchorY:
          DecorConfigs.isMainIslandSkyDecor(config) ? null : normalizedY,
    );
  }
}
