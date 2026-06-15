import 'package:flutter/material.dart';

import '../core/constants/catalog.dart';
import '../core/utils/mood_stats.dart';
import 'mood_face_icon.dart';
import 'mood_pentagon.dart';

/// 五芒星雷达图：点击表情跳跃，并在图上高亮该心情的条数。
class MoodRadarChart extends StatefulWidget {
  const MoodRadarChart({
    super.key,
    required this.scores,
    required this.counts,
    this.size = 240,
    this.gender,
  });

  final Map<String, double> scores;
  final Map<String, int> counts;
  final double size;
  final String? gender;

  static const _faceLabelSize = 48.0;
  static const _tapTargetSize = 56.0;

  @override
  State<MoodRadarChart> createState() => _MoodRadarChartState();
}

class _MoodRadarChartState extends State<MoodRadarChart> {
  String? _selectedMoodId;

  void _onMoodTap(MoodOption mood) {
    setState(() {
      _selectedMoodId = _selectedMoodId == mood.id ? null : mood.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final chartSize = Size(size, size);
    final center = Offset(size / 2, size / 2);
    final labelRadius = size * 0.48;
    final selected = _selectedMoodId != null
        ? moodById(_selectedMoodId!)
        : null;
    final selectedCount = _selectedMoodId != null
        ? widget.counts[_selectedMoodId!] ?? 0
        : 0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: chartSize,
            painter: _MoodRadarPainter(
              scores: widget.scores,
              counts: widget.counts,
              selectedMoodId: _selectedMoodId,
            ),
          ),
          if (selected != null)
            _MoodCountBadge(
              mood: selected,
              count: selectedCount,
            ),
          for (var i = 0; i < 5; i++)
            _MoodVertexFace(
              mood: moodById(moodPentagonOrder[i]),
              anchor: moodPentagonVertex(center, labelRadius, i),
              faceSize: MoodRadarChart._faceLabelSize,
              tapSize: MoodRadarChart._tapTargetSize,
              count: widget.counts[moodPentagonOrder[i]] ?? 0,
              gender: widget.gender,
              selected: _selectedMoodId == moodPentagonOrder[i],
              onTap: () => _onMoodTap(moodById(moodPentagonOrder[i])),
            ),
        ],
      ),
    );
  }
}

class _MoodCountBadge extends StatelessWidget {
  const _MoodCountBadge({
    required this.mood,
    required this.count,
  });

  final MoodOption mood;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mood.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mood.color.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: mood.color.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mood.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: mood.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count > 0 ? '$count 条' : '暂无记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: mood.color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodVertexFace extends StatefulWidget {
  const _MoodVertexFace({
    required this.mood,
    required this.anchor,
    required this.faceSize,
    required this.tapSize,
    required this.count,
    required this.selected,
    required this.onTap,
    this.gender,
  });

  final MoodOption mood;
  final Offset anchor;
  final double faceSize;
  final double tapSize;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final String? gender;

  @override
  State<_MoodVertexFace> createState() => _MoodVertexFaceState();
}

class _MoodVertexFaceState extends State<_MoodVertexFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.32), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.32, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final half = widget.tapSize / 2;
    return Positioned(
      left: widget.anchor.dx - half,
      top: widget.anchor.dy - half,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleTap,
          child: SizedBox(
            width: widget.tapSize,
            height: widget.tapSize,
            child: Center(
              child: AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounce.value,
                    child: child,
                  );
                },
                child: DecoratedBox(
                  decoration: widget.selected
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.mood.color.withValues(alpha: 0.16),
                          border: Border.all(
                            color: widget.mood.color.withValues(alpha: 0.55),
                            width: 2,
                          ),
                        )
                      : const BoxDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: MoodFaceIcon(
                      type: widget.mood.faceType,
                      color: widget.mood.color,
                      size: widget.faceSize,
                      strokeWidth: 2,
                      moodId: widget.mood.id,
                      gender: widget.gender,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodRadarPainter extends CustomPainter {
  _MoodRadarPainter({
    required this.scores,
    required this.counts,
    this.selectedMoodId,
  });

  final Map<String, double> scores;
  final Map<String, int> counts;
  final String? selectedMoodId;

  static const _gridTicksPct = [0.0, 20.0, 40.0, 60.0, 80.0, 100.0];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);

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
      final moodId = moodPentagonOrder[i];
      final isSelected = selectedMoodId == moodId;
      final axisPaint = Paint()
        ..color = isSelected
            ? moodById(moodId).color.withValues(alpha: 0.55)
            : const Color(0xFFB0BEC5).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 : 1;
      canvas.drawLine(
        center,
        moodPentagonVertex(center, radius, i),
        axisPaint,
      );
    }

    if (selectedMoodId != null) {
      _paintSelectedAxis(canvas, center, radius, maxCount);
      return;
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
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fill);

    final stroke = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, stroke);
  }

  void _paintSelectedAxis(
    Canvas canvas,
    Offset center,
    double radius,
    int maxCount,
  ) {
    final mood = moodById(selectedMoodId!);
    final index = moodPentagonOrder.indexOf(selectedMoodId!);
    final count = counts[selectedMoodId!] ?? 0;
    final factor = maxCount > 0 ? (count / maxCount).clamp(0.08, 1.0) : 0.08;
    final barRadius = radius * moodRadarRadiusFactor(factor);
    final outer = moodPentagonVertex(center, radius, index);
    final inner = moodPentagonVertex(center, barRadius, index);

    final wedge = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(inner.dx, inner.dy)
      ..lineTo(outer.dx, outer.dy)
      ..close();

    canvas.drawPath(
      wedge,
      Paint()
        ..color = mood.color.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );

    final axisLine = Paint()
      ..color = mood.color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, inner, axisLine);

    canvas.drawCircle(
      inner,
      7,
      Paint()..color = mood.color,
    );
    canvas.drawCircle(
      inner,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MoodRadarPainter oldDelegate) =>
      oldDelegate.scores != scores ||
      oldDelegate.counts != counts ||
      oldDelegate.selectedMoodId != selectedMoodId;
}
