import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/growth/growth_system.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

final landingGrowthProvider = FutureProvider<GrowthSummary>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return GrowthSummary.guest();

  try {
    return await ref.read(appRepositoryProvider).getGrowthSummary();
  } catch (_) {
    try {
      final moments = await ref.read(appRepositoryProvider).listRecentMoments(days: 365);
      final mood = ref.read(profileProvider).valueOrNull?.todayMood;
      return GrowthSystem.compute(moments: moments, profileTodayMood: mood);
    } catch (_) {
      return GrowthSummary.guest();
    }
  }
});
