import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show Colors, LinearGradient, RadialGradient;

import '../../../core/models/mood_island_config.dart';
import '../../../island/building/building_factory.dart';
import '../../../island/config/building_config.dart';
import '../../../island/config/growth_island_config_models.dart';
import '../../../island/config/growth_island_configs.dart';
import '../../engine/world_state.dart';
import 'world_layer.dart';

class BuildingLayer extends WorldLayer {
  BuildingLayer() : super(layerPriority: -20);

  final BuildingFactory _buildingFactory = BuildingFactory();
  double _time = 0;

  @override
  void onWorldStateChanged(WorldState worldState) {
    unawaited(_buildingFactory.preload(game, worldState.buildings));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    final style = state.island.style;
    final buildings = [...state.buildings]
      ..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
    for (final b in buildings) {
      final configured = GrowthIslandConfigs.buildingById(b.definitionId);
      if (configured != null) {
        _drawConfiguredSnapshot(canvas, b, style, s.x);
        continue;
      }
      final anchor = Offset(b.anchor.dx * s.x, b.anchor.dy * s.y);
      _drawProp(
        canvas,
        anchor: anchor,
        propId: b.definitionId,
        level: b.level,
        style: style,
        sceneW: s.x,
        unlockFx: b.playUnlockFx,
      );
    }
  }

  void _drawConfiguredSnapshot(
    Canvas canvas,
    BuildingSnapshot snapshot,
    MoodIslandConfig style,
    double sceneW,
  ) {
    final scale = (sceneW / 390).clamp(0.85, 1.15).toDouble();
    final anchor = Offset(
      snapshot.anchor.dx * sceneSize.x,
      snapshot.anchor.dy * sceneSize.y,
    );
    final component = _buildingFactory.create(snapshot);
    component?.render(
      canvas,
      base: anchor,
      scale: scale,
      style: style,
    );
    if (snapshot.playUnlockFx) {
      canvas.drawCircle(
        anchor,
        26 * scale,
        Paint()
          ..color =
              style.accent.withValues(alpha: 0.18 + 0.08 * math.sin(_time * 4)),
      );
    }
  }

  void _drawProp(
    Canvas canvas, {
    required Offset anchor,
    required String propId,
    required int level,
    required MoodIslandConfig style,
    required double sceneW,
    required bool unlockFx,
  }) {
    final scale = (sceneW / 390).clamp(0.85, 1.15);
    final def = IslandBuildingConfig.find(propId);
    final depthScale = def?.depthScale ?? 1.0;
    final layerScale = scale * depthScale;
    final base = anchor;
    final accent = style.accent;
    final grass = style.grass;
    final sea = style.sea;
    final flower = style.flower;
    final sand = style.sand;

    final configured = GrowthIslandConfigs.buildingById(propId);
    if (configured != null) {
      _drawConfiguredBuilding(
        canvas,
        base,
        layerScale,
        configured,
        accent,
        sea,
        grass,
        sand,
      );
      if (unlockFx) {
        canvas.drawCircle(
          anchor,
          26 * layerScale,
          Paint()
            ..color =
                accent.withValues(alpha: 0.18 + 0.08 * math.sin(_time * 4)),
        );
      }
      return;
    }

    switch (propId) {
      case 'prop_sun_beach':
        _drawSunBeach(canvas, base, scale, accent, sea, flower);
      case 'prop_green_rest':
        _drawGreenRest(canvas, base, scale, grass, accent);
      case 'prop_zen_stones':
        _drawZenStones(canvas, base, scale, sand, accent, sea);
      case 'prop_warm_lamp':
        _drawWarmLamp(canvas, base, scale, accent, sea);
      case 'prop_lava_vent':
        _drawLavaVent(canvas, base, scale, accent, sand);
      case 'growth_tree':
        _drawGrowthTree(canvas, base, scale, level, accent);
      case 'growth_lighthouse':
        _drawGrowthLighthouse(canvas, base, layerScale, accent, sea);
      case 'growth_library':
        _drawGrowthLibrary(canvas, base, layerScale, accent, grass);
      case 'growth_plaza':
        _drawMemoryPlaza(canvas, base, layerScale, accent, sand);
      default:
        break;
    }

    if (unlockFx) {
      canvas.drawCircle(
        anchor,
        26 * layerScale,
        Paint()
          ..color = accent.withValues(alpha: 0.18 + 0.08 * math.sin(_time * 4)),
      );
    }
  }

  void _drawConfiguredBuilding(
    Canvas canvas,
    Offset base,
    double scale,
    BuildingConfig config,
    Color accent,
    Color sea,
    Color grass,
    Color sand,
  ) {
    switch (config.type) {
      case 'stone':
        _drawConfiguredStone(canvas, base, scale, sand);
      case 'house':
        _drawConfiguredHouse(canvas, base, scale, config.upgradeLevel, accent);
      case 'clocktower':
        _drawConfiguredTower(canvas, base, scale, accent);
      case 'academy':
        _drawConfiguredAcademy(canvas, base, scale, accent, grass);
      case 'lighthouse':
      case 'lighthouse_base':
        _drawGrowthLighthouse(canvas, base, scale, accent, sea);
      case 'library':
      case 'gallery':
        _drawGrowthLibrary(canvas, base, scale, accent, grass);
      case 'plaza':
      case 'fountain':
        _drawMemoryPlaza(canvas, base, scale, accent, sand);
      case 'pier':
        _drawConfiguredPier(canvas, base, scale);
      case 'shed':
      case 'mailbox':
      case 'windchime':
      case 'flowerbed':
      case 'tent':
      case 'observatory':
      default:
        _drawConfiguredSmallBuilding(canvas, base, scale, accent, grass);
    }
  }

  void _drawConfiguredStone(
      Canvas canvas, Offset base, double scale, Color sand) {
    final rect = Rect.fromCenter(
      center: base + Offset(0, -8 * scale),
      width: 22 * scale,
      height: 16 * scale,
    );
    canvas.drawOval(
      rect,
      Paint()..color = Color.lerp(sand, const Color(0xFFB0BEC5), 0.42)!,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF78909C).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );
  }

  void _drawConfiguredHouse(
    Canvas canvas,
    Offset base,
    double scale,
    int upgradeLevel,
    Color accent,
  ) {
    final bodyW = (38 + upgradeLevel * 6) * scale;
    final bodyH = (28 + upgradeLevel * 4) * scale;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -18 * scale),
        width: bodyW,
        height: bodyH,
      ),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFFF4E7D2).withValues(alpha: 0.95),
    );
    final roof = Path()
      ..moveTo(base.dx - bodyW * 0.58, base.dy - bodyH)
      ..lineTo(base.dx, base.dy - bodyH - 18 * scale)
      ..lineTo(base.dx + bodyW * 0.58, base.dy - bodyH)
      ..close();
    canvas.drawPath(
      roof,
      Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.86),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: base + Offset(0, -12 * scale),
        width: 9 * scale,
        height: 14 * scale,
      ),
      Paint()..color = accent.withValues(alpha: 0.55),
    );
  }

  void _drawConfiguredTower(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
  ) {
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -34 * scale),
        width: 18 * scale,
        height: 58 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(
      tower,
      Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      base + Offset(0, -62 * scale),
      8 * scale,
      Paint()..color = accent.withValues(alpha: 0.65),
    );
  }

  void _drawConfiguredAcademy(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color grass,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -24 * scale),
        width: 64 * scale,
        height: 34 * scale,
      ),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFFE8DED0).withValues(alpha: 0.96),
    );
    final roof = Path()
      ..moveTo(base.dx - 38 * scale, base.dy - 42 * scale)
      ..lineTo(base.dx, base.dy - 66 * scale)
      ..lineTo(base.dx + 38 * scale, base.dy - 42 * scale)
      ..close();
    canvas.drawPath(
      roof,
      Paint()..color = const Color(0xFF7A5D45).withValues(alpha: 0.9),
    );
    for (final dx in [-18.0, 0.0, 18.0]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: base + Offset(dx * scale, -24 * scale),
          width: 8 * scale,
          height: 16 * scale,
        ),
        Paint()
          ..color = Color.lerp(grass, accent, 0.35)!.withValues(alpha: 0.58),
      );
    }
  }

  void _drawConfiguredPier(Canvas canvas, Offset base, double scale) {
    final wood = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.72)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = base.dy - i * 7 * scale;
      canvas.drawLine(
        Offset(base.dx - 22 * scale, y),
        Offset(base.dx + 22 * scale, y + 2 * scale),
        wood,
      );
    }
  }

  void _drawConfiguredSmallBuilding(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color grass,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -16 * scale),
        width: 30 * scale,
        height: 24 * scale,
      ),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = Color.lerp(grass, const Color(0xFFF5F0E6), 0.72)!,
    );
    canvas.drawCircle(
      base + Offset(10 * scale, -28 * scale),
      3 * scale,
      Paint()..color = accent.withValues(alpha: 0.62),
    );
  }

  /// 开心：沙滩遮阳伞 + 小球
  void _drawSunBeach(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sea,
    Color flower,
  ) {
    final pole = base + Offset(0, -4 * scale);
    canvas.drawLine(
      pole,
      pole + Offset(0, -34 * scale),
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.75)
        ..strokeWidth = 2.2 * scale
        ..strokeCap = StrokeCap.round,
    );
    final canopy = Path()
      ..moveTo(pole.dx, pole.dy - 34 * scale)
      ..quadraticBezierTo(
        pole.dx - 28 * scale,
        pole.dy - 20 * scale,
        pole.dx - 26 * scale,
        pole.dy - 6 * scale,
      )
      ..lineTo(pole.dx + 26 * scale, pole.dy - 6 * scale)
      ..quadraticBezierTo(
        pole.dx + 28 * scale,
        pole.dy - 20 * scale,
        pole.dx,
        pole.dy - 34 * scale,
      )
      ..close();
    canvas.drawPath(
      canopy,
      Paint()
        ..shader = LinearGradient(
          colors: [
            flower.withValues(alpha: 0.85),
            accent.withValues(alpha: 0.75),
          ],
        ).createShader(Rect.fromLTWH(pole.dx - 30 * scale, pole.dy - 36 * scale,
            60 * scale, 32 * scale)),
    );
    canvas.drawCircle(
      pole + Offset(22 * scale, -8 * scale),
      5 * scale,
      Paint()..color = sea.withValues(alpha: 0.8),
    );
    _drawSunIcon(
        canvas, pole + Offset(-18 * scale, -42 * scale), 9 * scale, accent);
  }

  void _drawSunIcon(Canvas canvas, Offset c, double r, Color accent) {
    canvas.drawCircle(c, r, Paint()..color = accent.withValues(alpha: 0.9));
    final ray = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        c + Offset(math.cos(a) * (r + 2), math.sin(a) * (r + 2)),
        c + Offset(math.cos(a) * (r + 7), math.sin(a) * (r + 7)),
        ray,
      );
    }
  }

  /// 开心/平静（calm）：野餐垫 + 小树
  void _drawGreenRest(
    Canvas canvas,
    Offset base,
    double scale,
    Color grass,
    Color accent,
  ) {
    final mat = Rect.fromCenter(
      center: base + Offset(0, -8 * scale),
      width: 44 * scale,
      height: 22 * scale,
    );
    canvas.drawOval(
      mat,
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      mat,
      Paint()
        ..color = grass.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
    final trunk = base + Offset(0, -18 * scale);
    canvas.drawLine(
      trunk,
      trunk + Offset(0, -16 * scale),
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.7)
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      trunk + Offset(0, -22 * scale),
      11 * scale,
      Paint()..color = grass.withValues(alpha: 0.75),
    );
  }

  /// 平静/思考：叠石 + 水纹
  void _drawZenStones(
    Canvas canvas,
    Offset base,
    double scale,
    Color sand,
    Color accent,
    Color sea,
  ) {
    final stones = [
      (8.0, 0.0),
      (6.0, -10.0),
      (4.5, -18.0),
    ];
    for (final (r, dy) in stones) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base + Offset(0, dy * scale),
          width: r * 2 * scale,
          height: r * 1.3 * scale,
        ),
        Paint()..color = Color.lerp(sand, const Color(0xFF90A4AE), 0.35)!,
      );
    }
    final ring = Paint()
      ..color = sea.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base + Offset(0, 6 * scale),
          width: (18 + i * 8) * scale,
          height: (7 + i * 3) * scale,
        ),
        ring,
      );
    }
    canvas.drawCircle(
      base + Offset(14 * scale, -24 * scale),
      3 * scale,
      Paint()..color = accent.withValues(alpha: 0.5),
    );
  }

  /// 低落：暖光小灯塔（可辨认，非玻璃卡片）
  void _drawWarmLamp(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sea,
  ) {
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -22 * scale),
        width: 14 * scale,
        height: 32 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(
      tower,
      Paint()..color = sea.withValues(alpha: 0.55),
    );
    final glow = base + Offset(0, -40 * scale);
    canvas.drawCircle(
      glow,
      8 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF9C4).withValues(alpha: 0.95),
            accent.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: 14 * scale)),
    );
    canvas.drawCircle(
      glow,
      4 * scale,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.9),
    );
  }

  /// 生气：岩石气孔 + 热气
  void _drawLavaVent(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sand,
  ) {
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center:
              base + Offset((i - 1) * 12.0 * scale, -4 * scale - (i % 2) * 3),
          width: 18 * scale,
          height: 10 * scale,
        ),
        Paint()..color = Color.lerp(sand, const Color(0xFF3E2723), 0.5)!,
      );
    }
    final steam = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final p = base + Offset(i * 8.0 * scale, -14 * scale);
      final wobble = math.sin(_time * 2 + i) * 3 * scale;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(
            p.dx + i * 4 * scale + wobble,
            p.dy - 12 * scale,
            p.dx + i * 2 * scale,
            p.dy - 24 * scale,
          ),
        steam,
      );
    }
  }

  void _drawGrowthTree(
    Canvas canvas,
    Offset base,
    double scale,
    int level,
    Color accent,
  ) {
    final height = (48 + level * 6) * scale;
    canvas.drawLine(
      base + Offset(0, -4 * scale),
      base + Offset(0, -height),
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.72)
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      base + Offset(0, -height),
      (10 + level * 2) * scale,
      Paint()..color = accent.withValues(alpha: 0.55),
    );
  }

  /// 成长岛：灯塔（繁荣 tier ≥ 2）
  void _drawGrowthLighthouse(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sea,
  ) {
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -28 * scale),
        width: 16 * scale,
        height: 44 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(
      tower,
      Paint()..color = sea.withValues(alpha: 0.65),
    );
    canvas.drawRRect(
      tower,
      Paint()
        ..color = const Color(0xFFCFD8DC).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
    final glow = base + Offset(0, -54 * scale);
    final pulse = 0.85 + 0.15 * math.sin(_time * 2.2);
    canvas.drawCircle(
      glow,
      10 * scale * pulse,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF9C4).withValues(alpha: 0.95),
            accent.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: 16 * scale)),
    );
    canvas.drawCircle(
      glow,
      5 * scale,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.92),
    );
  }

  /// 成长岛：图书馆（繁荣 tier ≥ 3）
  void _drawGrowthLibrary(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color grass,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, -18 * scale),
        width: 38 * scale,
        height: 28 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.92),
    );
    final roof = Path()
      ..moveTo(base.dx - 22 * scale, base.dy - 32 * scale)
      ..lineTo(base.dx, base.dy - 48 * scale)
      ..lineTo(base.dx + 22 * scale, base.dy - 32 * scale)
      ..close();
    canvas.drawPath(
      roof,
      Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.88),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: base + Offset(0, -20 * scale),
        width: 10 * scale,
        height: 14 * scale,
      ),
      Paint()..color = grass.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      base + Offset(14 * scale, -38 * scale),
      3 * scale,
      Paint()..color = accent.withValues(alpha: 0.5),
    );
  }

  /// 成长岛：记忆广场（繁荣 tier ≥ 4）
  void _drawMemoryPlaza(
    Canvas canvas,
    Offset base,
    double scale,
    Color accent,
    Color sand,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, -6 * scale),
        width: 52 * scale,
        height: 14 * scale,
      ),
      Paint()..color = sand.withValues(alpha: 0.75),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, -6 * scale),
        width: 52 * scale,
        height: 14 * scale,
      ),
      Paint()
        ..color = const Color(0xFF90A4AE).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
    for (final dx in [-16.0, 16.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: base + Offset(dx * scale, -22 * scale),
            width: 6 * scale,
            height: 22 * scale,
          ),
          Radius.circular(2 * scale),
        ),
        Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.9),
      );
    }
    canvas.drawCircle(
      base + Offset(0, -10 * scale),
      4 * scale,
      Paint()..color = accent.withValues(alpha: 0.55),
    );
  }
}
