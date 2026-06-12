import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/growth/growth_system.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/app_fonts.dart';
import '../../island/config/island_visual_config.dart';

/// 叠在岛景上的 HUD：等级、连续天、进度、心情入口。
class IslandHudOverlay extends StatelessWidget {
  const IslandHudOverlay({
    super.key,
    required this.summary,
    required this.todayMoodId,
    required this.todayMoodLabel,
    this.onRecordTap,
    this.onMoodTap,
  });

  final GrowthSummary summary;
  final String todayMoodId;
  final String todayMoodLabel;
  final VoidCallback? onRecordTap;
  final VoidCallback? onMoodTap;

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
                          summary: summary, tierLabel: tierLabel)),
                  const SizedBox(width: 8),
                  _MoodChip(
                    moodId: todayMoodId,
                    label: todayMoodLabel,
                    onTap: onMoodTap,
                  ),
                ],
              ),
            ),
            const Spacer(),
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
  const _TopLeftCard({required this.summary, required this.tierLabel});

  final GrowthSummary summary;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    final nextLabel = summary.nextLevel != null
        ? '下一级 Lv.${summary.nextLevel} ${summary.nextLevelTitle ?? ''}'.trim()
        : '已到达当前最高等级';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
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
            'Lv.${summary.level} ${summary.levelTitle}',
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D3229),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '🔥 ${summary.streakDays} 天 · ✦ ${summary.growthValue}',
            style: appTextStyle(fontSize: 11, color: const Color(0xFF8C7B6B)),
          ),
          const SizedBox(height: 1),
          Text(
            nextLabel,
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
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.moodId, required this.label, this.onTap});

  final String moodId;
  final String label;
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CustomPaint(
                  painter: _WeatherMoodIconPainter(moodId),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: appTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D4E44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherMoodIconPainter extends CustomPainter {
  const _WeatherMoodIconPainter(this.moodId);

  final String moodId;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    switch (moodId) {
      case 'happy':
        _drawSunFace(canvas, c, size.shortestSide * 0.30,
            color: const Color(0xFFFFC83D), smile: 1.0, rays: true);
        return;
      case 'sad':
        _drawCloud(canvas, c + Offset(0, size.height * 0.02), size,
            color: const Color(0xFFB8C7D2));
        _drawRain(canvas, size, const Color(0xFF77A9D8));
        return;
      case 'thinking':
      case 'anxious':
        _drawCloud(canvas, c, size, color: const Color(0xFFB9B0D8));
        _drawWind(canvas, size, const Color(0xFF7E6DB7));
        return;
      case 'angry':
        _drawCloud(canvas, c, size, color: const Color(0xFFD09A8F));
        _drawWind(canvas, size, const Color(0xFFFF7043));
        return;
      case 'proud':
      case 'expecting':
      case 'hopeful':
        _drawSunFace(canvas, c, size.shortestSide * 0.28,
            color: const Color(0xFF52D9B5), smile: 0.75, rays: false);
        _drawSpark(canvas, c + Offset(size.width * 0.26, -size.height * 0.22),
            size.shortestSide * 0.10, const Color(0xFFFFF59D));
        return;
      default:
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

  void _drawSpark(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.32, c.dy - r * 0.32)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.32, c.dy + r * 0.32)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.32, c.dy + r * 0.32)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.32, c.dy - r * 0.32)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WeatherMoodIconPainter oldDelegate) =>
      oldDelegate.moodId != moodId;
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
        ? '距离 Lv.$next 还需 ${(need! - summary.xpIntoLevel).clamp(0, need!)} 成长值'
        : '你的成长世界正在变得繁荣';

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
