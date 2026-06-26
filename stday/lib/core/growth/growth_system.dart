import '../../data/models/profile_models.dart';
import 'island_unlock_catalog.dart';
import '../utils/moment_tags.dart';

/// 与后端 `growth_points_service` 规则一致的客户端成长计算（离线兜底）。
class GrowthSystem {
  GrowthSystem._();

  static const minDetailNoteLen = 10;
  static const maxLevel = 20;
  static const maxGrowthValue = 2700;

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

  /// Lv1–Lv20 称号。
  static const levelTitles = <int, String>{
    1: '初心者',
    2: '探索者',
    3: '记录者',
    4: '成长者',
    5: '践行者',
    6: '学习者',
    7: '开拓者',
    8: '积累者',
    9: '进阶者',
    10: '领航者',
    11: '思考者',
    12: '创造者',
    13: '坚持者',
    14: '影响者',
    15: '追光者',
    16: '远行者',
    17: '筑梦者',
    18: '星辰使者',
    19: '群岛守护者',
    20: '岛屿传说',
  };

  /// 到达该等级所需的累计成长值（index 0 = Lv1）。
  /// 满勤约 90 天（3 个月）可达 Lv20（≈2480 成长值，含连续与周奖励）。
  static const levelCumulativeXp = <int>[
    0,
    91,
    199,
    313,
    433,
    556,
    681,
    810,
    941,
    1073,
    1208,
    1344,
    1482,
    1621,
    1761,
    1903,
    2045,
    2189,
    2334,
    2480,
    2700,
  ];

  /// 每级升级所需成长值（Lv1→Lv2 … Lv19→Lv20）。
  static const levelXpRequirements = <int>[
    91,
    108,
    114,
    120,
    123,
    125,
    129,
    131,
    132,
    135,
    136,
    138,
    139,
    140,
    142,
    142,
    144,
    145,
    146,
    220,
  ];

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

    return enrich(
      GrowthSummary(
        growthValue: growthValue,
        level: 1,
        levelTitle: levelTitle(1),
        streakDays: streak,
        maxStreakDays: maxStreak,
        nextLevel: 2,
        nextLevelTitle: levelTitle(2),
        xpIntoLevel: 0,
        xpForNextLevel: levelXpRequirements.first,
        islandStage: 1,
        unlockLabel: IslandUnlockCatalog.unlockSummaryForLevel(1),
        todayMood: profileTodayMood,
        todayWeatherLabel: moodWeatherLabel(profileTodayMood),
        isGuest: false,
      ),
    );
  }

  /// 根据成长值重算等级、称号与进度（服务端/本地统一口径）。
  static GrowthSummary enrich(GrowthSummary summary) {
    final level = resolveLevel(summary.growthValue);
    final progress = nextLevelProgress(summary.growthValue, level);
    return GrowthSummary(
      growthValue: summary.growthValue,
      level: level,
      levelTitle: levelTitle(level),
      streakDays: summary.streakDays,
      maxStreakDays: summary.maxStreakDays,
      nextLevel: progress.$1,
      nextLevelTitle: progress.$2,
      xpIntoLevel: progress.$3,
      xpForNextLevel: progress.$4,
      islandStage: level,
      unlockLabel: IslandUnlockCatalog.unlockSummaryForLevel(level),
      todayMood: summary.todayMood,
      todayWeatherLabel: summary.todayWeatherLabel,
      isGuest: summary.isGuest,
    );
  }

  static int resolveLevel(int growthValue) {
    var level = 1;
    for (var i = 1; i < levelCumulativeXp.length; i++) {
      if (growthValue >= levelCumulativeXp[i]) {
        level = i + 1;
      } else {
        break;
      }
    }
    return level.clamp(1, maxLevel);
  }

  static String levelTitle(int level) =>
      levelTitles[level.clamp(1, maxLevel)] ?? levelTitles[1]!;

  static int cumulativeXpForLevel(int level) =>
      levelCumulativeXp[(level.clamp(1, maxLevel) - 1)];

  static (int?, String?, int, int?) nextLevelProgress(int growthValue, int level) {
    if (level >= maxLevel) {
      final current = cumulativeXpForLevel(maxLevel);
      return (null, null, growthValue - current, null);
    }
    final current = cumulativeXpForLevel(level);
    final next = level + 1;
    final span = levelXpRequirements[level - 1];
    return (next, levelTitle(next), growthValue - current, span);
  }

  static double levelProgressRatio(GrowthSummary summary) {
    final need = summary.xpForNextLevel;
    if (need == null || need <= 0 || summary.nextLevel == null) return 1;
    return (summary.xpIntoLevel / need).clamp(0.0, 1.0);
  }

  static int levelProgressPercent(GrowthSummary summary) =>
      (levelProgressRatio(summary) * 100).round();

  static int xpRemainingToNextLevel(GrowthSummary summary) {
    final need = summary.xpForNextLevel;
    if (need == null || summary.nextLevel == null) return 0;
    return (need - summary.xpIntoLevel).clamp(0, need);
  }

  static String levelDisplayLabel(GrowthSummary summary) =>
      '成长等级：Lv.${summary.level} ${summary.levelTitle}';

  /// 欢迎页顶部仅展示称号。
  static String levelTitleOnly(GrowthSummary summary) => summary.levelTitle;

  /// 今日状态：`{伙伴名} {心情天气}`。
  static String todayCompanionStatusLabel({
    required GrowthSummary summary,
    required String companionName,
  }) {
    return '$companionName ${summary.todayWeatherLabel}';
  }

  static String nextLevelDistanceLabel(GrowthSummary summary) {
    final next = summary.nextLevel;
    final nextTitle = summary.nextLevelTitle;
    if (next == null || nextTitle == null) {
      return '你已成为岛屿传说';
    }
    return '距离 Lv.$next $nextTitle\n还需 ${xpRemainingToNextLevel(summary)} 成长值';
  }

  static String compactNextLevelLabel(GrowthSummary summary) {
    final next = summary.nextLevel;
    final nextTitle = summary.nextLevelTitle;
    if (next == null || nextTitle == null) return '已满级 · 岛屿传说';
    return '距离 Lv.$next $nextTitle · 还需 ${xpRemainingToNextLevel(summary)} 成长值';
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

  double get levelProgressRatio => GrowthSystem.levelProgressRatio(this);

  int get levelProgressPercent => GrowthSystem.levelProgressPercent(this);

  int get xpRemainingToNextLevel => GrowthSystem.xpRemainingToNextLevel(this);

  factory GrowthSummary.guest() => const GrowthSummary(
        growthValue: 0,
        level: 1,
        levelTitle: '初心者',
        streakDays: 0,
        maxStreakDays: 0,
        nextLevel: 2,
        nextLevelTitle: '探索者',
        xpIntoLevel: 0,
        xpForNextLevel: 100,
        islandStage: 1,
        unlockLabel: '',
        todayWeatherLabel: '☀ 平静',
        isGuest: true,
      );

  factory GrowthSummary.fromJson(Map<String, dynamic> json) {
    return GrowthSystem.enrich(
      GrowthSummary(
        growthValue: json['growth_value'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        levelTitle: json['level_title'] as String? ?? '初心者',
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
      ),
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
