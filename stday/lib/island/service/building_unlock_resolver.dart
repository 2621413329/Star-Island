import '../../core/growth/growth_system.dart';
import '../../data/models/profile_models.dart';
import '../config/growth_island_configs.dart';

/// 根据成长记录推算建筑首次解锁日期。
class BuildingUnlockResolver {
  BuildingUnlockResolver._();

  static int? _requiredScoreForLevel(int unlockLevel) {
    for (final config in GrowthIslandConfigs.levels) {
      if (config.level == unlockLevel) return config.requiredGrowthScore;
    }
    return null;
  }

  static DateTime? resolveUnlockDate({
    required int unlockLevel,
    required List<DailyMomentModel> moments,
    String? profileTodayMood,
  }) {
    final targetScore = _requiredScoreForLevel(unlockLevel);
    if (targetScore == null) return null;
    if (targetScore <= 0) {
      if (moments.isEmpty) return DateTime.now();
      final earliest = moments.map((m) => m.momentDate).reduce(
            (a, b) => a.isBefore(b) ? a : b,
          );
      return DateTime(earliest.year, earliest.month, earliest.day);
    }

    if (moments.isEmpty) return null;

    final dayKeys = <DateTime>{};
    for (final moment in moments) {
      final d = moment.momentDate;
      dayKeys.add(DateTime(d.year, d.month, d.day));
    }
    final sortedDays = dayKeys.toList()..sort();

    for (final day in sortedDays) {
      final cumulative = moments
          .where((m) => !_isAfterDay(m.momentDate, day))
          .toList(growable: false);
      final mood = _isSameDay(day, DateTime.now()) ? profileTodayMood : null;
      final summary = GrowthSystem.compute(
        moments: cumulative,
        profileTodayMood: mood,
      );
      if (summary.growthValue >= targetScore) {
        return day;
      }
    }
    return null;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isAfterDay(DateTime value, DateTime day) {
    final v = DateTime(value.year, value.month, value.day);
    return v.isAfter(day);
  }
}
