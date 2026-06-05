import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/models/mood_island_config.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';

class GrowthIslandGameWidget extends StatefulWidget {
  const GrowthIslandGameWidget({
    super.key,
    required this.palette,
    required this.moments,
    this.islandConfig,
    this.highlightedMomentId,
    this.compact = false,
  });

  final MoodPalette palette;
  final MoodIslandConfig? islandConfig;
  final List<DailyMomentModel> moments;
  final String? highlightedMomentId;
  final bool compact;

  @override
  State<GrowthIslandGameWidget> createState() => _GrowthIslandGameWidgetState();
}

class _GrowthIslandGameWidgetState extends State<GrowthIslandGameWidget> {
  late final GrowthIslandGame _game;

  @override
  void initState() {
    super.initState();
    _game = GrowthIslandGame(
      palette: widget.palette,
      islandConfig: widget.islandConfig,
      highlightedMomentId: widget.highlightedMomentId,
      moments: widget.moments,
      compact: widget.compact,
    );
  }

  @override
  void didUpdateWidget(covariant GrowthIslandGameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateScene(
      palette: widget.palette,
      islandConfig: widget.islandConfig,
      highlightedMomentId: widget.highlightedMomentId,
      moments: widget.moments,
      compact: widget.compact,
    );
  }

  @override
  Widget build(BuildContext context) => GameWidget(game: _game);
}

class GrowthIslandGame extends FlameGame {
  GrowthIslandGame({
    required MoodPalette palette,
    required List<DailyMomentModel> moments,
    MoodIslandConfig? islandConfig,
    String? highlightedMomentId,
    bool compact = false,
  })  : _palette = palette,
        _moments = List.of(moments),
        _islandConfig = islandConfig,
        _highlightedMomentId = highlightedMomentId,
        _compact = compact;

  MoodPalette _palette;
  MoodIslandConfig? _islandConfig;
  List<DailyMomentModel> _moments;
  String? _highlightedMomentId;
  bool _compact;
  double _time = 0;

  void updateScene({
    required MoodPalette palette,
    required List<DailyMomentModel> moments,
    MoodIslandConfig? islandConfig,
    String? highlightedMomentId,
    bool compact = false,
  }) {
    _palette = palette;
    _islandConfig = islandConfig;
    _moments = List.of(moments);
    _highlightedMomentId = highlightedMomentId;
    _compact = compact;
  }

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final s = Size(size.x, size.y);
    if (s.width <= 0 || s.height <= 0) return;

    final biome = _IslandBiome.from(_islandConfig, _palette);
    _drawOcean(canvas, s, biome);
    _drawDistantLight(canvas, s, biome);
    _drawIslandShadow(canvas, s);
    _drawIslandBody(canvas, s, biome);
    _drawMoodDecor(canvas, s, biome);
    _drawMomentDecor(canvas, s, biome);
    _drawAtmosphere(canvas, s, biome);
  }

  Path _heartIslandPath(Size s, {double lift = 0}) {
    final w = s.width;
    final h = s.height;
    final cx = w * 0.5;
    final cy = h * (_compact ? 0.58 : 0.56) + lift;
    final scaleX = w * (_compact ? 0.31 : 0.38);
    final scaleY = h * (_compact ? 0.2 : 0.24);
    final path = Path();
    for (var i = 0; i <= 160; i++) {
      final t = math.pi * 2 * i / 160;
      final x = 16 * math.pow(math.sin(t), 3).toDouble();
      final y = -(13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t));
      final p = Offset(cx + x / 18 * scaleX, cy + y / 18 * scaleY);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _drawOcean(Canvas canvas, Size s, _IslandBiome biome) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [biome.skyTop, biome.skyBottom, biome.sea, Color.lerp(biome.sea, const Color(0xFF0277BD), 0.34)!],
          stops: const [0, 0.34, 0.68, 1],
        ).createShader(rect),
    );

    final shimmerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (var i = 0; i < 22; i++) {
      final y = s.height * (0.18 + (i % 9) * 0.08) + math.sin(_time * 0.8 + i) * 4;
      final x = (i * 47.0 + _time * 18) % (s.width + 80) - 40;
      final len = 20 + (i % 4) * 16;
      shimmerPaint.color = Colors.white.withValues(alpha: 0.1 + 0.08 * math.sin(_time + i).abs());
      canvas.drawLine(Offset(x, y), Offset(x + len, y + math.sin(i) * 5), shimmerPaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < 4; i++) {
      final phase = (_time * 0.12 + i * 0.23) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.5, s.height * 0.63),
          width: s.width * (0.62 + phase * 0.34),
          height: s.height * (0.22 + phase * 0.16),
        ),
        ringPaint..color = Colors.white.withValues(alpha: (1 - phase) * 0.22),
      );
    }
  }

  void _drawDistantLight(Canvas canvas, Size s, _IslandBiome biome) {
    final sun = biome.moodId == 'happy' || biome.biome == 'sunset' ? biome.accent : Color.lerp(biome.accent, Colors.white, 0.35)!;
    canvas.drawCircle(
      Offset(s.width * 0.18, s.height * 0.16),
      s.width * 0.13,
      Paint()
        ..shader = RadialGradient(
          colors: [sun.withValues(alpha: 0.42), sun.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(s.width * 0.18, s.height * 0.16), radius: s.width * 0.16)),
    );
  }

  void _drawIslandShadow(Canvas canvas, Size s) {
    final shadow = _heartIslandPath(s, lift: s.height * 0.055);
    canvas.drawPath(
      shadow,
      Paint()
        ..color = const Color(0xFF004D63).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  void _drawIslandBody(Canvas canvas, Size s, _IslandBiome biome) {
    final lower = _heartIslandPath(s, lift: s.height * 0.045);
    final beach = _heartIslandPath(s, lift: s.height * 0.018);
    final grass = _heartIslandPath(s);

    canvas.drawPath(lower, Paint()..color = Color.lerp(biome.sand, const Color(0xFF8D6E63), 0.28)!);
    canvas.drawPath(
      beach,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(biome.sand, Colors.white, 0.28)!, biome.sand],
        ).createShader(Offset.zero & s),
    );

    canvas.save();
    canvas.clipPath(grass);
    final grassRect = Rect.fromLTWH(s.width * 0.18, s.height * 0.31, s.width * 0.64, s.height * 0.4);
    canvas.drawOval(
      grassRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(biome.grass, Colors.white, 0.42)!,
            biome.grass,
            Color.lerp(biome.grass, const Color(0xFF2E7D32), 0.2)!,
          ],
        ).createShader(grassRect),
    );
    _drawGrassSparkles(canvas, s, biome);
    canvas.restore();

    canvas.drawPath(
      grass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _drawGrassSparkles(Canvas canvas, Size s, _IslandBiome biome) {
    for (var i = 0; i < 36; i++) {
      final p = _decorSlot(i, s, 36);
      final r = 1.2 + (i % 3) * 0.7 + math.sin(_time * 2 + i) * 0.25;
      canvas.drawCircle(
        p,
        r,
        Paint()..color = Color.lerp(biome.flower, Colors.white, (i % 5) * 0.12)!.withValues(alpha: 0.65),
      );
    }
  }

  void _drawMoodDecor(Canvas canvas, Size s, _IslandBiome biome) {
    _drawPalm(canvas, Offset(s.width * 0.68, s.height * 0.46), 1, biome);
    _drawPalm(canvas, Offset(s.width * 0.78, s.height * 0.5), -1, biome, scale: 0.72);
    _drawShell(canvas, Offset(s.width * 0.38, s.height * 0.7), s.width * 0.045, biome);
    _drawStarfish(canvas, Offset(s.width * 0.59, s.height * 0.72), s.width * 0.04, biome.accent);

    if (biome.moodId == 'sad') {
      _drawCrystal(canvas, Offset(s.width * 0.34, s.height * 0.58), biome.accent);
      _drawUmbrella(canvas, Offset(s.width * 0.26, s.height * 0.63), biome);
    } else if (biome.moodId == 'angry') {
      _drawWindRibbon(canvas, Offset(s.width * 0.28, s.height * 0.56), biome.accent);
      _drawWindRibbon(canvas, Offset(s.width * 0.36, s.height * 0.64), const Color(0xFFFF7043));
    } else if (biome.moodId == 'thinking') {
      _drawMoonStone(canvas, Offset(s.width * 0.31, s.height * 0.59), biome);
      _drawFireflies(canvas, s, biome);
    } else if (biome.moodId == 'happy') {
      _drawTinyFlags(canvas, Offset(s.width * 0.27, s.height * 0.59), biome.accent);
      _drawTinyFlags(canvas, Offset(s.width * 0.35, s.height * 0.64), const Color(0xFFFFA726));
    } else {
      _drawWarmLamp(canvas, Offset(s.width * 0.29, s.height * 0.61), biome.accent);
    }
  }

  void _drawMomentDecor(Canvas canvas, Size s, _IslandBiome biome) {
    final count = math.min(_moments.length, 12);
    for (var i = 0; i < count; i++) {
      final m = _moments[i];
      final p = _decorSlot(i, s, count);
      final pulse = 0.75 + 0.25 * math.sin(_time * 1.8 + i);
      if (m.id == _highlightedMomentId) {
        canvas.drawCircle(
          p,
          25 + 6 * math.sin(_time * 5).abs(),
          Paint()..color = biome.accent.withValues(alpha: 0.2),
        );
        canvas.drawCircle(
          p,
          15,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      final type = _decorType(m);
      switch (type) {
        case _MomentDecor.study:
          _drawBook(canvas, p, biome, pulse);
        case _MomentDecor.sport:
          _drawSportMark(canvas, p, biome, pulse);
        case _MomentDecor.friend:
          _drawFriendBloom(canvas, p, biome, pulse);
        case _MomentDecor.family:
          _drawHomeLight(canvas, p, biome, pulse);
        case _MomentDecor.hobby:
          _drawPinwheel(canvas, p, biome, pulse);
        case _MomentDecor.other:
          _drawShell(canvas, p, 11 + pulse * 2, biome);
      }
    }
  }

  Offset _decorSlot(int i, Size s, int count) {
    final angle = -math.pi * 0.86 + (math.pi * 1.72) * ((i % math.max(1, count)) / math.max(1, count - 1));
    final ring = i.isEven ? 0.78 : 0.48;
    return Offset(
      s.width * 0.5 + math.cos(angle) * s.width * 0.25 * ring,
      s.height * 0.58 + math.sin(angle) * s.height * 0.16 * ring + (i % 3 - 1) * 7,
    );
  }

  _MomentDecor _decorType(DailyMomentModel m) {
    final text = '${m.eventTags.join()} ${m.note ?? ''} ${m.companionSpec.prop}';
    if (text.contains('学习') || text.contains('workbook')) return _MomentDecor.study;
    if (text.contains('运动') || text.contains('ball') || text.contains('badminton')) return _MomentDecor.sport;
    if (text.contains('朋友') || text.contains('friends') || text.contains('heart') || text.contains('chat')) {
      return _MomentDecor.friend;
    }
    if (text.contains('家庭') || text.contains('home')) return _MomentDecor.family;
    if (text.contains('兴趣') || text.contains('music')) return _MomentDecor.hobby;
    return _MomentDecor.other;
  }

  void _drawAtmosphere(Canvas canvas, Size s, _IslandBiome biome) {
    if (biome.rain) {
      final rain = Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..strokeWidth = 1.1;
      for (var i = 0; i < 42; i++) {
        final x = (i * 37.0 + _time * 24) % s.width;
        final y = (i * 23.0 + _time * 86) % (s.height * 0.68);
        canvas.drawLine(Offset(x, y), Offset(x - 3, y + 9), rain);
      }
    }

    if (biome.particles == 'sparkle' || biome.particles == 'fireflies') {
      _drawFireflies(canvas, s, biome);
    }
  }

  void _drawPalm(Canvas canvas, Offset base, int flip, _IslandBiome biome, {double scale = 1}) {
    final sway = math.sin(_time * 1.4 + base.dx * 0.01) * (biome.wind ? 9 : 4);
    final trunk = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    final top = base + Offset(sway, -48 * scale);
    canvas.drawLine(base, top, trunk);
    final leaf = Paint()
      ..color = Color.lerp(const Color(0xFF66BB6A), biome.grass, 0.35)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = -3; i <= 3; i++) {
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + i * 16.0 * flip * scale,
          top.dy - 18 * scale - i.abs() * 3,
          top.dx + i * 28.0 * flip * scale,
          top.dy + 10 * scale,
        );
      canvas.drawPath(path, leaf);
    }
    canvas.drawCircle(top + Offset(3.0 * flip, 8 * scale), 4 * scale, Paint()..color = const Color(0xFFB87333));
  }

  void _drawBook(Canvas canvas, Offset p, _IslandBiome biome, double pulse) {
    final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 24, height: 15), const Radius.circular(3));
    canvas.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.82));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = biome.accent.withValues(alpha: 0.75),
    );
    canvas.drawCircle(p + const Offset(0, -12), 5 * pulse, Paint()..color = biome.accent.withValues(alpha: 0.18));
  }

  void _drawSportMark(Canvas canvas, Offset p, _IslandBiome biome, double pulse) {
    canvas.drawCircle(p, 7 * pulse, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.75));
    canvas.drawLine(
      p + const Offset(8, -10),
      p + const Offset(22, 5),
      Paint()
        ..color = biome.accent.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(center: p + const Offset(26, 9), width: 15, height: 20),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.88),
    );
  }

  void _drawFriendBloom(Canvas canvas, Offset p, _IslandBiome biome, double pulse) {
    final heart = Path()
      ..moveTo(p.dx, p.dy + 7)
      ..cubicTo(p.dx - 16, p.dy - 5, p.dx - 6, p.dy - 17, p.dx, p.dy - 7)
      ..cubicTo(p.dx + 6, p.dy - 17, p.dx + 16, p.dy - 5, p.dx, p.dy + 7)
      ..close();
    canvas.drawPath(heart, Paint()..color = const Color(0xFFF8BBD0).withValues(alpha: 0.7 * pulse));
    canvas.drawCircle(p + const Offset(16, -10), 5, Paint()..color = Colors.white.withValues(alpha: 0.55));
    canvas.drawCircle(p + const Offset(24, -12), 3, Paint()..color = Colors.white.withValues(alpha: 0.42));
  }

  void _drawHomeLight(Canvas canvas, Offset p, _IslandBiome biome, double pulse) {
    final house = Path()
      ..moveTo(p.dx - 11, p.dy)
      ..lineTo(p.dx, p.dy - 12)
      ..lineTo(p.dx + 11, p.dy)
      ..lineTo(p.dx + 9, p.dy + 13)
      ..lineTo(p.dx - 9, p.dy + 13)
      ..close();
    canvas.drawPath(house, Paint()..color = const Color(0xFFFFE0B2).withValues(alpha: 0.72));
    canvas.drawCircle(p + const Offset(0, 3), 10 + pulse * 5, Paint()..color = biome.accent.withValues(alpha: 0.14));
  }

  void _drawPinwheel(Canvas canvas, Offset p, _IslandBiome biome, double pulse) {
    canvas.drawLine(p, p + const Offset(0, 18), Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 1.4);
    for (var i = 0; i < 4; i++) {
      final a = _time * 1.6 + i * math.pi / 2;
      final tip = p + Offset(math.cos(a), math.sin(a)) * (12 + pulse * 2);
      canvas.drawLine(p, tip, Paint()..color = Color.lerp(biome.flower, Colors.white, i * 0.18)!.withValues(alpha: 0.78)..strokeWidth = 3);
    }
  }

  void _drawShell(Canvas canvas, Offset p, double r, _IslandBiome biome) {
    canvas.drawOval(
      Rect.fromCenter(center: p, width: r * 1.7, height: r),
      Paint()..color = Color.lerp(biome.sand, Colors.white, 0.42)!.withValues(alpha: 0.78),
    );
  }

  void _drawStarfish(Canvas canvas, Offset p, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.42;
      final q = p + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(q.dx, q.dy);
      } else {
        path.lineTo(q.dx, q.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFF8A65).withValues(alpha: 0.78));
  }

  void _drawCrystal(Canvas canvas, Offset p, Color color) {
    final path = Path()
      ..moveTo(p.dx, p.dy - 20)
      ..lineTo(p.dx + 10, p.dy - 2)
      ..lineTo(p.dx + 4, p.dy + 18)
      ..lineTo(p.dx - 9, p.dy + 7)
      ..lineTo(p.dx - 7, p.dy - 6)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.52));
    canvas.drawCircle(p, 26, Paint()..color = color.withValues(alpha: 0.08));
  }

  void _drawUmbrella(Canvas canvas, Offset p, _IslandBiome biome) {
    canvas.drawArc(
      Rect.fromCenter(center: p, width: 42, height: 28),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawLine(p, p + const Offset(0, 26), Paint()..color = biome.accent..strokeWidth = 2);
  }

  void _drawWindRibbon(Canvas canvas, Offset p, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(p.dx, p.dy - i * 9)
        ..quadraticBezierTo(p.dx + 22, p.dy - 13 - i * 9 + math.sin(_time + i) * 5, p.dx + 48, p.dy - i * 9);
      canvas.drawPath(path, paint);
    }
  }

  void _drawMoonStone(Canvas canvas, Offset p, _IslandBiome biome) {
    canvas.drawOval(Rect.fromCenter(center: p, width: 24, height: 34), Paint()..color = biome.accent.withValues(alpha: 0.35));
    canvas.drawOval(Rect.fromCenter(center: p - const Offset(5, 4), width: 16, height: 24), Paint()..color = Colors.white.withValues(alpha: 0.42));
  }

  void _drawFireflies(Canvas canvas, Size s, _IslandBiome biome) {
    for (var i = 0; i < 12; i++) {
      final p = Offset(
        s.width * (0.2 + (i * 0.061) % 0.58),
        s.height * (0.24 + (i * 0.097) % 0.42) + math.sin(_time * 1.2 + i) * 8,
      );
      canvas.drawCircle(p, 2.2, Paint()..color = biome.accent.withValues(alpha: 0.28 + 0.22 * math.sin(_time + i).abs()));
    }
  }

  void _drawTinyFlags(Canvas canvas, Offset p, Color color) {
    canvas.drawLine(p, p + const Offset(0, -30), Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 2);
    final flag = Path()
      ..moveTo(p.dx, p.dy - 30)
      ..quadraticBezierTo(p.dx + 18, p.dy - 38, p.dx + 34, p.dy - 28)
      ..quadraticBezierTo(p.dx + 16, p.dy - 22, p.dx, p.dy - 24)
      ..close();
    canvas.drawPath(flag, Paint()..color = color.withValues(alpha: 0.75));
  }

  void _drawWarmLamp(Canvas canvas, Offset p, Color color) {
    canvas.drawLine(p, p + const Offset(0, -25), Paint()..color = const Color(0xFF795548)..strokeWidth = 2);
    canvas.drawCircle(p + const Offset(0, -29), 7, Paint()..color = color.withValues(alpha: 0.78));
    canvas.drawCircle(p + const Offset(0, -29), 17, Paint()..color = color.withValues(alpha: 0.16));
  }
}

enum _MomentDecor { study, sport, friend, family, hobby, other }

class _IslandBiome {
  _IslandBiome({
    required this.moodId,
    required this.biome,
    required this.particles,
    required this.skyTop,
    required this.skyBottom,
    required this.sea,
    required this.sand,
    required this.grass,
    required this.accent,
    required this.flower,
    required this.rain,
    required this.wind,
  });

  final String moodId;
  final String biome;
  final String particles;
  final Color skyTop;
  final Color skyBottom;
  final Color sea;
  final Color sand;
  final Color grass;
  final Color accent;
  final Color flower;
  final bool rain;
  final bool wind;

  factory _IslandBiome.from(MoodIslandConfig? config, MoodPalette palette) {
    final moodId = config?.moodId ?? 'calm';
    return _IslandBiome(
      moodId: moodId,
      biome: config?.biome ?? _defaultBiome(moodId),
      particles: config?.ambientParticles ?? _defaultParticles(moodId),
      skyTop: config?.skyTop ?? palette.gradientStart,
      skyBottom: config?.skyBottom ?? palette.gradientEnd,
      sea: config?.sea ?? const Color(0xFF4FC3F7),
      sand: config?.sand ?? const Color(0xFFFFE0B2),
      grass: config?.grass ?? _grassForMood(moodId),
      accent: config?.accent ?? palette.accent,
      flower: config?.flower ?? _flowerForMood(moodId),
      rain: config?.rain ?? moodId == 'sad',
      wind: config?.wind ?? moodId == 'angry',
    );
  }

  static String _defaultBiome(String moodId) => switch (moodId) {
        'happy' => 'sunny',
        'sad' => 'drizzle',
        'angry' => 'windy',
        'thinking' => 'mist',
        _ => 'soft',
      };

  static String _defaultParticles(String moodId) => switch (moodId) {
        'happy' => 'sparkle',
        'thinking' => 'fireflies',
        'angry' => 'leaves',
        'sad' => 'drizzle',
        _ => 'sparkle',
      };

  static Color _grassForMood(String moodId) => switch (moodId) {
        'sad' => const Color(0xFF9CCCBC),
        'thinking' => const Color(0xFFA5B7A0),
        'angry' => const Color(0xFFC7A66A),
        'happy' => const Color(0xFFBCEB63),
        _ => const Color(0xFFA8DF9A),
      };

  static Color _flowerForMood(String moodId) => switch (moodId) {
        'sad' => const Color(0xFFB3E5FC),
        'thinking' => const Color(0xFFE1BEE7),
        'angry' => const Color(0xFFFFAB91),
        'happy' => const Color(0xFFFFF176),
        _ => const Color(0xFFF8BBD0),
      };
}
