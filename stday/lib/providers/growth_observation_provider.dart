import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/growth_observation_models.dart';
import '../data/repositories/app_repository.dart';

final weeklySummaryProvider =
    FutureProvider.autoDispose<WeeklySummary>((ref) async {
  return ref.read(growthRepositoryProvider).getWeeklySummary(days: 7);
});
