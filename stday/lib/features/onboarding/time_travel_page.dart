import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/catalog.dart';
import '../../core/constants/island_weather.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/growth_island_scene.dart';

/// 选中心情后的「时空穿梭」进入小岛。
class TimeTravelArrivalPage extends StatefulWidget {
  const TimeTravelArrivalPage({super.key, required this.moodId});

  final String moodId;

  @override
  State<TimeTravelArrivalPage> createState() => _TimeTravelArrivalPageState();
}

class _TimeTravelArrivalPageState extends State<TimeTravelArrivalPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        context.go('/today');
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteForMood(widget.moodId);
    final mood = moodById(widget.moodId);
    final weather = weatherForMood(widget.moodId);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final warp = 1 + t * 18;
          final opacity = t < 0.15 ? t / 0.15 : 1.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.gradientStart, palette.gradientEnd, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              CustomPaint(painter: _WarpPainter(progress: t)),
              Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t < 0.45 ? '时空穿梭中…' : '欢迎来到我的小岛',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${mood.label} · ${_weatherLabel(weather)}',
                      style: const TextStyle(color: Color(0xFF8C7B6B)),
                    ),
                    const SizedBox(height: 32),
                    Transform.scale(
                      scale: 0.4 + t * 0.6,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.88,
                        height: 260,
                        child: GrowthIslandScene(
                          moodId: widget.moodId,
                          palette: palette,
                          companionStyle: 'chibi',
                          moments: const [],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (t > 0.2)
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: warp,
                      height: warp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25 * (1 - t))),
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

  String _weatherLabel(IslandWeather w) {
    return switch (w) {
      IslandWeather.sunny => '晴朗',
      IslandWeather.softCloud => '温柔多云',
      IslandWeather.overcast => '静静阴天',
      IslandWeather.drizzle => '毛毛雨',
      IslandWeather.windy => '微风',
    };
  }
}

class _WarpPainter extends CustomPainter {
  _WarpPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08 + progress * 0.12)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 24; i++) {
      final angle = i / 24 * math.pi * 2 + progress * 2;
      final len = size.shortestSide * (0.4 + progress * 0.5);
      final end = center + Offset(math.cos(angle), math.sin(angle)) * len;
      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WarpPainter oldDelegate) => oldDelegate.progress != progress;
}
