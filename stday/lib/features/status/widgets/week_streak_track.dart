import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../data/models/mood_check_in_models.dart';

/// 周打卡时间轴（与成长轨迹「连续记录天数」同款样式）。
class WeekStreakTrack extends StatelessWidget {
  const WeekStreakTrack({
    super.key,
    required this.days,
    required this.palette,
    this.trailingStreak,
    this.height = 72,
  });

  final List<WeekCheckInDay> days;
  final MoodPalette palette;
  final int? trailingStreak;
  final double height;

  @override
  Widget build(BuildContext context) {
    final showTail = trailingStreak != null;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _WeekStreakLinePainter(
              days: days,
              accent: palette.accent,
              trackColor: palette.primaryContainer.withValues(alpha: 0.85),
              includeTrailingSlot: showTail,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: _WeekDayNode(
                      day: days[i],
                      palette: palette,
                      showTodayLabel: days[i].isToday,
                    ),
                  ),
                if (showTail)
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: palette.accent.withValues(alpha: 0.35),
                            ),
                            color: palette.card.withValues(alpha: 0.9),
                          ),
                          child: Text(
                            '${trailingStreak!}',
                            style: appTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeekDayNode extends StatelessWidget {
  const _WeekDayNode({
    required this.day,
    required this.palette,
    required this.showTodayLabel,
  });

  final WeekCheckInDay day;
  final MoodPalette palette;
  final bool showTodayLabel;

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    final muted = palette.primary.withValues(alpha: 0.35);

    Widget circleChild;
    Color? fill;
    Color border = muted;
    double borderW = 1.5;

    if (day.checkedIn) {
      fill = accent;
      border = accent;
      circleChild =
          const Icon(Icons.check_rounded, size: 18, color: Colors.white);
    } else if (day.isToday) {
      border = accent;
      borderW = 2;
      circleChild = Icon(Icons.add_rounded, size: 18, color: accent);
    } else if (day.isFuture) {
      circleChild = Icon(
        Icons.add_rounded,
        size: 16,
        color: muted.withValues(alpha: 0.5),
      );
    } else {
      circleChild = Icon(Icons.add_rounded, size: 16, color: muted);
    }

    final label = showTodayLabel ? '今天' : day.weekdayLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border, width: borderW),
            boxShadow: day.checkedIn
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: circleChild,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: appTextStyle(
            fontSize: 10,
            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
            color:
                day.isToday ? accent : palette.primary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _WeekStreakLinePainter extends CustomPainter {
  _WeekStreakLinePainter({
    required this.days,
    required this.accent,
    required this.trackColor,
    this.includeTrailingSlot = false,
  });

  final List<WeekCheckInDay> days;
  final Color accent;
  final Color trackColor;
  final bool includeTrailingSlot;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    const nodeSize = 34.0;
    const tailWidth = 36.0;
    final trackW = size.width - (includeTrailingSlot ? tailWidth : 0);
    final slot = trackW / days.length;
    final y = nodeSize * 0.5;
    final startX = slot * 0.5;
    final endX = trackW - slot * 0.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), trackPaint);

    final streakPaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < days.length - 1; i++) {
      if (!days[i].checkedIn || !days[i + 1].checkedIn) continue;
      final x0 = slot * i + slot * 0.5;
      final x1 = slot * (i + 1) + slot * 0.5;
      canvas.drawLine(Offset(x0, y), Offset(x1, y), streakPaint);
    }

    for (var i = 0; i < days.length; i++) {
      if (!days[i].checkedIn) continue;
      final cx = slot * i + slot * 0.5;
      canvas.drawCircle(
        Offset(cx, y),
        nodeSize * 0.5 + 2,
        Paint()..color = accent.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeekStreakLinePainter old) {
    return old.days != days ||
        old.accent != accent ||
        old.includeTrailingSlot != includeTrailingSlot;
  }
}
