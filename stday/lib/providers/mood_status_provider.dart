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
  });

  final MoodStatusPeriod period;
  final List<DailyMomentModel> moments;
  final List<DailyMoodReportModel> reports;

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
    return _load(period);
  }

  Future<MoodStatusViewState> _load(MoodStatusPeriod period) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      return MoodStatusViewState(
        period: period,
        moments: const [],
        reports: const [],
      );
    }

    final repo = ref.read(appRepositoryProvider);
    final anchor = DateTime.now();
    final moments = await _loadMoments(repo, period, anchor);
    final reports = await _loadReports(repo, period);

    return MoodStatusViewState(
      period: period,
      moments: moments,
      reports: reports,
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
    ref.invalidate(moodPeriodSummaryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(period));
  }
}
