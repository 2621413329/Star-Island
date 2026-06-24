import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/island_weather.dart';
import '../../core/growth/growth_system.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/app_fonts.dart';
import '../../island/config/island_visual_config.dart';

/// 叠在岛景上的 HUD：等级、连续天、进度；底部浮条展示天气所在地与实况。
class IslandHudOverlay extends StatelessWidget {
  const IslandHudOverlay({
    super.key,
    required this.summary,
    required this.weatherKind,
    required this.weatherLabel,
    required this.geoLocationLabel,
    this.onRecordTap,
    this.onWeatherTap,
    this.onLevelTap,
  });

  final GrowthSummary summary;
  final IslandWeather weatherKind;
  final String weatherLabel;
  final String geoLocationLabel;
  final VoidCallback? onRecordTap;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onLevelTap;

  @override
  Widget build(BuildContext context) {
    final tier = IslandVisualConfig.prosperityTierFromLevel(summary.level);
    final tierLabel = IslandVisualConfig.prosperityLabel(tier);
    final next = summary.nextLevel;
    final need = summary.xpForNextLevel;
    final progress = need != null && need > 0
        ? (summary.xpIntoLevel / need).clamp(0.0, 1.0)
        : 1.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.pageHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TopLeftCard(
                      summary: summary,
                      tierLabel: tierLabel,
                      onTap: onLevelTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _WeatherChip(
                    weatherKind: weatherKind,
                    onTap: onWeatherTap,
                  ),
                ],
              ),
            ),
            Expanded(
              child: IgnorePointer(
                child: const SizedBox(width: double.infinity),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: _LocationWeatherFloat(
                locationLabel: geoLocationLabel,
                islandLabel: tierLabel,
                weatherKind: weatherKind,
                weatherLabel: weatherLabel,
                onTap: onWeatherTap,
              ),
            ),
            const SizedBox(height: 12),
            _BottomProgress(
              summary: summary,
              progress: progress,
              next: next,
              need: need,
              onRecordTap: onRecordTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopLeftCard extends StatelessWidget {
  const _TopLeftCard({
    required this.summary,
    required this.tierLabel,
    this.onTap,
  });

  final GrowthSummary summary;
  final String tierLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GrowthSystem.levelDisplayLabel(summary),
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D3229),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '🔥 ${summary.streakDays} 天',
            style: appTextStyle(fontSize: 11, color: const Color(0xFF8C7B6B)),
          ),
          const SizedBox(height: 1),
          Text(
            summary.nextLevel == null
                ? '已满级 · 岛屿传说'
                : '下一级 Lv.${summary.nextLevel} ${summary.nextLevelTitle ?? ''}'
                    .trim(),
            style: appTextStyle(
              fontSize: 10,
              color: const Color(0xFF6F8F7B),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            tierLabel,
            style: appTextStyle(
              fontSize: 10,
              color: const Color(0xFF8C7B6B),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({
    required this.weatherKind,
    this.onTap,
  });

  final IslandWeather weatherKind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SizedBox(
            width: 34,
            height: 34,
            child: CustomPaint(
              painter: _WeatherIconPainter(weatherKind),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationWeatherFloat extends StatelessWidget {
  const _LocationWeatherFloat({
    required this.locationLabel,
    required this.islandLabel,
    required this.weatherKind,
    required this.weatherLabel,
    this.onTap,
  });

  final String locationLabel;
  final String islandLabel;
  final IslandWeather weatherKind;
  final String weatherLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final placeText = islandLabel.isEmpty
        ? locationLabel
        : '$locationLabel · $islandLabel';
    return Material(
      color: Colors.white.withValues(alpha: 0.84),
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                placeText,
                style: appTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D3229),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 22,
                color: const Color(0xFFD8CEC4),
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: CustomPaint(
                  painter: _WeatherIconPainter(weatherKind),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                weatherLabel,
                style: appTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A3F36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherIconPainter extends CustomPainter {
  const _WeatherIconPainter(this.weatherKind);

  final IslandWeather weatherKind;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    switch (weatherKind) {
      case IslandWeather.sunny:
        _drawSunFace(canvas, c, size.shortestSide * 0.30,
            color: const Color(0xFFFFC83D), smile: 1.0, rays: true);
        return;
      case IslandWeather.drizzle:
        _drawCloud(canvas, c + Offset(0, size.height * 0.02), size,
            color: const Color(0xFFB8C7D2));
        _drawRain(canvas, size, const Color(0xFF77A9D8));
        return;
      case IslandWeather.windy:
        _drawCloud(canvas, c, size, color: const Color(0xFFB9B0D8));
        _drawWind(canvas, size, const Color(0xFF7E6DB7));
        return;
      case IslandWeather.overcast:
        _drawCloud(canvas, c, size, color: const Color(0xFF9EACB5));
        return;
      case IslandWeather.softCloud:
        _drawSunFace(canvas, c, size.shortestSide * 0.28,
            color: const Color(0xFF8EC5FF), smile: 0.55, rays: false);
        _drawCloud(canvas, c + Offset(size.width * 0.15, size.height * 0.11),
            size * 0.70,
            color: Colors.white.withValues(alpha: 0.82));
        return;
    }
  }

  void _drawSunFace(
    Canvas canvas,
    Offset c,
    double r, {
    required Color color,
    required double smile,
    required bool rays,
  }) {
    if (rays) {
      final ray = Paint()
        ..color = color.withValues(alpha: 0.70)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi * 2 / 10;
        canvas.drawLine(
          c + Offset(math.cos(a), math.sin(a)) * (r + 2),
          c + Offset(math.cos(a), math.sin(a)) * (r + 6),
          ray,
        );
      }
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [Colors.white.withValues(alpha: 0.95), color],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final eye = Paint()..color = const Color(0xFF5D4037);
    canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.10), r * 0.08, eye);
    canvas.drawCircle(c + Offset(r * 0.35, -r * 0.10), r * 0.08, eye);
    canvas.drawArc(
      Rect.fromCenter(
          center: c + Offset(0, r * 0.08), width: r * 0.70, height: r * 0.42),
      0.15,
      math.pi * smile,
      false,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCloud(Canvas canvas, Offset c, Size size, {required Color color}) {
    final paint = Paint()..color = color;
    final w = size.shortestSide;
    canvas.drawCircle(c + Offset(-w * 0.18, 0), w * 0.20, paint);
    canvas.drawCircle(c + Offset(0, -w * 0.08), w * 0.25, paint);
    canvas.drawCircle(c + Offset(w * 0.20, w * 0.01), w * 0.19, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: c + Offset(w * 0.02, w * 0.08),
            width: w * 0.62,
            height: w * 0.25),
        Radius.circular(w * 0.14),
      ),
      paint,
    );
    final eye = Paint()
      ..color = const Color(0xFF5D4E44).withValues(alpha: 0.75);
    canvas.drawCircle(c + Offset(-w * 0.10, w * 0.07), w * 0.035, eye);
    canvas.drawCircle(c + Offset(w * 0.12, w * 0.07), w * 0.035, eye);
  }

  void _drawRain(Canvas canvas, Size size, Color color) {
    final rain = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final x in [0.34, 0.50, 0.66]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.66),
        Offset(size.width * x - 2, size.height * 0.82),
        rain,
      );
    }
  }

  void _drawWind(Canvas canvas, Size size, Color color) {
    final wind = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final y = size.height * (0.64 + i * 0.13);
      canvas.drawArc(
        Rect.fromLTWH(
            size.width * 0.24, y, size.width * 0.52, size.height * 0.18),
        math.pi,
        math.pi * 0.9,
        false,
        wind,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherIconPainter oldDelegate) =>
      oldDelegate.weatherKind != weatherKind;
}

class _BottomProgress extends StatelessWidget {
  const _BottomProgress({
    required this.summary,
    required this.progress,
    required this.next,
    required this.need,
    this.onRecordTap,
  });

  final GrowthSummary summary;
  final double progress;
  final int? next;
  final int? need;
  final VoidCallback? onRecordTap;

  @override
  Widget build(BuildContext context) {
    final hint = next != null && need != null && need! > 0
        ? GrowthSystem.compactNextLevelLabel(summary)
        : '你已成为岛屿传说';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hint,
                style:
                    appTextStyle(fontSize: 12, color: const Color(0xFF5D4E44)),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8DDD4),
                  color: const Color(0xFFE8A87C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (onRecordTap != null)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: onRecordTap,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('记录今天'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5D4E44),
                backgroundColor: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
