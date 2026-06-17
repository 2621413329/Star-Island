import '../../data/models/profile_models.dart';
import '../utils/moment_tags.dart';

/// 与后端 `growth_points_service` 规则一致的客户端成长计算（离线兜底）。
class GrowthSystem {
  static const minDetailNoteLen = 10;

  static const streakMilestoneXp = <int, int>{
    2: 5,
    3: 10,
    7: 20,
    14: 30,
    30: 50,
    60: 100,
    100: 150,
    365: 500,
  };

  /// 下一个尚未达到过的连续打卡里程碑（天数, 奖励）。
  static (int days, int xp)? nextUnclaimedStreakMilestone({
    required int maxStreakDays,
  }) {
    for (final days in streakMilestoneXp.keys.toList()..sort()) {
      if (maxStreakDays < days) {
        return (days, streakMilestoneXp[days]!);
      }
    }
    return null;
  }

  /// 连续打卡里程碑右侧文案：优先展示「明日登录 +X」，否则展示距下一里程碑的天数。
  static String streakMilestoneHint({
    required int currentStreak,
    required int maxStreakDays,
    required bool activeToday,
  }) {
    if (activeToday) {
      final tomorrowStreak = currentStreak + 1;
      final tomorrowXp = streakMilestoneXp[tomorrowStreak];
      if (tomorrowXp != null && maxStreakDays < tomorrowStreak) {
        return '明日登录 +$tomorrowXp';
      }
    }
    final next = nextUnclaimedStreakMilestone(maxStreakDays: maxStreakDays);
    if (next == null) return '里程碑已全部达成';
    final (milestoneDays, xp) = next;
    if (activeToday) {
      final daysUntil = milestoneDays - currentStreak;
      if (daysUntil <= 1) return '明日登录 +$xp';
      return '再连续$daysUntil天 +$xp';
    }
    return '连续$milestoneDays天 +$xp';
  }

  static const levelThresholds = <int, String>{
    0: '漂流者',
    25: '登岛者',
    55: '守望者',
    95: '探索者',
    145: '建造者',
    205: '追光者',
    275: '灯塔守护者',
    355: '星海旅人',
    445: '梦想岛主',
    545: '成长观察者',
  };

  static const unlockLabels = <int, String>{
    1: '荒岛草地',
    2: '小树苗',
    3: '发光石',
    4: '花丛',
    5: '木屋',
    6: '风车',
    7: '灯塔',
    8: '夜空星光',
    9: '岛屿扩建',
    10: '成长纪念馆',
  };

  static GrowthSummary compute({
    required List<DailyMomentModel> moments,
    String? profileTodayMood,
    Set<DateTime>? aiSummaryDays,
  }) {
    final today = _calendar(DateTime.now());
    final dayMap = <DateTime, _DayAct>{};

    for (final m in moments) {
      final d = _calendar(m.momentDate);
      final act = dayMap.putIfAbsent(d, () => _DayAct());
      act.mood = true;
      // 写今日故事时会自动整理当日总结，有故事即视为完成。
      act.ai = true;
      final note = (m.note ?? '').trim();
      if (note.length >= minDetailNoteLen && momentHasGrowthTags(m)) {
        act.detail = true;
      }
    }

    if (aiSummaryDays != null) {
      for (final d in aiSummaryDays) {
        dayMap.putIfAbsent(_calendar(d), () => _DayAct()).ai = true;
      }
    }

    if (profileTodayMood != null && profileTodayMood.isNotEmpty) {
      dayMap.putIfAbsent(today, () => _DayAct()).mood = true;
    }

    var dailyXp = 0;
    for (final act in dayMap.values) {
      if (act.mood) dailyXp += 10;
      if (act.detail) dailyXp += 5;
      if (act.ai) dailyXp += 5;
    }

    final days = dayMap.keys.toList();
    final maxStreak = _maxStreak(days);
    final streak = _currentStreak(days, today);
    var streakBonus = 0;
    for (final e in streakMilestoneXp.entries) {
      if (maxStreak >= e.key) streakBonus += e.value;
    }
    final weeklyBonus = _weeklyBonus(days);
    final growthValue = dailyXp + streakBonus + weeklyBonus;

    final level = resolveLevel(growthValue);
    final title = levelTitle(level);
    final progress = nextLevelProgress(growthValue, level);

    return GrowthSummary(
      growthValue: growthValue,
      level: level,
      levelTitle: title,
      streakDays: streak,
      maxStreakDays: maxStreak,
      nextLevel: progress.$1,
      nextLevelTitle: progress.$2,
      xpIntoLevel: progress.$3,
      xpForNextLevel: progress.$4,
      islandStage: level,
      unlockLabel: unlockLabels[level] ?? '',
      todayMood: profileTodayMood,
      todayWeatherLabel: moodWeatherLabel(profileTodayMood),
      isGuest: false,
    );
  }

  static int resolveLevel(int growthValue) {
    final keys = levelThresholds.keys.toList()..sort();
    var level = 1;
    for (var i = 0; i < keys.length; i++) {
      if (growthValue >= keys[i]) level = i + 1;
    }
    return level.clamp(1, 10);
  }

  static String levelTitle(int level) {
    final keys = levelThresholds.keys.toList()..sort();
    final idx = (level - 1).clamp(0, keys.length - 1);
    return levelThresholds[keys[idx]]!;
  }

  static (int?, String?, int, int?) nextLevelProgress(int growthValue, int level) {
    final keys = levelThresholds.keys.toList()..sort();
    if (level >= keys.length) {
      return (null, null, growthValue - keys.last, null);
    }
    final current = keys[level - 1];
    final next = keys[level];
    return (level + 1, levelThresholds[next], growthValue - current, next - current);
  }

  static String moodWeatherLabel(String? mood) {
    return switch (mood) {
      'happy' => '☀ 超开心',
      'calm' => '☀ 平静',
      'thinking' => '✨ 思考',
      'sad' => '🌫 低落',
      'angry' => '🌧 生气',
      _ => '☀ 平静',
    };
  }

  static int _weeklyBonus(List<DateTime> days) {
    if (days.isEmpty) return 0;
    final byWeek = <String, Set<DateTime>>{};
    for (final d in days) {
      final iso = _isoWeekKey(d);
      byWeek.putIfAbsent(iso, () => {}).add(d);
    }
    var total = 0;
    for (final set in byWeek.values) {
      final n = set.length;
      if (n >= 7) {
        total += 50;
      } else if (n >= 5) {
        total += 20;
      }
    }
    return total;
  }

  static String _isoWeekKey(DateTime d) {
    final start = DateTime(d.year, 1, 1);
    final week = (d.difference(start).inDays / 7).floor();
    return '${d.year}-$week';
  }

  static int _maxStreak(List<DateTime> days) {
    if (days.isEmpty) return 0;
    final sorted = days.map(_calendar).toSet().toList()..sort();
    var best = 1;
    var cur = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 1;
      }
    }
    return best;
  }

  static int _currentStreak(List<DateTime> days, DateTime today) {
    final set = days.map(_calendar).toSet();
    if (set.isEmpty) return 0;
    var cursor = today;
    if (!set.contains(cursor)) {
      cursor = today.subtract(const Duration(days: 1));
      if (!set.contains(cursor)) return 0;
    }
    var streak = 0;
    while (set.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _calendar(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _DayAct {
  bool mood = false;
  bool detail = false;
  bool ai = false;
}

class GrowthSummary {
  const GrowthSummary({
    required this.growthValue,
    required this.level,
    required this.levelTitle,
    required this.streakDays,
    required this.maxStreakDays,
    this.nextLevel,
    this.nextLevelTitle,
    required this.xpIntoLevel,
    this.xpForNextLevel,
    required this.islandStage,
    required this.unlockLabel,
    this.todayMood,
    required this.todayWeatherLabel,
    required this.isGuest,
  });

  final int growthValue;
  final int level;
  final String levelTitle;
  final int streakDays;
  final int maxStreakDays;
  final int? nextLevel;
  final String? nextLevelTitle;
  final int xpIntoLevel;
  final int? xpForNextLevel;
  final int islandStage;
  final String unlockLabel;
  final String? todayMood;
  final String todayWeatherLabel;
  final bool isGuest;

  factory GrowthSummary.guest() => const GrowthSummary(
        growthValue: 0,
        level: 1,
        levelTitle: '漂流者',
        streakDays: 0,
        maxStreakDays: 0,
        nextLevel: 2,
        nextLevelTitle: '登岛者',
        xpIntoLevel: 0,
        xpForNextLevel: 25,
        islandStage: 1,
        unlockLabel: '荒岛草地',
        todayWeatherLabel: '☀ 平静',
        isGuest: true,
      );

  factory GrowthSummary.fromJson(Map<String, dynamic> json) {
    return GrowthSummary(
      growthValue: json['growth_value'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      levelTitle: json['level_title'] as String? ?? '漂流者',
      streakDays: json['streak_days'] as int? ?? 0,
      maxStreakDays: json['max_streak_days'] as int? ?? 0,
      nextLevel: json['next_level'] as int?,
      nextLevelTitle: json['next_level_title'] as String?,
      xpIntoLevel: json['xp_into_level'] as int? ?? 0,
      xpForNextLevel: json['xp_for_next_level'] as int?,
      islandStage: json['island_stage'] as int? ?? 1,
      unlockLabel: json['unlock_label'] as String? ?? '',
      todayMood: json['today_mood'] as String?,
      todayWeatherLabel: json['today_weather_label'] as String? ?? '☀ 平静',
      isGuest: false,
    );
  }
}

/// 岛屿可视化阶段（与等级对齐）。
class IslandGrowthStage {
  const IslandGrowthStage(this.level);

  final int level;

  bool get showSapling => level >= 2;
  bool get showGlowCore => level >= 3;
  bool get showFlowers => level >= 4;
  bool get showCabin => level >= 5;
  bool get showWindmill => level >= 6;
  bool get showLighthouse => level >= 7;
  bool get showStarfield => level >= 8;
  bool get showSecondIslet => level >= 9;
  bool get showMemorial => level >= 10;
}
