import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/school_classes.dart';
import '../data/models/school_class_models.dart';
import '../data/repositories/teacher_repository.dart';

final schoolClassesProvider = FutureProvider<SchoolClassList>((ref) async {
  try {
    return await ref.read(teacherRepositoryProvider).listSchoolClasses();
  } catch (_) {
    return const SchoolClassList(
      defaultClass: defaultClassName,
      classes: schoolClassOptions,
    );
  }
});
