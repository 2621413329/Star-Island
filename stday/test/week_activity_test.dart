import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/growth/week_activity.dart';
import 'package:stday/data/models/mood_check_in_models.dart';

void main() {
  group('WeekActivity', () {
    test('current week starts on Monday', () {
      final days = WeekActivity.currentWeekDays(DateTime(2026, 6, 22)); // Sunday
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
    });

    test('mergeActiveDays includes mood and check-in today', () {
      final today = WeekActivity.dateOnly(DateTime.now());
      final active = WeekActivity.mergeActiveDays(
        momentDates: const {},
        checkIn: MoodReportCheckIn.empty.copyWith(checkedInToday: true),
        summary: GrowthSummary(
          growthValue: 100,
          level: 2,
          levelTitle: '探索者',
          streakDays: 1,
          maxStreakDays: 1,
          xpIntoLevel: 10,
          xpForNextLevel: 100,
          islandStage: 1,
          unlockLabel: '',
          todayMood: 'thinking',
          todayWeatherLabel: '✨ 思考',
          isGuest: false,
        ),
      );
      expect(active.contains(today), isTrue);
    });

    test('activeDaysInCurrentWeek counts only current week', () {
      final monday = WeekActivity.mondayOfWeek(DateTime(2026, 6, 18)); // Wed
      final active = {
        monday,
        monday.add(const Duration(days: 2)),
        monday.subtract(const Duration(days: 1)),
      };
      expect(WeekActivity.activeDaysInCurrentWeek(active, DateTime(2026, 6, 18)), 2);
    });
  });
}

extension _CheckInCopy on MoodReportCheckIn {
  MoodReportCheckIn copyWith({bool? checkedInToday}) {
    return MoodReportCheckIn(
      currentStreak: currentStreak,
      maxStreak: maxStreak,
      totalCheckInDays: totalCheckInDays,
      checkedInToday: checkedInToday ?? this.checkedInToday,
      todayMomentCount: todayMomentCount,
      reportedMomentCount: reportedMomentCount,
      hasPendingStories: hasPendingStories,
      allSyncedToday: allSyncedToday,
      weekDays: weekDays,
    );
  }
}
