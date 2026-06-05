class WeekCheckInDay {
  const WeekCheckInDay({
    required this.date,
    required this.weekdayLabel,
    required this.checkedIn,
    required this.isToday,
    required this.isFuture,
  });

  final String date;
  final String weekdayLabel;
  final bool checkedIn;
  final bool isToday;
  final bool isFuture;

  factory WeekCheckInDay.fromJson(Map<String, dynamic> json) {
    return WeekCheckInDay(
      date: json['date'] as String? ?? '',
      weekdayLabel: json['weekday_label'] as String? ?? '',
      checkedIn: json['checked_in'] as bool? ?? false,
      isToday: json['is_today'] as bool? ?? false,
      isFuture: json['is_future'] as bool? ?? false,
    );
  }
}

class MoodReportCheckIn {
  const MoodReportCheckIn({
    required this.currentStreak,
    required this.maxStreak,
    required this.totalCheckInDays,
    required this.checkedInToday,
    required this.todayMomentCount,
    required this.reportedMomentCount,
    required this.hasPendingStories,
    required this.allSyncedToday,
    required this.weekDays,
  });

  final int currentStreak;
  final int maxStreak;
  final int totalCheckInDays;
  final bool checkedInToday;
  final int todayMomentCount;
  final int reportedMomentCount;
  final bool hasPendingStories;
  final bool allSyncedToday;
  final List<WeekCheckInDay> weekDays;

  factory MoodReportCheckIn.fromJson(Map<String, dynamic> json) {
    final weekRaw = json['week_days'] as List<dynamic>? ?? [];
    return MoodReportCheckIn(
      currentStreak: json['current_streak'] as int? ?? 0,
      maxStreak: json['max_streak'] as int? ?? 0,
      totalCheckInDays: json['total_check_in_days'] as int? ?? 0,
      checkedInToday: json['checked_in_today'] as bool? ?? false,
      todayMomentCount: json['today_moment_count'] as int? ?? 0,
      reportedMomentCount: json['reported_moment_count'] as int? ?? 0,
      hasPendingStories: json['has_pending_stories'] as bool? ?? false,
      allSyncedToday: json['all_synced_today'] as bool? ?? false,
      weekDays: weekRaw
          .map((e) => WeekCheckInDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<WeekCheckInDay> _defaultWeekDays() {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.subtract(Duration(days: today.weekday % 7));
    return List.generate(7, (i) {
      final d = sunday.add(Duration(days: i));
      final isToday = d == today;
      return WeekCheckInDay(
        date:
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        weekdayLabel: labels[d.weekday - 1],
        checkedIn: false,
        isToday: isToday,
        isFuture: d.isAfter(today),
      );
    });
  }

  static final empty = MoodReportCheckIn(
    currentStreak: 0,
    maxStreak: 0,
    totalCheckInDays: 0,
    checkedInToday: false,
    todayMomentCount: 0,
    reportedMomentCount: 0,
    hasPendingStories: false,
    allSyncedToday: false,
    weekDays: _defaultWeekDays(),
  );
}

/// 今日心情整理按钮文案（弱化「上传」）。
class TodayMoodRecapAction {
  const TodayMoodRecapAction({
    required this.label,
    required this.enabled,
    required this.highlight,
  });

  final String label;
  final bool enabled;
  final bool highlight;

  static TodayMoodRecapAction resolve(MoodReportCheckIn checkIn) {
    if (checkIn.todayMomentCount == 0) {
      return const TodayMoodRecapAction(
        label: '先记录故事，再整理心情',
        enabled: false,
        highlight: false,
      );
    }
    if (checkIn.allSyncedToday) {
      return const TodayMoodRecapAction(
        label: '今日心情已全部记下',
        enabled: false,
        highlight: false,
      );
    }
    if (checkIn.hasPendingStories && checkIn.checkedInToday) {
      final extra = checkIn.todayMomentCount - checkIn.reportedMomentCount;
      final hint = extra > 0 ? '（+$extra 条新故事）' : '';
      return TodayMoodRecapAction(
        label: '有新故事，再整理一次$hint',
        enabled: true,
        highlight: true,
      );
    }
    return const TodayMoodRecapAction(
      label: '整理今日心情',
      enabled: true,
      highlight: true,
    );
  }
}
