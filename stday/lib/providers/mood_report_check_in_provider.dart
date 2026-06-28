import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/mood_check_in_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';

final moodReportCheckInProvider =
    FutureProvider<MoodReportCheckIn>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return MoodReportCheckIn.empty;
  try {
    return await ref.read(moodRepositoryProvider).getMoodReportCheckIn();
  } catch (_) {
    return MoodReportCheckIn.empty;
  }
});
