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

/// 感受筛选（客户端过滤；与标签筛选叠加）。
final moodStatusEmotionFilterProvider = StateProvider<String?>((ref) => null);

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

const moodStatusAllMomentsPageSize = 50;

/// 当前周期内全部日常（标签统计用，不受列表分页影响）。
final moodStatusAllMomentsProvider =
    FutureProvider.family<List<DailyMomentModel>, MoodSummaryKey>(
  (ref, key) async {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) return const [];

    final momentRepo = ref.read(momentRepositoryProvider);
    final moodRepo = ref.read(moodRepositoryProvider);
    final period = key.period;
    final categoryFilter = key.categoryFilter;

    if (period != MoodStatusPeriod.month && period != MoodStatusPeriod.year) {
      final anchor = DateTime.now();
      try {
        if (period == MoodStatusPeriod.today) {
          return await momentRepo.listTodayMoments();
        }
        final recent = await momentRepo.listRecentMoments(days: period.fetchDays);
        return filterMomentsByMoodPeriod(recent, period, anchor: anchor);
      } catch (_) {
        return const [];
      }
    }

    final all = <DailyMomentModel>[];
    var page = 1;
    while (true) {
      final result = await moodRepo.fetchMoodPeriodMoments(
        period: period.apiValue,
        categoryFilter: categoryFilter,
        page: page,
        pageSize: moodStatusAllMomentsPageSize,
      );
      all.addAll(result.items);
      if (result.items.isEmpty || all.length >= result.total) break;
      page++;
    }
    return all;
  },
);

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
    final repo = ref.read(moodRepositoryProvider);
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

    final moodRepo = ref.read(moodRepositoryProvider);
    final momentRepo = ref.read(momentRepositoryProvider);

    if (period == MoodStatusPeriod.month || period == MoodStatusPeriod.year) {
      final result = await moodRepo.fetchMoodPeriodMoments(
        period: period.apiValue,
        categoryFilter: categoryFilter,
        page: page,
        pageSize: moodStatusPageSize,
      );
      final reports = await _loadReports(moodRepo, period);
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
    final moments = await _loadMoments(momentRepo, period, anchor);
    final reports = await _loadReports(moodRepo, period);
    return MoodStatusViewState(
      period: period,
      moments: moments,
      reports: reports,
      total: moments.length,
      page: 1,
      pageSize: moments.isNotEmpty ? moments.length : moodStatusPageSize,
    );
  }

  Future<List<DailyMomentModel>> _loadMoments(
    MomentRepository repo,
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
    MoodRepository repo,
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
    ref.invalidate(moodStatusAllMomentsProvider);
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
