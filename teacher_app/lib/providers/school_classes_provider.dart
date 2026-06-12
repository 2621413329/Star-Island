import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/school_class_models.dart';
import '../data/repositories/teacher_repository.dart';

final schoolClassesProvider =
    FutureProvider.autoDispose<SchoolClassList>((ref) async {
  return ref.read(teacherRepositoryProvider).listSchoolClasses();
});
