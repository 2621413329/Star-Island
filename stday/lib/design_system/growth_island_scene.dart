import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/island_weather.dart';
import '../core/models/mood_island_config.dart';
import '../core/theme/mood_theme.dart';
import '../data/models/profile_models.dart';
import 'companion_avatar.dart';

class GrowthIslandScene extends StatefulWidget {
  const GrowthIslandScene({
    super.key,
    required this.moodId,
    required this.palette,
    required this.companionStyle,
    required this.moments,
    this.islandConfig,
    this.scale = 1.0,
    this.compact = false,
    this.onCompanionTap,
  });

  final String? moodId;
  final MoodPalette palette;
  final MoodIslandConfig? islandConfig;
  final String companionStyle;
  final List<DailyMomentModel> moments;
  final double scale;
  final bool compact;
  final void Function(DailyMomentModel moment, CompanionAvatarState state)? onCompanionTap;

  @override
  State<GrowthIslandScene> createState() => GrowthIslandSceneState();
}

class GrowthIslandSceneState extends State<GrowthIslandScene> with TickerProviderStateMixin {
  final Map<String, GlobalKey<CompanionAvatarState>> _companionKeys = {};
  late final AnimationController _interact;
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _interact = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _wave = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _syncKeys();
  }

  void _syncKeys() {
    for (final m in widget.moments) {
      _companionKeys.putIfAbsent(m.id, GlobalKey.new);
    }
  }

  @override
  void didUpdateWidget(covariant GrowthIslandScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
  }

  @override
  void dispose() {
    _interact.dispose();
    _wave.dispose();
    super.dispose();
  }

  void playMoment(String momentId) => _companionKeys[momentId]?.currentState?.playPerformance();

  void playAllMoments() {
    for (final key in _companionKeys.values) {
      key.currentState?.playPerformance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.islandConfig;
    final sky = cfg != null ? _skyFromConfig(cfg) : skyStyleForMood(widget.moodId);
    final waveAmp = cfg?.waveIntensity ?? 0.4;
    return Transform.scale(
      scale: widget.scale,
      alignment: Alignment.topCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final slots = _companionSlots(widget.moments.length, w, h);
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.compact ? 20 : 28),
            child: AnimatedBuilder(
              animation: Listenable.merge([_interact, _wave]),
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _BeachIslandPainter(
                        sky: sky,
                        islandConfig: cfg,
                        palette: widget.palette,
                        wavePhase: _wave.value,
                        waveIntensity: waveAmp,
                        palmSway: math.sin(_interact.value * math.pi) * (cfg?.wind == true ? 0.08 : 0.04),
                      ),
                    ),
                    if (widget.moments.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: h * 0.06),
                          child: CompanionAvatar(
                            style: widget.companionStyle,
                            expression: widget.moodId == 'happy' ? 'happy' : 'calm',
                            actionType: 'wave',
                            companionTint: cfg?.accent ?? widget.palette.accent,
                            size: widget.compact ? 80 : 100,
                            palette: widget.palette,
                          ),
                        ),
                      ),
                    ...List.generate(widget.moments.length, (i) {
                      final m = widget.moments[i];
                      final pos = slots[i];
                      final interactDx = widget.moments.length >= 2
                          ? math.sin(_interact.value * math.pi + i) * 10
                          : 0.0;
                      final key = _companionKeys[m.id]!;
                      final bob = math.sin(_wave.value * math.pi * 2 + i) * 3;
                      return Positioned(
                        left: pos.dx + interactDx - (widget.compact ? 38 : 48),
                        top: pos.dy + bob - (widget.compact ? 44 : 54),
                        child: GestureDetector(
                          onTap: () {
                            key.currentState?.playPerformance();
                            final st = key.currentState;
                            if (st != null) widget.onCompanionTap?.call(m, st);
                          },
                          child: CompanionAvatar(
                            key: key,
                            style: widget.companionStyle,
                            scene: m.companionScene,
                            pose: m.companionPose,
                            spec: m.companionSpec,
                            size: widget.compact ? 76 : 92,
                            palette: widget.palette,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Offset> _companionSlots(int n, double w, double h) {
    final cy = h * 0.52;
    final cx = w * 0.5;
    if (n <= 0) return [];
    if (n == 1) return [Offset(cx, cy)];
    final spread = math.min(w * 0.28, 110.0);
    return List.generate(n, (i) {
      final t = (i / (n - 1) - 0.5) * 2;
      return Offset(cx + t * spread, cy + (i.isEven ? -4 : 6));
    });
  }

  IslandSkyStyle _skyFromConfig(MoodIslandConfig c) {
    return IslandSkyStyle(
      top: c.skyTop,
      bottom: c.skyBottom,
      rain: c.rain,
      wind: c.wind,
      cloudOpacity: c.rain ? 0.55 : 0.35,
      sun: c.moodId == 'happy' ? c.accent : null,
    );
  }
}

class _BeachIslandPainter extends CustomPainter {
  _BeachIslandPainter({
    required this.sky,
    required this.palette,
    required this.wavePhase,
    required this.waveIntensity,
    required this.palmSway,
    this.islandConfig,
  });

  final IslandSkyStyle sky;
  final MoodIslandConfig? islandConfig;
  final MoodPalette palette;
  final double wavePhase;
  final double waveIntensity;
  final double palmSway;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.top, sky.bottom, islandConfig?.sea ?? const Color(0xFF4FC3F7)],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    if (sky.sun != null) {
      canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.14),
        size.width * 0.08,
        Paint()..color = sky.sun!.withValues(alpha: 0.95),
      );
    }

    final cloud = Paint()..color = Colors.white.withValues(alpha: sky.cloudOpacity);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.28, size.height * 0.16), width: 100, height: 34), cloud);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.42, size.height * 0.13), width: 72, height: 28), cloud);

    final seaTop = size.height * 0.58;
    for (var layer = 0; layer < 3; layer++) {
      final path = Path()..moveTo(0, seaTop + layer * 8);
      for (var x = 0.0; x <= size.width; x += 6) {
        final y = seaTop +
            layer * 10 +
            math.sin((x / size.width * 4 + wavePhase * 2 + layer * 0.4) * math.pi) *
                (4 + waveIntensity * 8 - layer * 1.5);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
                islandConfig?.sea ?? const Color(0xFF29B6F6),
                const Color(0xFF0288D1),
                layer / 3,
              )!
              .withValues(alpha: 0.55 - layer * 0.1),
      );
    }

    final sandLight = islandConfig?.sand ?? const Color(0xFFFFE0B2);
    final sandPath = Path()
      ..moveTo(0, size.height * 0.68)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.58, size.width * 0.5, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.66, size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      sandPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(sandLight, Colors.white, 0.35)!,
            sandLight,
            Color.lerp(sandLight, islandConfig?.accent ?? const Color(0xFFFFCC80), 0.4)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45)),
    );

    final dune = Path()
      ..moveTo(size.width * 0.12, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.48, size.width * 0.88, size.height * 0.7);
    canvas.drawPath(
      dune,
      Paint()
        ..color = const Color(0xFFAED581).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round,
    );

    _drawPalm(canvas, Offset(size.width * 0.14 + palmSway * 20, size.height * 0.62), 1);
    _drawPalm(canvas, Offset(size.width * 0.86 - palmSway * 15, size.height * 0.64), -1);

    final shell = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.15 + i * 0.1);
      final y = size.height * (0.78 + (i % 3) * 0.04);
      canvas.drawCircle(Offset(x, y), 2 + (i % 2), shell);
    }

    if (sky.rain) {
      final rain = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.2;
      for (var i = 0; i < 30; i++) {
        final x = (i * 37.0) % size.width;
        final y = (i * 19.0 + wavePhase * 80) % (size.height * 0.55);
        canvas.drawLine(Offset(x, y), Offset(x - 2, y + 7), rain);
      }
    }
  }

  void _drawPalm(Canvas canvas, Offset base, int flip) {
    final trunk = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base + const Offset(0, -42), trunk);
    final leaf = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = -2; i <= 2; i++) {
      final path = Path()
        ..moveTo(base.dx, base.dy - 40)
        ..quadraticBezierTo(
          base.dx + i * 18.0 * flip,
          base.dy - 55 - i.abs() * 4,
          base.dx + i * 28.0 * flip,
          base.dy - 30,
        );
      canvas.drawPath(path, leaf);
    }
  }

  @override
  bool shouldRepaint(covariant _BeachIslandPainter old) =>
      old.wavePhase != wavePhase ||
      old.sky != sky ||
      old.palmSway != palmSway ||
      old.islandConfig != islandConfig ||
      old.waveIntensity != waveIntensity;
}
