import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 预警页：日期范围（默认含今日在内的近 3 天）。
class AlertDateRange {
  const AlertDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  AlertDateRange normalized() {
    if (!start.isAfter(end)) return this;
    return AlertDateRange(start: end, end: start);
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

AlertDateRange defaultAlertRange() {
  final today = dateOnly(DateTime.now());
  return AlertDateRange(start: today.subtract(const Duration(days: 2)), end: today);
}

final alertsDateRangeProvider = StateProvider<AlertDateRange>((ref) => defaultAlertRange());

/// 心情页：独立单日选择（默认昨日）。
/// 心情页：按学生姓名筛选（空字符串表示不过滤）。
final moodStudentSearchProvider = StateProvider<String>((ref) => '');

final moodSelectedDateProvider = StateProvider<DateTime>((ref) {
  final today = dateOnly(DateTime.now());
  return today.subtract(const Duration(days: 1));
});

String formatReportDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

bool isYesterday(DateTime selected) {
  final today = dateOnly(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));
  return dateOnly(selected) == yesterday;
}

bool isToday(DateTime selected) => dateOnly(selected) == dateOnly(DateTime.now());

bool isSameDay(DateTime a, DateTime b) => dateOnly(a) == dateOnly(b);
