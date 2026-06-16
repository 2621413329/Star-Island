import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/growth_tag_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/auth_provider.dart';

final growthTagCatalogProvider =
    FutureProvider<List<GrowthTagCategoryModel>>((ref) async {
  if (!ref.watch(authProvider).isLoggedIn) return const [];
  try {
    return await ref.read(appRepositoryProvider).listGrowthTags();
  } catch (_) {
    return const [];
  }
});
