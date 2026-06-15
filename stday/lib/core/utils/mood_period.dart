import '../../data/models/profile_models.dart';
import 'moment_date_groups.dart';

/// 成长轨迹页独立的心情周期筛选（与今日记录日期筛选解耦）。
enum MoodStatusPeriod {
  today,
  week,
  month,
  year,
}

extension MoodStatusPeriodX on MoodStatusPeriod {
  String get label {
    switch (this) {
      case MoodStatusPeriod.today:
        return '今天';
      case MoodStatusPeriod.week:
        return '本周';
      case MoodStatusPeriod.month:
        return '本月';
      case MoodStatusPeriod.year:
        return '本年度';
    }
  }

  String get summaryTitle {
    switch (this) {
      case MoodStatusPeriod.today:
        return '今日概览';
      case MoodStatusPeriod.week:
        return '本周概览';
      case MoodStatusPeriod.month:
        return '本月概览';
      case MoodStatusPeriod.year:
        return '本年度概览';
    }
  }

  String get apiValue {
    switch (this) {
      case MoodStatusPeriod.today:
        return 'today';
      case MoodStatusPeriod.week:
        return 'week';
      case MoodStatusPeriod.month:
        return 'month';
      case MoodStatusPeriod.year:
        return 'year';
    }
  }

  static MoodStatusPeriod fromApi(String value) {
    switch (value) {
      case 'week':
        return MoodStatusPeriod.week;
      case 'month':
        return MoodStatusPeriod.month;
      case 'year':
        return MoodStatusPeriod.year;
      default:
        return MoodStatusPeriod.today;
    }
  }

  DateTime periodStart(DateTime anchor) {
    final d = DateTime(anchor.year, anchor.month, anchor.day);
    switch (this) {
      case MoodStatusPeriod.today:
        return d;
      case MoodStatusPeriod.week:
        return d.subtract(Duration(days: d.weekday - 1));
      case MoodStatusPeriod.month:
        return DateTime(d.year, d.month, 1);
      case MoodStatusPeriod.year:
        return DateTime(d.year, 1, 1);
    }
  }

  int get fetchDays {
    switch (this) {
      case MoodStatusPeriod.today:
        return 1;
      case MoodStatusPeriod.week:
        return 7;
      case MoodStatusPeriod.month:
        return 31;
      case MoodStatusPeriod.year:
        return 365;
    }
  }

  bool containsDay(DateTime day, {DateTime? anchor}) {
    final now = anchor ?? DateTime.now();
    final target = DateTime(day.year, day.month, day.day);
    final start = periodStart(now);
    final end = DateTime(now.year, now.month, now.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }
}

bool momentInMoodPeriod(
  DailyMomentModel moment,
  MoodStatusPeriod period, {
  DateTime? anchor,
}) {
  return period.containsDay(momentCalendarDate(moment), anchor: anchor);
}

List<DailyMomentModel> filterMomentsByMoodPeriod(
  List<DailyMomentModel> moments,
  MoodStatusPeriod period, {
  DateTime? anchor,
}) {
  return moments
      .where((m) => momentInMoodPeriod(m, period, anchor: anchor))
      .toList();
}
