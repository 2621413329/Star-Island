import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'decor_config.dart';
import 'decor_scale_resolver.dart';

/// 动态装饰组件：云朵漂浮、鸟类绕岛、蝴蝶飞舞、萤火虫发光。
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
        super(
          sprite: sprite,
          anchor: Anchor.bottomCenter,
          priority: config.category.layerPriority,
          position: Vector2(
            (position?.dx ?? config.x) * viewportSize.x,
            (position?.dy ?? config.y) * viewportSize.y,
          ),
        ) {
    opacity = config.opacity;
    angle = config.rotation;
    _applyBaseSize(sprite);
    _origin = position.clone();
  }

  final DecorConfig _config;
  final Vector2 _viewportSize;
  final int _userLevel;
  final DecorScaleResolver _scaleResolver;
  final math.Random _random;

  late final Vector2 _origin;
  double _cloudSpeed = 15;
  double _windPhase = 0;
  Vector2 _butterflyTarget = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applyAnimation();
  }

  void _applyBaseSize(Sprite sprite) {
    size = _scaleResolver.computeSize(
      config: _config,
      userLevel: _userLevel,
      spriteSrcSize: sprite.srcSize,
      viewportHeight: _viewportSize.y,
    );
  }

  void _applyAnimation() {
    switch (_config.animationType) {
      case 'cloud_float':
        _cloudSpeed = 10 + _random.nextDouble() * 10;
      case 'bird_fly':
        _startBirdFly();
      case 'butterfly_fly':
        _butterflyTarget = _randomOffset(40);
        _startButterflyFly();
      case 'firefly':
        _startFirefly();
      case 'grass_sway':
        break;
      default:
        break;
    }
  }

  void _startBirdFly() {
    final cx = _viewportSize.x * 0.5;
    final cy = _viewportSize.y * 0.48;
    final rx = _viewportSize.x * 0.22;
    final ry = _viewportSize.y * 0.08;
    final path = Path();
    const segments = 64;
    for (var i = 0; i <= segments; i++) {
      final t = i / segments * math.pi * 2;
      final x = cx + math.cos(t) * rx;
      final y = cy + math.sin(t) * ry + math.sin(t * 3) * ry * 0.15;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    add(
      MoveAlongPathEffect(
        path,
        EffectController(duration: 18, infinite: _config.loop),
        absolute: true,
        oriented: true,
      ),
    );
  }

  void _startButterflyFly() {
    add(
      MoveEffect.to(
        _origin + _butterflyTarget,
        EffectController(duration: 1.2 + _random.nextDouble()),
        onComplete: _scheduleNextButterflyMove,
      ),
    );
  }

  void _scheduleNextButterflyMove() {
    if (!isMounted || !_config.loop) return;
    final pauseDuration = 0.4 + _random.nextDouble() * 0.8;
    Future<void>.delayed(Duration(milliseconds: (pauseDuration * 1000).round()),
        () {
      if (!isMounted) return;
      _butterflyTarget = _randomOffset(55);
      angle = (_random.nextDouble() - 0.5) * 0.6;
      add(
        MoveEffect.to(
          _origin + _butterflyTarget,
          EffectController(duration: 0.8 + _random.nextDouble() * 1.2),
          onComplete: _scheduleNextButterflyMove,
        ),
      );
    });
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
    final target = _origin + _randomOffset(35);
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
    if (_config.animationType == 'cloud_float') {
      position.x += _cloudSpeed * dt;
      if (position.x > _viewportSize.x + size.x) {
        position = Vector2(-size.x, _config.y * _viewportSize.y);
      }
    } else if (_config.animationType == 'grass_sway') {
      _windPhase += dt;
      final phase = _config.id.hashCode * 0.013;
      final speed = 1.25 + (_config.id.hashCode.abs() % 5) * 0.08;
      final gust = math.sin(_windPhase * speed + phase);
      angle = _config.rotation + gust * 0.14;
      position.y = _origin.y + math.sin(_windPhase * 2.0 + phase) * 1.1;
    }
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
          priority: config.category.layerPriority,
          position: Vector2(
            (position?.dx ?? config.x) * viewportSize.x,
            (position?.dy ?? config.y) * viewportSize.y,
          ),
        ) {
    opacity = config.opacity;
    angle = config.rotation;
    final resolver = scaleResolver ?? const DecorScaleResolver();
    size = resolver.computeSize(
      config: config,
      userLevel: userLevel,
      spriteSrcSize: sprite.srcSize,
      viewportHeight: viewportSize.y,
    );
  }
}
