import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/growth/growth_system.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

/// 用户成长摘要（等级、XP、连续打卡等）。
final growthSummaryProvider = FutureProvider<GrowthSummary>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return GrowthSummary.guest();

  // 故事/资料变更后自动重算等级与情绪碎片汇总。
  ref.watch(profileProvider);
  ref.watch(todayMomentsProvider);

  try {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile?.growth != null) {
      return profile!.growth!;
    }
    return await ref.read(appRepositoryProvider).getGrowthSummary();
  } catch (_) {
    try {
      final moments =
          await ref.read(appRepositoryProvider).listRecentMoments(days: 365);
      final mood = ref.read(profileProvider).valueOrNull?.todayMood;
      return GrowthSystem.compute(moments: moments, profileTodayMood: mood);
    } catch (_) {
      return GrowthSummary.guest();
    }
  }
});
