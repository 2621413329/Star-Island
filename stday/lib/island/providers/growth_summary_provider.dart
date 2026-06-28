import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/growth/growth_system.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

/// 用户成长摘要（等级、XP、连续打卡等）。
final growthSummaryProvider = FutureProvider<GrowthSummary>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return GrowthSummary.guest();

  // 日常/资料变更后自动重算等级与情绪碎片汇总。
  ref.watch(profileProvider);
  ref.watch(todayMomentsProvider);

  try {
    final summary = await ref.read(growthRepositoryProvider).getGrowthSummary();
    return GrowthSystem.enrich(summary);
  } catch (_) {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile?.growth != null) {
      return GrowthSystem.enrich(profile!.growth!);
    }
    try {
      final moments =
          await ref.read(momentRepositoryProvider).listRecentMoments(days: 365);
      final mood = ref.read(profileProvider).valueOrNull?.todayMood;
      return GrowthSystem.compute(moments: moments, profileTodayMood: mood);
    } catch (_) {
      return GrowthSummary.guest();
    }
  }
});

/// 强制刷新成长摘要（升级/写日常后调用）。
Future<GrowthSummary> refreshGrowthSummary(WidgetRef ref) async {
  await ref.read(profileProvider.notifier).refresh();
  ref.invalidate(growthSummaryProvider);
  return ref.read(growthSummaryProvider.future);
}
