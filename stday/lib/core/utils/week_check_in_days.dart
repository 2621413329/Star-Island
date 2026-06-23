import '../../data/models/mood_check_in_models.dart';

DateTime? parseCalendarDate(String raw) {
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

bool sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// 与成长轨迹「连续记录天数」一致的本周时间轴（周日至周六）。
List<WeekCheckInDay> defaultWeekCheckInDays() {
  return MoodReportCheckIn.empty.weekDays;
}

/// 合并心情打卡、日常记录与今日实时活跃，用于「近 7 天登岛」等展示。
List<WeekCheckInDay> mergeIslandVisitWeekDays({
  required List<WeekCheckInDay> baseWeekDays,
  required Set<DateTime> momentDates,
  required bool todayActive,
}) {
  return baseWeekDays.map((day) {
    final date = parseCalendarDate(day.date);
    if (date == null) return day;

    final hasMoment = momentDates.any((d) => sameCalendarDay(d, date));
    final checkedIn =
        day.checkedIn || hasMoment || (day.isToday && todayActive);
    if (checkedIn == day.checkedIn) return day;

    return WeekCheckInDay(
      date: day.date,
      weekdayLabel: day.weekdayLabel,
      checkedIn: checkedIn,
      isToday: day.isToday,
      isFuture: day.isFuture,
    );
  }).toList();
}
