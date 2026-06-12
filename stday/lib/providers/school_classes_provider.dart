import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/school_class_models.dart';
import '../data/repositories/app_repository.dart';

/// 进入注册/登录页时会 invalidate，确保拉取数据库最新班级列表。
final schoolClassesProvider =
    FutureProvider.autoDispose<SchoolClassList>((ref) async {
  return ref.read(appRepositoryProvider).listSchoolClasses();
});
