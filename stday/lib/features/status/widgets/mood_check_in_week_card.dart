import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../data/models/mood_check_in_models.dart';
import '../../../design_system/island_decorations.dart';
import 'week_streak_track.dart';

/// 连续记录天数：本周打卡时间轴。
class MoodCheckInWeekCard extends StatelessWidget {
  const MoodCheckInWeekCard({
    super.key,
    required this.palette,
    required this.checkIn,
  });

  final MoodPalette palette;
  final MoodReportCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final days = checkIn.weekDays.isNotEmpty
        ? checkIn.weekDays
        : MoodReportCheckIn.empty.weekDays;
    final streak = checkIn.currentStreak;

    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '连续记录天数',
                  style: appTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '连续 $streak 天',
                  style: appTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '在今日日常整理心情即可完成当日打卡',
            style: appTextStyle(
              fontSize: 11,
              color: palette.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          WeekStreakTrack(
            days: days,
            palette: palette,
            trailingStreak: streak,
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: palette.primary.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '最高连续记录天数：${checkIn.maxStreak}',
                style: appTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.primary.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              Text(
                '累计 ${checkIn.totalCheckInDays} 天',
                style: appTextStyle(
                  fontSize: 12,
                  color: palette.primary.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
