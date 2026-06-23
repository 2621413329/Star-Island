import '../../data/models/mood_check_in_models.dart';
import '../../data/models/profile_models.dart';
import 'growth_system.dart';

/// 本周登岛 / 活跃天数统计（周一至周日）。
class WeekActivity {
  WeekActivity._();

  static const weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime mondayOfWeek([DateTime? reference]) {
    final today = dateOnly(reference ?? DateTime.now());
    return today.subtract(Duration(days: today.weekday - 1));
  }

  static List<DateTime> currentWeekDays([DateTime? reference]) {
    final monday = mondayOfWeek(reference);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static DateTime? parseDate(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// 合并日常日期、心情打卡与今日活跃，用于周视图标记。
  static Set<DateTime> mergeActiveDays({
    required Set<DateTime> momentDates,
    MoodReportCheckIn? checkIn,
    GrowthSummary? summary,
    List<DailyMomentModel> todayMoments = const [],
  }) {
    final result = momentDates.map(dateOnly).toSet();

    for (final day in checkIn?.weekDays ?? const <WeekCheckInDay>[]) {
      if (!day.checkedIn) continue;
      final parsed = parseDate(day.date);
      if (parsed != null) result.add(dateOnly(parsed));
    }

    final today = dateOnly(DateTime.now());
    if (summary != null && !summary.isGuest) {
      final moodDone = (summary.todayMood ?? '').trim().isNotEmpty;
      final detailDone = todayMoments.any((moment) {
        final note = (moment.note ?? '').trim();
        return note.length >= GrowthSystem.minDetailNoteLen;
      });
      final aiDone =
          todayMoments.isNotEmpty || (checkIn?.checkedInToday ?? false);
      if (moodDone || detailDone || aiDone) {
        result.add(today);
      }
    }

    return result;
  }

  static int activeDaysInCurrentWeek(
    Set<DateTime> activeDays, [
    DateTime? reference,
  ]) {
    final start = mondayOfWeek(reference);
    final end = start.add(const Duration(days: 7));
    var count = 0;
    for (final d in activeDays) {
      final day = dateOnly(d);
      if (!day.isBefore(start) && day.isBefore(end)) count++;
    }
    return count;
  }

  static String weekdayLabelFor(DateTime day, {required bool isToday}) {
    if (isToday) return '今天';
    return weekdayLabels[day.weekday - 1];
  }
}
