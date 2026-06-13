import 'package:flutter/material.dart';

import '../core/constants/catalog.dart';
import '../core/utils/mood_stats.dart';
import 'mood_face_icon.dart';
import 'mood_pentagon.dart';

/// 五芒星雷达图：外圈为心情表情，中心不显示刻度文字。
class MoodRadarChart extends StatelessWidget {
  const MoodRadarChart({
    super.key,
    required this.scores,
    required this.counts,
    this.size = 240,
    this.gender,
    this.onMoodTap,
  });

  final Map<String, double> scores;
  final Map<String, int> counts;
  final double size;
  final String? gender;
  final void Function(MoodOption mood, int count)? onMoodTap;

  static const _faceLabelSize = 30.0;
  static const _tapTargetSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final chartSize = Size(size, size);
    final center = Offset(size / 2, size / 2);
    final labelRadius = size * 0.46;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: chartSize,
            painter: _MoodRadarPainter(scores: scores),
          ),
          for (var i = 0; i < 5; i++)
            _MoodVertexFace(
              mood: moodById(moodPentagonOrder[i]),
              anchor: moodPentagonVertex(center, labelRadius, i),
              faceSize: _faceLabelSize,
              tapSize: _tapTargetSize,
              count: counts[moodPentagonOrder[i]] ?? 0,
              gender: gender,
              onTap: onMoodTap,
            ),
        ],
      ),
    );
  }
}

class _MoodVertexFace extends StatelessWidget {
  const _MoodVertexFace({
    required this.mood,
    required this.anchor,
    required this.faceSize,
    required this.tapSize,
    required this.count,
    this.gender,
    this.onTap,
  });

  final MoodOption mood;
  final Offset anchor;
  final double faceSize;
  final double tapSize;
  final int count;
  final String? gender;
  final void Function(MoodOption mood, int count)? onTap;

  @override
  Widget build(BuildContext context) {
    final half = tapSize / 2;
    return Positioned(
      left: anchor.dx - half,
      top: anchor.dy - half,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap == null ? null : () => onTap!(mood, count),
          child: SizedBox(
            width: tapSize,
            height: tapSize,
            child: Center(
              child: MoodFaceIcon(
                type: mood.faceType,
                color: mood.color,
                size: faceSize,
                strokeWidth: 2,
                moodId: mood.id,
                gender: gender,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodRadarPainter extends CustomPainter {
  _MoodRadarPainter({required this.scores});

  final Map<String, double> scores;

  static const _gridTicksPct = [0.0, 20.0, 40.0, 60.0, 80.0, 100.0];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;

    final gridPaint = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final tick in _gridTicksPct) {
      final r = radius * moodRadarRadiusFactor(tick / 100);
      if (r <= 0) continue;
      canvas.drawPath(moodPentagonPath(center, r), gridPaint);
    }

    for (var i = 0; i < 5; i++) {
      canvas.drawLine(center, moodPentagonVertex(center, radius, i), gridPaint);
    }

    final hasData = scores.values.any((v) => v > 0);
    if (!hasData) return;

    final dataPath = Path();
    for (var i = 0; i < 5; i++) {
      final moodId = moodPentagonOrder[i];
      final score = (scores[moodId] ?? 0).clamp(0.0, 1.0);
      final r = radius * moodRadarRadiusFactor(score);
      final p = moodPentagonVertex(center, r, i);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    final fill = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fill);

    final stroke = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, stroke);

    for (var i = 0; i < 5; i++) {
      final moodId = moodPentagonOrder[i];
      final mood = moodById(moodId);
      final score = (scores[moodId] ?? 0).clamp(0.0, 1.0);
      if (score <= 0) continue;
      final p = moodPentagonVertex(center, radius * moodRadarRadiusFactor(score), i);
      canvas.drawCircle(p, 5, Paint()..color = mood.color);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodRadarPainter oldDelegate) =>
      oldDelegate.scores != scores;
}
