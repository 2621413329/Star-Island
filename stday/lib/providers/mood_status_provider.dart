import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/emotion_catalog.dart';
import '../core/utils/moment_tags.dart';
import '../core/utils/mood_period.dart';
import '../core/utils/mood_stats.dart';
import '../data/models/mood_report_models.dart';
import '../data/models/paginated_moments_model.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';
import 'member_provider.dart';

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
        final recent =
            await momentRepo.listRecentMoments(days: period.fetchDays);
        return filterMomentsByMoodPeriod(recent, period, anchor: anchor);
      } catch (_) {
        return const [];
      }
    }

    try {
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
      if (all.isNotEmpty) return all;
    } catch (_) {
      // Fall through to the stable moments API below.
    }
    return _loadLocalPeriodMoments(
      momentRepo,
      period: period,
      categoryFilter: categoryFilter,
    );
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
    if (!ref.watch(isVipProvider)) {
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
    MoodPeriodSummaryModel? summary;
    try {
      summary = await repo.fetchMoodPeriodSummary(
        period: key.period.apiValue,
        categoryFilter: key.categoryFilter,
      );
      if (summary.totalMoments > 0 ||
          key.period != MoodStatusPeriod.month &&
              key.period != MoodStatusPeriod.year) {
        return summary;
      }
    } catch (_) {
      if (key.period != MoodStatusPeriod.month &&
          key.period != MoodStatusPeriod.year) {
        rethrow;
      }
    }

    final localMoments = await _loadLocalPeriodMoments(
      ref.read(momentRepositoryProvider),
      period: key.period,
      categoryFilter: key.categoryFilter,
    );
    if (localMoments.isEmpty && summary != null) return summary;
    if (localMoments.isEmpty) {
      return MoodPeriodSummaryModel(
        period: key.period.apiValue,
        categoryFilter: key.categoryFilter,
        summary: '',
        aiGenerated: false,
        totalMoments: 0,
        moodCounts: const {},
      );
    }
    return _localMoodSummary(
      period: key.period,
      categoryFilter: key.categoryFilter,
      moments: localMoments,
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
      final result = await _loadPaginatedPeriodMoments(
        moodRepo,
        momentRepo,
        period: period,
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

Future<PaginatedMomentsModel> _loadPaginatedPeriodMoments(
  MoodRepository moodRepo,
  MomentRepository momentRepo, {
  required MoodStatusPeriod period,
  required String? categoryFilter,
  required int page,
  required int pageSize,
}) async {
  try {
    final result = await moodRepo.fetchMoodPeriodMoments(
      period: period.apiValue,
      categoryFilter: categoryFilter,
      page: page,
      pageSize: pageSize,
    );
    if (result.items.isNotEmpty || result.total > 0) return result;
  } catch (_) {
    // The period endpoint can lag behind moment creation; use local filtering.
  }

  final moments = await _loadLocalPeriodMoments(
    momentRepo,
    period: period,
    categoryFilter: categoryFilter,
  );
  return _paginateLocalMoments(moments, page: page, pageSize: pageSize);
}

Future<List<DailyMomentModel>> _loadLocalPeriodMoments(
  MomentRepository repo, {
  required MoodStatusPeriod period,
  required String? categoryFilter,
}) async {
  try {
    final anchor = DateTime.now();
    final recent = await repo.listRecentMoments(days: period.fetchDays);
    final moments = filterMomentsByMoodPeriod(recent, period, anchor: anchor)
        .where((m) =>
            categoryFilter == null ||
            momentPrimaryCategory(m) == categoryFilter)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return moments;
  } catch (_) {
    return const [];
  }
}

PaginatedMomentsModel _paginateLocalMoments(
  List<DailyMomentModel> moments, {
  required int page,
  required int pageSize,
}) {
  final safePageSize = pageSize <= 0 ? moodStatusPageSize : pageSize;
  final total = moments.length;
  final totalPages = (total / safePageSize).ceil().clamp(1, 999999).toInt();
  final safePage = page.clamp(1, totalPages).toInt();
  final start = ((safePage - 1) * safePageSize).clamp(0, total).toInt();
  final end = (start + safePageSize).clamp(start, total).toInt();
  return PaginatedMomentsModel(
    total: total,
    page: safePage,
    pageSize: safePageSize,
    items: moments.sublist(start, end),
  );
}

MoodPeriodSummaryModel _localMoodSummary({
  required MoodStatusPeriod period,
  required String? categoryFilter,
  required List<DailyMomentModel> moments,
}) {
  final counts = moodCountsForMoments(moments, categoryLabel: categoryFilter);
  final dominantId = dominantMoodId(counts);
  final dominant = dominantId == null ? null : emotionById(dominantId);
  final moodText = dominant == null ? '已有新的心情记录' : '主要感受是「${dominant.label}」';
  return MoodPeriodSummaryModel(
    period: period.apiValue,
    categoryFilter: categoryFilter,
    summary:
        '${period.label}已记录 ${moments.length} 条日常，$moodText。AI 总结稍后会根据这些记录更新。',
    aiGenerated: false,
    totalMoments: moments.length,
    moodCounts: counts,
    dominantMood: dominantId,
  );
}
