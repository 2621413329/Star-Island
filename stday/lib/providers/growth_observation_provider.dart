import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/growth_observation_models.dart';
import '../data/repositories/app_repository.dart';
import 'app_providers.dart';

final studentGrowthObservationProvider =
    FutureProvider.autoDispose<StudentGrowthObservation>((ref) async {
  return ref.read(appRepositoryProvider).getStudentGrowthObservation(days: 7);
});
