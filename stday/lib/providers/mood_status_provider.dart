import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/mood_period.dart';
import '../data/models/mood_report_models.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';

/// 成长轨迹页当前周期（独立于今日记录 [selectedStoryDayProvider]）。
final moodStatusPeriodProvider =
    StateProvider<MoodStatusPeriod>((ref) => MoodStatusPeriod.today);

/// 标签筛选（服务端查询参数）。
final moodStatusCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// 「本月 / 本年度」列表当前页码（切换周期或标签时重置为 1）。
final moodStatusPageProvider = StateProvider<int>((ref) => 1);

const moodStatusPageSize = 10;

@immutable
class MoodSummaryKey {
  const MoodSummaryKey({
    required this.period,
    this.categoryFilter,
  });

  final MoodStatusPeriod period;
  final String? categoryFilter;

  @override
  bool operator ==(Object other) {
    return other is MoodSummaryKey &&
        other.period == period &&
        other.categoryFilter == categoryFilter;
  }

  @override
  int get hashCode => Object.hash(period, categoryFilter);
}

final moodPeriodSummaryProvider =
    FutureProvider.family<MoodPeriodSummaryModel, MoodSummaryKey>(
  (ref, key) async {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) {
      return MoodPeriodSummaryModel(
        period: key.period.apiValue,
        categoryFilter: key.categoryFilter,
        summary: '',
        aiGenerated: false,
        totalMoments: 0,
        moodCounts: const {},
      );
    }
    final repo = ref.read(appRepositoryProvider);
    return repo.fetchMoodPeriodSummary(
      period: key.period.apiValue,
      categoryFilter: key.categoryFilter,
    );
  },
);

class MoodStatusViewState {
  const MoodStatusViewState({
    required this.period,
    required this.moments,
    required this.reports,
    this.total = 0,
    this.page = 1,
    this.pageSize = moodStatusPageSize,
  });

  final MoodStatusPeriod period;
  final List<DailyMomentModel> moments;
  final List<DailyMoodReportModel> reports;
  final int total;
  final int page;
  final int pageSize;

  bool get isPaginated =>
      period == MoodStatusPeriod.month || period == MoodStatusPeriod.year;

  int get totalPages {
    if (!isPaginated || pageSize <= 0) return 1;
    final pages = (total / pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  String get periodLabel => period.label;
  String get summaryTitle => period.summaryTitle;
}

final moodStatusViewProvider =
    AsyncNotifierProvider<MoodStatusViewNotifier, MoodStatusViewState>(
  MoodStatusViewNotifier.new,
);

class MoodStatusViewNotifier extends AsyncNotifier<MoodStatusViewState> {
  @override
  Future<MoodStatusViewState> build() async {
    final period = ref.watch(moodStatusPeriodProvider);
    final page = ref.watch(moodStatusPageProvider);
    final categoryFilter = ref.watch(moodStatusCategoryFilterProvider);
    return _load(
      period: period,
      page: page,
      categoryFilter: categoryFilter,
    );
  }

  Future<MoodStatusViewState> _load({
    required MoodStatusPeriod period,
    required int page,
    required String? categoryFilter,
  }) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      return MoodStatusViewState(
        period: period,
        moments: const [],
        reports: const [],
      );
    }

    final repo = ref.read(appRepositoryProvider);

    if (period == MoodStatusPeriod.month ||
        period == MoodStatusPeriod.year) {
      final result = await repo.fetchMoodPeriodMoments(
        period: period.apiValue,
        categoryFilter: categoryFilter,
        page: page,
        pageSize: moodStatusPageSize,
      );
      final reports = await _loadReports(repo, period);
      return MoodStatusViewState(
        period: period,
        moments: result.items,
        reports: reports,
        total: result.total,
        page: result.page,
        pageSize: result.pageSize,
      );
    }

    final anchor = DateTime.now();
    final moments = await _loadMoments(repo, period, anchor);
    final reports = await _loadReports(repo, period);
    return MoodStatusViewState(
      period: period,
      moments: moments,
      reports: reports,
      total: moments.length,
      page: 1,
      pageSize: moments.length > 0 ? moments.length : moodStatusPageSize,
    );
  }

  Future<List<DailyMomentModel>> _loadMoments(
    AppRepository repo,
    MoodStatusPeriod period,
    DateTime anchor,
  ) async {
    try {
      if (period == MoodStatusPeriod.today) {
        return await repo.listTodayMoments();
      }
      final recent = await repo.listRecentMoments(days: period.fetchDays);
      return filterMomentsByMoodPeriod(recent, period, anchor: anchor);
    } catch (_) {
      return const [];
    }
  }

  Future<List<DailyMoodReportModel>> _loadReports(
    AppRepository repo,
    MoodStatusPeriod period,
  ) async {
    try {
      return await repo.listMoodReports(period: period.apiValue);
    } catch (_) {
      return const [];
    }
  }

  Future<void> refresh() async {
    final period = ref.read(moodStatusPeriodProvider);
    final page = ref.read(moodStatusPageProvider);
    final categoryFilter = ref.read(moodStatusCategoryFilterProvider);
    ref.invalidate(moodPeriodSummaryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(
        period: period,
        page: page,
        categoryFilter: categoryFilter,
      ),
    );
  }

  void goToPage(int page) {
    ref.read(moodStatusPageProvider.notifier).state = page;
  }
}
