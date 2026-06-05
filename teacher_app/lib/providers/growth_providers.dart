import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/critical_risk.dart';
import '../data/models/growth_observation.dart';
import '../data/repositories/teacher_repository.dart';
import 'date_providers.dart';

final criticalRiskDetailProvider = FutureProvider.autoDispose.family<CriticalRiskDetail, String>(
  (ref, momentId) => ref.read(teacherRepositoryProvider).getCriticalRiskDetail(momentId),
);

final criticalRiskListProvider = FutureProvider.autoDispose<List<CriticalRiskSignal>>((ref) async {
  final range = ref.watch(alertsDateRangeProvider).normalized();
  return ref.read(teacherRepositoryProvider).listCriticalRiskSignals(
        dateFrom: formatReportDate(range.start),
        dateTo: formatReportDate(range.end),
      );
});

/// 底部导航角标：默认近 3 日待关注危险信号数量。
final pendingGrowthFocusCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final range = defaultAlertRange().normalized();
  return ref.read(teacherRepositoryProvider).pendingCriticalRiskCount(
        dateFrom: formatReportDate(range.start),
        dateTo: formatReportDate(range.end),
      );
});

final archiveTrendDaysProvider = StateProvider.family<int, String>((ref, _) => 5);

/// 档案页成长分类筛选：`all` 或 event_tags 主类 id（学习/朋友/运动/家庭/兴趣/其它）
final archiveCategoryFilterProvider = StateProvider.family<String, String>((ref, _) => 'all');

final growthArchiveProvider = FutureProvider.autoDispose
    .family<GrowthArchive, String>((ref, studentId) async {
  final days = ref.watch(archiveTrendDaysProvider(studentId));
  return ref.read(teacherRepositoryProvider).getGrowthArchive(studentId, days: days);
});
