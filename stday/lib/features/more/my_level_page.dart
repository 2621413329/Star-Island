import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/growth/growth_system.dart';
import '../../core/growth/island_unlock_catalog.dart';
import '../../core/growth/level_unlock_preview.dart';
import '../../core/growth/week_activity.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_loading.dart';
import '../../design_system/island_decorations.dart';
import '../../core/utils/moment_tags.dart';
import '../../core/utils/week_check_in_days.dart';
import '../../data/models/mood_check_in_models.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../landing/landing_growth_header.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../landing/landing_island_progress.dart';
import '../status/widgets/week_streak_track.dart';
import 'widgets/more_subpage_header.dart';

final _momentDatesProvider = FutureProvider<Set<DateTime>>((ref) async {
  try {
    final raw =
        await ref.read(appRepositoryProvider).listMomentDates(days: 30);
    return raw.map(_parseDate).whereType<DateTime>().map(WeekActivity.dateOnly).toSet();
  } catch (_) {
    return {};
  }
});

DateTime? _parseDate(String s) {
  final parts = s.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

class MyLevelPage extends ConsumerStatefulWidget {
  const MyLevelPage({super.key, this.scrollToSection});

  /// 进入后滚动到的区块，如 `titles` 表示「等级与称号」。
  final String? scrollToSection;

  @override
  ConsumerState<MyLevelPage> createState() => _MyLevelPageState();
}

class _MyLevelPageState extends ConsumerState<MyLevelPage> {
  final _scrollController = ScrollController();
  final _levelLadderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToSection == 'titles') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLevelLadder());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLevelLadder() {
    final target = _levelLadderKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final growthAsync = ref.watch(growthSummaryProvider);
    final datesAsync = ref.watch(_momentDatesProvider);
    final todayMomentsAsync = ref.watch(todayMomentsProvider);
    final checkInAsync = ref.watch(moodReportCheckInProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MoreSubpageHeader(title: '我的等级'),
              Expanded(
                child: growthAsync.when(
                  loading: () => const MoodCompanionLoadingBody(
                    message: '正在读取你的成长记录…',
                  ),
                  error: (_, __) => _ErrorBody(
                    onRetry: () {
                      ref.invalidate(growthSummaryProvider);
                      ref.invalidate(_momentDatesProvider);
                    },
                  ),
                  data: (summary) {
                    if (widget.scrollToSection == 'titles') {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToLevelLadder(),
                      );
                    }
                    return RefreshIndicator(
                    color: palette.primary,
                    onRefresh: () async {
                      ref.invalidate(growthSummaryProvider);
                      ref.invalidate(_momentDatesProvider);
                      ref.invalidate(todayMomentsProvider);
                      ref.invalidate(moodReportCheckInProvider);
                      await ref.read(growthSummaryProvider.future);
                    },
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.pageHorizontal,
                        8,
                        AppLayout.pageHorizontal,
                        32,
                      ),
                      children: [
                        _StatusCard(summary: summary),
                        const SizedBox(height: AppLayout.sectionGap),
                        _WeekActivityCard(
                          activeDays: WeekActivity.mergeActiveDays(
                            momentDates: datesAsync.valueOrNull ?? const {},
                            checkIn: checkInAsync.valueOrNull,
                            summary: summary,
                            todayMoments:
                                todayMomentsAsync.valueOrNull ?? const [],
                        datesAsync.when(
                          data: (dates) => _WeekActivityCard(
                            palette: palette,
                            activeDays: dates,
                            streakDays: summary.streakDays,
                            checkIn: checkInAsync.valueOrNull,
                            todayMoments: todayMomentsAsync.valueOrNull ?? const [],
                            todayMood: summary.todayMood,
                          ),
                          loading: () => _WeekActivityCard(
                            palette: palette,
                            activeDays: const {},
                            streakDays: summary.streakDays,
                            checkIn: checkInAsync.valueOrNull,
                            todayMoments: todayMomentsAsync.valueOrNull ?? const [],
                            todayMood: summary.todayMood,
                          ),
                          error: (_, __) => _WeekActivityCard(
                            palette: palette,
                            activeDays: const {},
                            streakDays: summary.streakDays,
                            checkIn: checkInAsync.valueOrNull,
                            todayMoments: todayMomentsAsync.valueOrNull ?? const [],
                            todayMood: summary.todayMood,
                          ),
                        ),
                        const SizedBox(height: AppLayout.sectionGap),
                        todayMomentsAsync.when(
                          data: (todayMoments) => _XpGuideCard(
                            palette: palette,
                            summary: summary,
                            activeDays: WeekActivity.mergeActiveDays(
                              momentDates: datesAsync.valueOrNull ?? const {},
                              checkIn: checkInAsync.valueOrNull,
                              summary: summary,
                              todayMoments: todayMoments,
                            ),
                            todayMoments: todayMoments,
                            checkIn: checkInAsync.valueOrNull,
                          ),
                          loading: () => _XpGuideCard(
                            palette: palette,
                            summary: summary,
                            activeDays: WeekActivity.mergeActiveDays(
                              momentDates: datesAsync.valueOrNull ?? const {},
                              checkIn: checkInAsync.valueOrNull,
                              summary: summary,
                            ),
                            todayMoments: const [],
                            checkIn: checkInAsync.valueOrNull,
                            loading: true,
                          ),
                          error: (_, __) => _XpGuideCard(
                            palette: palette,
                            summary: summary,
                            activeDays: WeekActivity.mergeActiveDays(
                              momentDates: datesAsync.valueOrNull ?? const {},
                              checkIn: checkInAsync.valueOrNull,
                              summary: summary,
                            ),
                            todayMoments: const [],
                            checkIn: checkInAsync.valueOrNull,
                          ),
                        ),
                        const SizedBox(height: AppLayout.sectionGap),
                        KeyedSubtree(
                          key: _levelLadderKey,
                          child: _LevelLadderCard(
                            palette: palette,
                            currentLevel: summary.level,
                            growthValue: summary.growthValue,
                          ),
                        ),
                        const SizedBox(height: AppLayout.sectionGap),
                        _IslandUnlockCard(
                          palette: palette,
                          currentLevel: summary.level,
                        ),
                      ],
                    ),
                  );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.summary});

  final GrowthSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8A87C).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          LandingGrowthHeader(summary: summary),
          const SizedBox(height: 10),
          LandingIslandProgress(
            summary: summary,
            progressBarHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _WeekActivityCard extends StatelessWidget {
  const _WeekActivityCard({
    required this.palette,
    required this.activeDays,
    required this.streakDays,
    required this.todayMoments,
    this.checkIn,
    this.todayMood,
  });

  final MoodPalette palette;
  final Set<DateTime> activeDays;

  @override
  Widget build(BuildContext context) {
    final today = WeekActivity.dateOnly(DateTime.now());
    final days = WeekActivity.currentWeekDays();
    final weekCount = WeekActivity.activeDaysInCurrentWeek(activeDays);
  final int streakDays;
  final List<DailyMomentModel> todayMoments;
  final MoodReportCheckIn? checkIn;
  final String? todayMood;

  bool get _todayActive {
    if ((todayMood ?? '').trim().isNotEmpty) return true;
    if (checkIn?.checkedInToday ?? false) return true;
    if (todayMoments.isNotEmpty) return true;
    for (final m in todayMoments) {
      final note = (m.note ?? '').trim();
      if (note.length >= GrowthSystem.minDetailNoteLen &&
          momentHasGrowthTags(m)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final baseWeekDays = checkIn?.weekDays.isNotEmpty == true
        ? checkIn!.weekDays
        : defaultWeekCheckInDays();
    final days = mergeIslandVisitWeekDays(
      baseWeekDays: baseWeekDays,
      momentDates: activeDays,
      todayActive: _todayActive,
    );

    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '近 7 天登岛',
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5D4E44),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days)
                _DayDot(
                  weekday: WeekActivity.weekdayLabelFor(
                    day,
                    isToday: day == today,
                  ),
                  active: activeDays.contains(day),
                  isToday: day == today,
                ),
            ],
          const SizedBox(height: 14),
          WeekStreakTrack(
            days: days,
            palette: palette,
          ),
          const SizedBox(height: 10),
          Text(
            '本周活跃 $weekCount 天 / 7 天',
            style: appTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8C7B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpGuideCard extends StatelessWidget {
  const _XpGuideCard({
    required this.palette,
    required this.summary,
    required this.activeDays,
    required this.todayMoments,
    this.checkIn,
    this.loading = false,
  });

  final MoodPalette palette;
  final GrowthSummary summary;
  final Set<DateTime> activeDays;
  final List<DailyMomentModel> todayMoments;
  final MoodReportCheckIn? checkIn;
  final bool loading;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _todayHasDetailRecord {
    for (final m in todayMoments) {
      final note = (m.note ?? '').trim();
      if (note.length >= GrowthSystem.minDetailNoteLen &&
          momentHasGrowthTags(m)) {
        return true;
      }
    }
    return false;
  }

  int get _thisWeekActiveDays =>
      WeekActivity.activeDaysInCurrentWeek(activeDays);

  bool _isActiveOn(DateTime day) => activeDays.contains(WeekActivity.dateOnly(day));

  @override
  Widget build(BuildContext context) {
    final moodDone = (summary.todayMood ?? '').trim().isNotEmpty;
    final detailDone = _todayHasDetailRecord;
    final aiDone =
        todayMoments.isNotEmpty || (checkIn?.checkedInToday ?? false);
    final activeToday = _isActiveOn(_today) ||
        moodDone ||
        detailDone ||
        aiDone;
    final streakDone = activeToday;
    final weekCount = _thisWeekActiveDays;
    final week5Done = weekCount >= 5;
    final week7Done = weekCount >= 7;
    final streakHint = GrowthSystem.streakMilestoneHint(
      currentStreak: summary.streakDays,
      maxStreakDays: summary.maxStreakDays,
      activeToday: activeToday,
    );

    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '如何获得成长值',
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5D4E44),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在「今日日常」里记录真实感受，小岛会慢慢长大。',
            style: appTextStyle(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF8C7B6B),
            ),
          ),
          for (final item in [
            ('记录今日心情', '+10 / 天', moodDone),
            ('写一个包含10个字的日常内容', '+5 / 天', detailDone),
            ('写一篇今日日常', '+5 / 天', aiDone),
            ('连续打卡里程碑', streakHint, streakDone),
            ('本周活跃 5 天', '+20', week5Done),
            ('本周活跃 7 天', '+50', week7Done),
          ]) ...[
            const Divider(height: 20, color: Color(0xFFE8DDD4)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.$3 ? Icons.check_circle_rounded : Icons.eco_outlined,
                  size: 18,
                  color: item.$3
                      ? const Color(0xFF8BC49A)
                      : palette.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.$1,
                    style: appTextStyle(
                      fontSize: 13,
                      color: const Color(0xFF5D4E44),
                    ),
                  ),
                ),
                Text(
                  item.$2,
                  style: appTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: loading
                        ? const Color(0xFFB0A090)
                        : const Color(0xFFE8A87C),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelLadderCard extends StatelessWidget {
  const _LevelLadderCard({
    required this.palette,
    required this.currentLevel,
    required this.growthValue,
  });

  final MoodPalette palette;
  final int currentLevel;
  final int growthValue;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '等级与称号',
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5D4E44),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '累计成长值 $growthValue',
            style: appTextStyle(fontSize: 12, color: const Color(0xFF8C7B6B)),
          ),
          for (var level = 1; level <= GrowthSystem.maxLevel; level++) ...[
            const Divider(height: 18, color: Color(0xFFE8DDD4)),
            _LevelRow(
              level: level,
              title: GrowthSystem.levelTitle(level),
              threshold: GrowthSystem.cumulativeXpForLevel(level),
              reached: currentLevel > level || (currentLevel == level),
              current: currentLevel == level,
              onTap: () => showTitlePreviewDialog(
                context,
                level: level,
                title: GrowthSystem.levelTitle(level),
                threshold: GrowthSystem.cumulativeXpForLevel(level),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.title,
    required this.threshold,
    required this.reached,
    required this.current,
    this.onTap,
  });

  final int level;
  final String title;
  final int threshold;
  final bool reached;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = reached
        ? (current ? Icons.star_rounded : Icons.check_circle_outline)
        : Icons.lock_outline;
    final iconColor = current
        ? const Color(0xFFE8A87C)
        : (reached ? const Color(0xFF8BC49A) : const Color(0xFFB0A090));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lv.$level $title',
                  style: appTextStyle(
                    fontSize: 13,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    color: current
                        ? const Color(0xFF3D3229)
                        : const Color(0xFF5D4E44),
                  ),
                ),
              ),
              Text(
                threshold == 0 ? '起点' : '$threshold',
                style: appTextStyle(fontSize: 11, color: const Color(0xFF8C7B6B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IslandUnlockCard extends StatelessWidget {
  const _IslandUnlockCard({
    required this.palette,
    required this.currentLevel,
  });

  final MoodPalette palette;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '岛屿装饰解锁',
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5D4E44),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '升级后，欢迎页与今日日常里的小岛会出现新元素。',
            style: appTextStyle(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF8C7B6B),
            ),
          ),
          for (final group in IslandUnlockCatalog.allLevelGroups()
              .where((group) => group.items.isNotEmpty)) ...[
            const Divider(height: 18, color: Color(0xFFE8DDD4)),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showLevelUnlockPreviewDialog(
                  context,
                  level: group.level,
                  unlocked: currentLevel >= group.level,
                  items: group.items,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        currentLevel >= group.level
                            ? Icons.landscape_outlined
                            : Icons.lock_outline,
                        size: 18,
                        color: currentLevel >= group.level
                            ? const Color(0xFF8BC49A)
                            : const Color(0xFFB0A090),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Lv.${group.level}',
                        style: appTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C7B6B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.summaryLabel,
                          style: appTextStyle(
                            fontSize: 13,
                            color: const Color(0xFF5D4E44),
                          ),
                        ),
                      ),
                      if (group.items.length > 1)
                        Text(
                          '${group.items.length}项',
                          style: appTextStyle(
                            fontSize: 11,
                            color: const Color(0xFF8C7B6B),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '暂时无法加载等级信息',
            style: appTextStyle(fontSize: 14, color: const Color(0xFF8C7B6B)),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
