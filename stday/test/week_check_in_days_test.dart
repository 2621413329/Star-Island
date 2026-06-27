import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/utils/week_check_in_days.dart';
import 'package:stday/data/models/mood_check_in_models.dart';

void main() {
  test('mergeIslandVisitWeekDays marks today when active', () {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final base = [
      WeekCheckInDay(
        date: date,
        weekdayLabel: '周一',
        checkedIn: false,
        isToday: true,
        isFuture: false,
      ),
    ];

    final merged = mergeIslandVisitWeekDays(
      baseWeekDays: base,
      momentDates: const {},
      todayActive: true,
    );

    expect(merged.first.checkedIn, isTrue);
  });

  test('mergeIslandVisitWeekDays uses moment dates', () {
    final d = DateTime(2026, 6, 18);
    final base = [
      WeekCheckInDay(
        date: '2026-06-18',
        weekdayLabel: '周四',
        checkedIn: false,
        isToday: false,
        isFuture: false,
      ),
    ];

    final merged = mergeIslandVisitWeekDays(
      baseWeekDays: base,
      momentDates: {d},
      todayActive: false,
    );

    expect(merged.first.checkedIn, isTrue);
  });

  test('defaultWeekCheckInDays starts on Monday', () {
    final days = defaultWeekCheckInDays();
    expect(days, hasLength(7));
    expect(days.first.weekdayLabel, '周一');
    expect(days.last.weekdayLabel, '周日');
    expect(days.any((d) => d.isToday), isTrue);
  });
}
