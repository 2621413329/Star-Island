import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/growth_observation_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';
import 'member_provider.dart';

final weeklySummaryProvider =
    FutureProvider.autoDispose<WeeklySummary>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) {
    return WeeklySummary(weeklyHint: '', trendLabel: '', disclaimer: '');
  }
  if (!ref.watch(isVipProvider)) {
    return WeeklySummary(weeklyHint: '', trendLabel: '', disclaimer: '');
  }
  return ref.read(growthRepositoryProvider).getWeeklySummary(days: 7);
});
