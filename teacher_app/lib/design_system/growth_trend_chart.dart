import 'package:flutter/material.dart';

import '../data/models/growth_observation.dart';
import '../core/theme/mood_theme.dart';

/// 根据所选周期内的趋势点推断整体走向（与折线图一致）。
String trendFromTrendPoints(List<TrendPoint> points) {
  if (points.length < 2) return 'stable';
  final delta = points.last.moodScore - points.first.moodScore;
  if (delta > 0.05) return 'up';
  if (delta < -0.05) return 'down';
  return 'stable';
}

/// 成长档案情绪趋势折线（轻量 CustomPainter）
class GrowthTrendChart extends StatelessWidget {
  const GrowthTrendChart({
    super.key,
    required this.points,
    this.height = 120,
    this.palette = defaultPalette,
    this.metricLabel,
  });

  final List<TrendPoint> points;
  final double height;
  final MoodPalette palette;
  final String? metricLabel;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '记录不足，暂无法绘制趋势',
            style: TextStyle(color: palette.accent.withValues(alpha: 0.55), fontSize: 13),
          ),
        ),
      );
    }
    final axisStyle = TextStyle(fontSize: 9, color: palette.accent.withValues(alpha: 0.5));
    final dateStyle = TextStyle(fontSize: 10, color: palette.accent.withValues(alpha: 0.45));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _GrowthTrendPainter(points: points, color: palette.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('低', style: axisStyle),
              Text('中', style: axisStyle),
              Text('高', style: axisStyle),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_shortDate(points.first.date), style: dateStyle),
              Text(_shortDate(points.last.date), style: dateStyle),
            ],
          ),
        ),
        if (metricLabel != null && metricLabel!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            metricLabel!,
            style: TextStyle(
              fontSize: 10,
              height: 1.35,
              color: palette.accent.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }

  static String _shortDate(String iso) {
    if (iso.length >= 10) {
      return iso.substring(5).replaceFirst('-', '/');
    }
    return iso;
  }
}

class _GrowthTrendPainter extends CustomPainter {
  _GrowthTrendPainter({required this.points, required this.color});

  final List<TrendPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scores = points.map((p) => p.moodScore.clamp(0.0, 1.0)).toList();
    const padH = 12.0;
    const padV = 16.0;
    const padLeft = 8.0;
    final w = size.width - padH - padLeft;
    final h = size.height - padV * 2;
    if (w <= 0 || h <= 0 || scores.length < 2) return;

    final path = Path();
    for (var i = 0; i < scores.length; i++) {
      final x = padLeft + (i / (scores.length - 1)) * w;
      final y = padV + (1 - scores[i]) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(padLeft + w, padV + h)
      ..lineTo(padLeft, padV + h)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(padLeft, 0, w, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < scores.length; i++) {
      final x = padLeft + (i / (scores.length - 1)) * w;
      final y = padV + (1 - scores[i]) * h;
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 1.8, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthTrendPainter old) =>
      old.points != points || old.color != color;
}
