import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/teacher_repository.dart';

final teacherProfileProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(teacherRepositoryProvider).fetchTeacherProfile();
});
