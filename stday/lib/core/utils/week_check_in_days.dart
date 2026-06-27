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

/// 与成长轨迹「连续记录天数」一致的本周时间轴（周一至周日）。
List<WeekCheckInDay> defaultWeekCheckInDays() {
  return MoodReportCheckIn.empty.weekDays;
}

/// 「我的等级」近 7 天登岛：固定周一到周日，合并服务端打卡与本地活跃。
List<WeekCheckInDay> mondayIslandVisitWeekDays({
  MoodReportCheckIn? checkIn,
  required Set<DateTime> momentDates,
  required bool todayActive,
}) {
  final backendChecked = <String>{
    for (final day in checkIn?.weekDays ?? const <WeekCheckInDay>[])
      if (day.checkedIn) day.date,
  };
  final baseWeekDays = defaultWeekCheckInDays().map((day) {
    if (backendChecked.contains(day.date) && !day.checkedIn) {
      return WeekCheckInDay(
        date: day.date,
        weekdayLabel: day.weekdayLabel,
        checkedIn: true,
        isToday: day.isToday,
        isFuture: day.isFuture,
      );
    }
    return day;
  }).toList();
  return mergeIslandVisitWeekDays(
    baseWeekDays: baseWeekDays,
    momentDates: momentDates,
    todayActive: todayActive,
  );
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
