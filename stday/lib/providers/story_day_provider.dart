import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/emotion_catalog.dart';
import '../core/storage/daily_mood_prompt_store.dart';
import '../core/utils/moment_date_groups.dart';
import '../core/utils/mood_stats.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/app_repository.dart';
import '../island/providers/growth_summary_provider.dart';
import 'app_providers.dart';
import 'auth_provider.dart';
import 'growth_observation_provider.dart';
import 'mood_report_check_in_provider.dart';
import 'mood_status_provider.dart';

DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String storyDayIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool isCalendarToday(DateTime day) =>
    calendarDate(day) == calendarDate(DateTime.now());

/// 今日日常页当前查看的日期（默认今天）。
final selectedStoryDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return calendarDate(now);
});

class StoryDayViewState {
  const StoryDayViewState({
    required this.selectedDay,
    required this.moments,
    required this.recordedDays,
    this.moodByDayIso = const {},
  });

  final DateTime selectedDay;
  final List<DailyMomentModel> moments;
  final List<DateTime> recordedDays;

  /// yyyy-MM-dd → 心情 id（由当日日常统计主导心情推断）
  final Map<String, String> moodByDayIso;

  String? moodForDay(DateTime day) => moodByDayIso[storyDayIso(day)];

  StoryDayViewState copyWith({
    DateTime? selectedDay,
    List<DailyMomentModel>? moments,
    List<DateTime>? recordedDays,
    Map<String, String>? moodByDayIso,
  }) {
    return StoryDayViewState(
      selectedDay: selectedDay ?? this.selectedDay,
      moments: moments ?? this.moments,
      recordedDays: recordedDays ?? this.recordedDays,
      moodByDayIso: moodByDayIso ?? this.moodByDayIso,
    );
  }

  /// 首屏骨架：避免全屏 loading 造成「空白」感。
  factory StoryDayViewState.initial({DateTime? day}) {
    final d = calendarDate(day ?? DateTime.now());
    return StoryDayViewState(
      selectedDay: d,
      moments: const [],
      recordedDays: [d],
    );
  }
}

final storyDayViewProvider =
    AsyncNotifierProvider<StoryDayViewNotifier, StoryDayViewState>(
        StoryDayViewNotifier.new);

class StoryDayViewNotifier extends AsyncNotifier<StoryDayViewState> {
  @override
  Future<StoryDayViewState> build() async {
    final day = ref.read(selectedStoryDayProvider);
    return _load(day);
  }

  Future<StoryDayViewState> _load(DateTime day) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      return StoryDayViewState(
        selectedDay: calendarDate(day),
        moments: const [],
        recordedDays: const [],
      );
    }
    final repo = ref.read(momentRepositoryProvider);
    final selected = calendarDate(day);
    final today = calendarDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final profile = ref.read(profileProvider).valueOrNull;
    final days = <DateTime>{selected, today, yesterday};
    final byDay = <DateTime, List<DailyMomentModel>>{};
    await Future.wait(days.map((date) async {
      final loaded = await _loadMomentsForDay(repo, date);
      byDay[date] =
          loaded.where((moment) => momentOnDay(moment, date)).toList();
    }));
    final moodMoments = byDay.values.expand((items) => items).toList();
    final moodByDay = buildMoodByDayIso(
      moodMoments,
      profileTodayMood: profile?.todayMood,
      appPreferences: profile?.appPreferences ?? const {},
    );
    final recordedDays = byDay.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (recordedDays.isEmpty) recordedDays.add(today);
    return StoryDayViewState(
      selectedDay: selected,
      moments: byDay[selected] ?? const [],
      recordedDays: recordedDays,
      moodByDayIso: moodByDay,
    );
  }

  /// 按日期拉取日常（含今天），避免补录后误刷「今日」列表。
  Future<List<DailyMomentModel>> _loadMomentsForDay(
    MomentRepository repo,
    DateTime day,
  ) async {
    final selected = calendarDate(day);
    return await repo.listMomentsForDate(selected);
  }

  Future<void> loadDay(DateTime day) async {
    final normalized = calendarDate(day);
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncData(previous.copyWith(selectedDay: normalized));
    }
    state = await AsyncValue.guard(() => _load(normalized));
  }

  Future<void> refresh() async {
    final day = ref.read(selectedStoryDayProvider);
    await loadDay(day);
  }
}

/// 日常增删改后刷新对应日期列表（历史日期与今天均适用）。
Future<void> refreshAfterMomentMutation(
  WidgetRef ref, {
  DateTime? momentDay,
}) async {
  final day = calendarDate(momentDay ?? ref.read(selectedStoryDayProvider));
  if (!isCalendarToday(day)) {
    ref.read(selectedStoryDayProvider.notifier).state = day;
    await ref.read(storyDayViewProvider.notifier).loadDay(day);
  } else {
    await ref.read(todayMomentsProvider.notifier).refresh();
    await ref.read(storyDayViewProvider.notifier).refresh();
  }
  ref.invalidate(moodStatusViewProvider);
  ref.invalidate(moodReportCheckInProvider);
  ref.invalidate(growthSummaryProvider);
  ref.invalidate(weeklySummaryProvider);
  ref.invalidate(recentStoryMomentsProvider);
}

/// 按日常日期汇总主导心情。今天额外参考个人资料里已选的感受。
Map<String, String> buildMoodByDayIso(
  List<DailyMomentModel> moments, {
  String? profileTodayMood,
  Map<String, dynamic> appPreferences = const {},
}) {
  final today = calendarDate(DateTime.now());
  final byDay = <DateTime, List<DailyMomentModel>>{};
  for (final moment in moments) {
    final day = momentCalendarDate(moment);
    byDay.putIfAbsent(day, () => []).add(moment);
  }
  final map = <String, String>{};
  for (final entry in byDay.entries) {
    final isToday = entry.key == today;
    final id = resolveStoryDayMoodId(
          viewingToday: isToday,
          moments: entry.value,
          profileTodayMood: isToday ? profileTodayMood : null,
          appPreferences: isToday ? appPreferences : const {},
        ) ??
        (entry.value.isNotEmpty
            ? effectiveEmotionIdForMoment(entry.value.first)
            : null);
    if (id != null && id.isNotEmpty) {
      map[storyDayIso(entry.key)] = id;
    }
  }
  return map;
}

/// 根据所选日期解析主导心情：有日常时按统计；无日常且为今天时，未主动选感受则用默认兴奋。
String? resolveStoryDayMoodId({
  required bool viewingToday,
  required List<DailyMomentModel> moments,
  String? profileTodayMood,
  Map<String, dynamic> appPreferences = const {},
}) {
  if (moments.isNotEmpty) {
    final counts = moodCountsForMoments(moments);
    return dominantMoodId(counts);
  }
  if (viewingToday) {
    if (DailyMoodPromptStore.serverSaysMoodPickedToday(appPreferences) &&
        profileTodayMood != null &&
        profileTodayMood.trim().isNotEmpty) {
      return normalizeEmotionId(profileTodayMood);
    }
    return defaultEmotionId;
  }
  return null;
}

bool momentOnDay(DailyMomentModel moment, DateTime day) =>
    momentCalendarDate(moment) == calendarDate(day);
