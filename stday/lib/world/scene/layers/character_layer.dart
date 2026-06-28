import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

import '../../../core/constants/catalog.dart';
import '../../../core/models/character_mood.dart';
import '../../../design_system/companion_painter.dart';
import '../../rendering/companion_asset_resolver.dart';
import '../../rendering/companion_picture_cache.dart';
import '../../behaviors/character_motion_behavior.dart';
import '../../behaviors/nearby_building_behavior.dart';
import '../../behaviors/protagonist_behavior.dart';
import '../../engine/world_state.dart';
import 'world_layer.dart';

double _islandCharSize(Vector2 sz, double scale, {bool cozyHero = false}) {
  final ratio = cozyHero ? 0.132 : 0.112;
  final maxSize = cozyHero ? 100.0 : 76.0;
  return (sz.x * ratio).clamp(34.0, maxSize).toDouble() * scale;
}

/// 角色层：用 Canvas 绘制情绪小人（与 CompanionPainter 同风格）+ Y-sort + 靠近建筑姿态切换。
/// 每个角色是一个独立 [_CharacterSprite]，添加到本层后由 Flame update/render 驱动。
class CharacterLayer extends WorldLayer with TapCallbacks {
  CharacterLayer({
    this.companionStyle = 'mindscape',
    this.onCharacterTap,
  }) : super(layerPriority: 600);

  final String companionStyle;

  /// 点击回调：(characterId, linkedEventId, nearbyBuildingId)
  final void Function(
    String characterId,
    String? linkedEventId,
    String? nearbyBuildingId,
  )? onCharacterTap;

  final _sprites = <_CharacterSprite>[];
  final CompanionAssetResolver _assetResolver = CompanionAssetResolver();
  bool _liteRender = false;
  bool _cozyHero = false;
  String? _companionGender;
  String? _worldMoodId;

  @override
  bool containsLocalPoint(Vector2 point) {
    if (onCharacterTap == null) return false;
    final sz = sceneSize;
    for (final s in _sprites.reversed) {
      if (s.hitTest(point, sz)) return true;
    }
    return false;
  }

  @override
  void onWorldStateChanged(WorldState worldState) {
    _companionGender = worldState.companionGender;
    _worldMoodId = worldState.island.style.moodId;
    _cozyHero = worldState.island.style.biome == 'growth_world' ||
        companionStyle == 'cozy';
    _rebuildSprites(worldState);
    unawaited(_assetResolver.preload(
      game,
      gender: _companionGender,
      expressions: worldState.characters.map((c) => c.expression),
      props: worldState.characters.expand((c) => [c.prop, ...c.extraProps]),
    ));
  }

  void _rebuildSprites(WorldState s) {
    _liteRender = s.characters.length >= 8;
    final existingById = {
      for (final sprite in _sprites) sprite.snapshot.id: sprite
    };
    final nextSprites = <_CharacterSprite>[];

    // 复用已有 sprite，保留正在播放的表演进度。
    // 否则底部卡片触发高亮导致 WorldState 更新时，会把岛上动画重置成普通 idle。
    for (final c in s.characters) {
      final nearbyBuilding = _nearestBuilding(c, s.buildings);
      final existing = existingById[c.id];
      if (existing != null) {
        existing.updateSnapshot(
            c, nearbyBuilding, _companionGender, _worldMoodId);
        nextSprites.add(existing);
      } else {
        nextSprites.add(_CharacterSprite(
          snapshot: c,
          nearbyBuilding: nearbyBuilding,
          companionStyle: companionStyle,
          companionGender: _companionGender,
          worldMoodId: _worldMoodId,
          cozyHero: _cozyHero,
        ));
      }
    }

    _sprites.clear();
    _sprites.addAll(nextSprites);
    // Y-sort：dy 大的（靠近屏幕底部）后绘制，遮挡靠前的。
    _sprites.sort((a, b) =>
        a.snapshot.normalizedPos.dy.compareTo(b.snapshot.normalizedPos.dy));
  }

  /// 找最近建筑，若距离 < 0.12（归一化）则认为"靠近"。
  BuildingSnapshot? _nearestBuilding(
      CharacterSnapshot c, List<BuildingSnapshot> buildings) {
    const threshold = 0.13;
    BuildingSnapshot? nearest;
    var minDist = double.infinity;
    for (final b in buildings) {
      final dx = c.normalizedPos.dx - b.anchor.dx;
      final dy = c.normalizedPos.dy - b.anchor.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < minDist && dist < threshold) {
        minDist = dist;
        nearest = b;
      }
    }
    return nearest;
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final s in _sprites) {
      s.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_sprites.isEmpty) return;
    final sz = sceneSize;
    for (final s in _sprites) {
      s.render(
        canvas,
        sz,
        liteRender: _liteRender,
        assetResolver: _assetResolver,
        lighting: state.environment,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final sz = sceneSize;
    final tapPos = event.localPosition;
    // 从最上层开始命中，避免重叠时点到后方角色。
    for (final s in _sprites.reversed) {
      if (s.hitTest(tapPos, sz)) {
        onCharacterTap?.call(
          s.snapshot.id,
          s.snapshot.linkedEventId,
          s.nearbyBuilding?.definitionId,
        );
        s.triggerPerformance();
        break;
      }
    }
  }

  void triggerPerformance(String? linkedEventId) {
    if (linkedEventId == null) return;
    for (final s in _sprites) {
      if (s.snapshot.linkedEventId == linkedEventId) {
        s.triggerPerformance();
      }
    }
  }

  void triggerAllPerformances() {
    for (final s in _sprites) {
      s.triggerPerformance();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 角色精灵：绑定 CompanionPainter 逻辑，持有运动状态。
// ─────────────────────────────────────────────────────────────────────────────

const _motionBehavior = CharacterMotionBehavior();
const _protagonistBehavior = ProtagonistBehavior();

class _CharacterSprite {
  _CharacterSprite({
    required this.snapshot,
    required this.companionStyle,
    this.companionGender,
    this.worldMoodId,
    this.nearbyBuilding,
    this.cozyHero = false,
  }) : _seed = _stablePhase(snapshot.id);

  CharacterSnapshot snapshot;
  final String companionStyle;
  String? companionGender;
  String? worldMoodId;
  BuildingSnapshot? nearbyBuilding;
  final bool cozyHero;

  final double _seed;
  double _time = 0;
  double _perfLevel = 0;
  bool _performing = false;

  static double _stablePhase(String id) {
    final h = id.hashCode & 0x7fffffff;
    return h / 0x7fffffff * math.pi * 2;
  }

  void updateSnapshot(
    CharacterSnapshot nextSnapshot,
    BuildingSnapshot? nextNearbyBuilding,
    String? gender,
    String? moodId,
  ) {
    snapshot = nextSnapshot;
    nearbyBuilding = nextNearbyBuilding;
    companionGender = gender;
    worldMoodId = moodId;
  }

  void update(double dt) {
    _time += dt;
    if (_performing) {
      _perfLevel = (_perfLevel + dt / 1.25).clamp(0.0, 1.0);
      if (_perfLevel >= 1.0) {
        _performing = false;
        _perfLevel = 0;
      }
    }
  }

  void triggerPerformance() {
    _performing = true;
    _perfLevel = 0.01;
  }

  NearbyBuildingRenderState _effectiveRenderState() {
    // 点击表演始终使用该记录最后生成的动画/道具/表情。
    // 靠近建筑只保留提示点，不覆盖日常本身生成的表演。
    return NearbyBuildingRenderState(
      expression: snapshot.expression,
      prop: snapshot.prop,
      animationKey: snapshot.animationKey,
      showHint: nearbyBuilding != null,
    );
  }

  bool get _usesProtagonistBehavior => cozyHero && snapshot.id == 'protagonist';

  _MotionFrame _motionFrame() {
    if (_usesProtagonistBehavior) {
      final s = _protagonistBehavior.sample(_time);
      return _MotionFrame(
        wander: Offset.zero,
        bob: s.bob,
        facingRotation: s.facingYaw * 0.15,
        absolutePos: s.normalizedPos,
        bobIsNormalized: true,
      );
    }
    final frame = _motionBehavior.sample(
      motion: snapshot.motion,
      time: _time,
      seed: _seed,
    );
    return _MotionFrame(
      wander: frame.wander,
      bob: frame.bob,
      facingRotation: 0,
    );
  }

  bool hitTest(Vector2 tapPos, Vector2 sz) {
    final motion = _motionFrame();
    final pos = motion.absolutePos ?? snapshot.normalizedPos;
    final groundX = pos.dx * sz.x + motion.wander.dx;
    final groundY = pos.dy * sz.y;
    final bodyBob =
        motion.bobIsNormalized ? motion.bob * sz.y : motion.bob * 0.35;
    final charSize = _islandCharSize(sz, snapshot.scale, cozyHero: cozyHero);
    final charHeight = charSize * 1.15;
    final rect = Rect.fromCenter(
      center: Offset(groundX, groundY - charHeight * 0.38 + bodyBob),
      width: charSize * 1.45,
      height: charHeight * 1.45,
    );
    return rect.contains(Offset(tapPos.x, tapPos.y));
  }

  void render(
    Canvas canvas,
    Vector2 sz, {
    required bool liteRender,
    required CompanionAssetResolver assetResolver,
    required MoodEnvironmentState lighting,
  }) {
    final motion = _motionFrame();
    final pos = motion.absolutePos ?? snapshot.normalizedPos;
    final renderState = _effectiveRenderState();
    final performance = _performanceTransform(renderState.animationKey);

    final groundX = pos.dx * sz.x + motion.wander.dx;
    final groundY = pos.dy * sz.y;
    final bodyBob =
        motion.bobIsNormalized ? motion.bob * sz.y : motion.bob * 0.35;

    final charSize = _islandCharSize(sz, snapshot.scale, cozyHero: cozyHero);
    final charHeight = charSize * 1.15;
    final rect = Rect.fromCenter(
      center: Offset(groundX, groundY - charHeight * 0.38 + bodyBob),
      width: charSize,
      height: charHeight,
    );

    final tint = _parseTint(snapshot.tintHex) ?? _defaultTint(snapshot.mood);
    final glow = Color.lerp(tint, const Color(0xFFFFFFFF), 0.35) ??
        const Color(0xFFFFFFFF);

    if (cozyHero) {
      final visibleProps = _visibleCompanionProps(
        renderState.prop,
        snapshot.extraProps,
      );
      final baseAsset = assetResolver.cachedBase(
        gender: companionGender,
        expression: renderState.expression,
      );
      if (baseAsset.hasImage) {
        _drawImageCompanion(
          canvas,
          baseAsset: baseAsset,
          props: visibleProps,
          assetResolver: assetResolver,
          groundX: groundX,
          groundY: groundY,
          charSize: charSize,
          bodyBob: bodyBob,
          dx: performance.dx,
          dy: performance.dy,
          rotation: performance.rotation + motion.facingRotation,
          scale: performance.scale,
          lighting: lighting,
        );
        if (renderState.showHint) {
          _drawInteractionHint(
              canvas, Offset(groundX, groundY - charSize * 1.1), tint);
        }
        return;
      }
      if (renderState.showHint) {
        _drawInteractionHint(
            canvas, Offset(groundX, groundY - charSize * 1.1), tint);
      }
      return;
    }

    // 柔和投影，让角色和地面有空间关系。
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(groundX, groundY + charSize * 0.08),
        width: charSize * (0.62 + snapshot.scale * 0.08),
        height: charSize * 0.18,
      ),
      Paint()..color = const Color(0xFF24485A).withValues(alpha: 0.16),
    );

    if (!liteRender) {
      canvas.drawCircle(
        Offset(groundX, groundY + charSize * 0.02),
        charSize * 0.34,
        Paint()..color = tint.withValues(alpha: 0.06),
      );
    }

    if (_performing && !liteRender) {
      final pulse = math.sin(_perfLevel * math.pi);
      canvas.drawCircle(
        Offset(groundX, groundY - charSize * 0.42),
        charSize * (0.44 + pulse * 0.18),
        Paint()..color = glow.withValues(alpha: 0.14 * pulse),
      );
    }

    final Picture picture;
    final useCache = !_performing && _perfLevel <= 0.001;
    if (useCache) {
      final w = rect.width.round();
      final h = rect.height.round();
      final key = CompanionPictureCache.key(
        style: companionStyle,
        expression: renderState.expression,
        prop: renderState.prop,
        tintArgb: tint.toARGB32(),
        widthPx: w,
        heightPx: h,
        gender: companionGender,
      );
      picture = CompanionPictureCache.get(key) ??
          CompanionPictureCache.rasterize(
            width: rect.width,
            height: rect.height,
            painter: (canvas, size) => CompanionPainter(
              style: companionStyle,
              expression: renderState.expression,
              prop: renderState.prop,
              tint: tint,
              glow: glow,
              performanceLevel: 0,
              gender: companionGender,
            ).paint(canvas, size),
          );
      if (CompanionPictureCache.get(key) == null) {
        CompanionPictureCache.put(key, picture);
      }
    } else {
      final recorder = PictureRecorder();
      CompanionPainter(
        style: companionStyle,
        expression: renderState.expression,
        prop: renderState.prop,
        tint: tint,
        glow: glow,
        performanceLevel: _perfLevel,
        gender: companionGender,
      ).paint(Canvas(recorder), Size(rect.width, rect.height));
      picture = recorder.endRecording();
    }

    canvas.save();
    canvas.translate(
        rect.center.dx + performance.dx, rect.center.dy + performance.dy);
    canvas.rotate(performance.rotation);
    canvas.scale(performance.scale, performance.scale);
    canvas.translate(-rect.width * 0.5, -rect.height * 0.5);
    canvas.drawPicture(picture);
    canvas.restore();

    if (renderState.showHint) {
      _drawInteractionHint(canvas, Offset(groundX, rect.top - 10), tint);
    }
  }

  void _drawImageCompanion(
    Canvas canvas, {
    required CompanionImageAsset baseAsset,
    required List<String> props,
    required CompanionAssetResolver assetResolver,
    required double groundX,
    required double groundY,
    required double charSize,
    required double bodyBob,
    required double dx,
    required double dy,
    required double rotation,
    required double scale,
    required MoodEnvironmentState lighting,
  }) {
    final baseImage = baseAsset.image;
    final baseSrc = baseAsset.region;
    if (baseImage == null || baseSrc == null) return;

    final charHeight = charSize * 1.15;
    final imageAspect = baseSrc.width / baseSrc.height;
    final drawHeight = charHeight;
    final drawWidth = drawHeight * imageAspect;
    final center = Offset(
      groundX + dx,
      groundY - drawHeight * 0.50 + bodyBob + dy,
    );
    final baseDst = Rect.fromCenter(
      center: Offset.zero,
      width: drawWidth,
      height: drawHeight,
    );

    const multiPropSlots = [
      Offset(-0.35, -0.05),
      Offset(0.34, 0.02),
      Offset(0.18, -0.34),
      Offset(-0.16, 0.34),
    ];
    const singlePropSlot = Offset(0.26, -0.42);
    final slots = props.length == 1 ? [singlePropSlot] : multiPropSlots;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scale, scale);
    final shadowPaint = Paint()
      ..color = const Color(0xFF2B4B5A).withValues(alpha: lighting.shadowAlpha);
    if (_performing) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            charSize * lighting.shadowDx * 0.42,
            charSize * 0.55,
          ),
          width: charSize * 0.48,
          height: charSize * 0.11,
        ),
        shadowPaint,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            charSize * lighting.shadowDx * 0.42,
            charSize * 0.55 + lighting.shadowDy * charSize * 0.12,
          ),
          width: charSize * (0.50 + lighting.shadowStretch.abs() * 0.08),
          height: charSize * (0.11 + lighting.shadowStretch.abs() * 0.03),
        ),
        shadowPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawImageRect(baseImage, baseSrc, baseDst, Paint());

    for (var i = 0; i < props.length && i < slots.length; i++) {
      final propAsset = assetResolver.cachedProp(props[i]);
      final propImage = propAsset.image;
      final propSrc = propAsset.region;
      if (propImage == null || propSrc == null) continue;
      final slot = slots[i];
      final propSize = charSize * 0.30;
      final propDst = Rect.fromCenter(
        center: Offset(
          slot.dx * drawWidth,
          slot.dy * drawHeight,
        ),
        width: propSize,
        height: propSize,
      );
      canvas.drawImageRect(propImage, propSrc, propDst, Paint());
    }
    canvas.restore();
  }

  static List<String> _visibleCompanionProps(
    String prop,
    List<String> extraProps,
  ) {
    final seen = <String>{};
    return [
      for (final item in [prop, ...extraProps])
        if (item != 'none' && seen.add(item)) item,
    ];
  }

  _PerformanceTransform _performanceTransform(String animationKey) {
    if (!_performing || _perfLevel <= 0) return const _PerformanceTransform();

    final p = Curves.easeInOutCubic.transform(_perfLevel.clamp(0.0, 1.0));
    var dx = 0.0;
    var dy = 0.0;
    var rotation = 0.0;
    var scale = 1.0 + 0.1 * math.sin(p * math.pi);
    dy = -8 * math.sin(p * math.pi);

    switch (animationKey) {
      case 'celebrate':
      case 'cheer':
        scale = 1 + 0.28 * math.sin(p * math.pi * 2);
        dy = -14 * math.sin(p * math.pi);
      case 'wave':
        dx = 14 * math.sin(p * math.pi * 3);
        rotation = 0.12 * math.sin(p * math.pi * 2);
      case 'shake':
        dx = 16 * math.sin(p * math.pi * 8);
      case 'swing':
        dx = 10 * math.sin(p * math.pi * 2);
        rotation = -0.34 * math.sin(p * math.pi * 1.4);
        scale = 1 + 0.08 * math.sin(p * math.pi);
      case 'lose_slump':
        dy = 14 * math.sin(p * math.pi);
        rotation = 0.14;
        scale = 0.9 + 0.04 * math.cos(p * math.pi);
      case 'hug':
        scale = 1 + 0.1 * math.sin(p * math.pi);
      case 'comfort':
        scale = 1 + 0.08 * math.sin(p * math.pi);
        dx = 6 * math.sin(p * math.pi);
        dy = -3 * math.sin(p * math.pi * 2);
      case 'reach_out':
        dx = 12 * math.sin(p * math.pi);
        rotation = -0.08 * math.sin(p * math.pi);
      case 'think':
        rotation = -0.12 * math.sin(p * math.pi);
        dy = 4 * math.sin(p * math.pi);
      case 'sit':
        dy = 6 * math.sin(p * math.pi);
      case 'slump_read':
        rotation = 0.08 * math.sin(p * math.pi);
        dy = 8 + 6 * math.sin(p * math.pi);
        scale = 0.96 + 0.02 * math.sin(p * math.pi);
      case 'look_down':
        dy = 10 * math.sin(p * math.pi);
        rotation = 0.06;
        scale = 0.94 + 0.03 * (1 - p);
      default:
        dx = 10 * math.sin(p * math.pi * 2);
        scale = 1 + 0.12 * math.sin(p * math.pi);
    }

    return _PerformanceTransform(
      dx: dx,
      dy: dy,
      rotation: rotation,
      scale: scale,
    );
  }

  void _drawInteractionHint(Canvas canvas, Offset center, Color tint) {
    final t = math.sin(_time * 3.0 + _seed).abs();
    final r = 6.0 + t * 2.5;
    canvas.drawCircle(
      center,
      r + 6,
      Paint()
        ..color = tint.withValues(alpha: 0.12 + t * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = tint.withValues(alpha: 0.55 + t * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  static Color _defaultTint(CharacterMood mood) => switch (mood) {
        CharacterMood.happy => moodColor('happy'),
        CharacterMood.anxious => moodColor('sad'),
        CharacterMood.angry => moodColor('angry'),
        CharacterMood.proud => moodColor('happy'),
        CharacterMood.calm => moodColor('calm'),
      };

  static Color? _parseTint(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

class _MotionFrame {
  const _MotionFrame({
    required this.wander,
    required this.bob,
    this.facingRotation = 0,
    this.absolutePos,
    this.bobIsNormalized = false,
  });

  final Offset wander;
  final double bob;
  final double facingRotation;
  final Offset? absolutePos;
  final bool bobIsNormalized;
}

class _PerformanceTransform {
  const _PerformanceTransform({
    this.dx = 0,
    this.dy = 0,
    this.rotation = 0,
    this.scale = 1,
  });

  final double dx;
  final double dy;
  final double rotation;
  final double scale;
}
