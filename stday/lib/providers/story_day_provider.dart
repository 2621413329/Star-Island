import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/utils/moment_date_groups.dart';
import '../core/utils/mood_stats.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/app_repository.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String storyDayIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool isCalendarToday(DateTime day) => calendarDate(day) == calendarDate(DateTime.now());

/// 今日故事页当前查看的日期（默认今天）。
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
  /// yyyy-MM-dd → 心情 id（由当日故事统计主导心情推断）
  final Map<String, String> moodByDayIso;

  String? moodForDay(DateTime day) => moodByDayIso[storyDayIso(day)];

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
    AsyncNotifierProvider<StoryDayViewNotifier, StoryDayViewState>(StoryDayViewNotifier.new);

class StoryDayViewNotifier extends AsyncNotifier<StoryDayViewState> {
  @override
  Future<StoryDayViewState> build() async {
    final day = ref.watch(selectedStoryDayProvider);
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
    final repo = ref.read(appRepositoryProvider);
    final selected = calendarDate(day);
    final profile = ref.read(profileProvider).valueOrNull;
    final recent = await _loadRecentSafe(repo);
    final moodByDay = _buildMoodByDay(
      recent,
      profileTodayMood: profile?.todayMood,
    );
    final recordedDays = _mergeRecordedDays(recent, moodByDay);
    final moments = await _loadMomentsForDay(repo, selected);
    return StoryDayViewState(
      selectedDay: selected,
      moments: moments,
      recordedDays: recordedDays,
      moodByDayIso: moodByDay,
    );
  }

  Future<List<DailyMomentModel>> _loadRecentSafe(AppRepository repo) async {
    try {
      return await repo.listRecentMoments(days: 90);
    } catch (_) {
      try {
        return await repo.listTodayMoments();
      } catch (_) {
        return const [];
      }
    }
  }

  Map<String, String> _buildMoodByDay(
    List<DailyMomentModel> recent, {
    String? profileTodayMood,
  }) {
    final today = calendarDate(DateTime.now());
    final byDay = <DateTime, List<DailyMomentModel>>{};
    for (final m in recent) {
      final d = momentCalendarDate(m);
      byDay.putIfAbsent(d, () => []).add(m);
    }
    final map = <String, String>{};
    for (final entry in byDay.entries) {
      final id = resolveStoryDayMoodId(
        viewingToday: entry.key == today,
        moments: entry.value,
        profileTodayMood: entry.key == today ? profileTodayMood : null,
      );
      if (id != null && id.isNotEmpty) {
        map[storyDayIso(entry.key)] = id;
      }
    }
    return map;
  }

  List<DateTime> _mergeRecordedDays(
    List<DailyMomentModel> recent,
    Map<String, String> moodByDay,
  ) {
    final set = <DateTime>{};
    for (final m in recent) {
      set.add(momentCalendarDate(m));
    }
    for (final iso in moodByDay.keys) {
      final parsed = DateTime.tryParse('${iso}T00:00:00');
      if (parsed != null) set.add(calendarDate(parsed));
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    if (list.isEmpty) list.add(calendarDate(DateTime.now()));
    return list;
  }

  /// 今天走 /moments/today（兼容旧后端）；其它日期走 /moments?date=。
  Future<List<DailyMomentModel>> _loadMomentsForDay(
    AppRepository repo,
    DateTime day,
  ) async {
    if (isCalendarToday(day)) {
      return repo.listTodayMoments();
    }
    try {
      return await repo.listMomentsForDate(day);
    } on ApiException catch (e) {
      if (e.statusCode == 405) {
        throw ApiException(
          '当前后端版本较旧，请重启 backend（run_dev.bat）后再查看历史日期',
          e.statusCode,
        );
      }
      rethrow;
    }
  }

  Future<void> loadDay(DateTime day) async {
    if (state.valueOrNull == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() => _load(day));
  }

  Future<void> refresh() async {
    final day = ref.read(selectedStoryDayProvider);
    await loadDay(day);
  }
}

/// 根据所选日期解析主导心情：有故事时按统计，无故事时今天可回退 profile。
String? resolveStoryDayMoodId({
  required bool viewingToday,
  required List<DailyMomentModel> moments,
  String? profileTodayMood,
}) {
  if (moments.isNotEmpty) {
    return averageMoodIdForMoments(moments);
  }
  if (viewingToday &&
      profileTodayMood != null &&
      profileTodayMood.isNotEmpty) {
    return profileTodayMood;
  }
  return null;
}

bool momentOnDay(DailyMomentModel moment, DateTime day) =>
    momentCalendarDate(moment) == calendarDate(day);
