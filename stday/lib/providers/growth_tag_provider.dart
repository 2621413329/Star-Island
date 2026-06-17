import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/growth_tag_catalog_cache.dart';
import '../../data/models/growth_tag_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/auth_provider.dart';

final growthTagCatalogProvider =
    FutureProvider<List<GrowthTagCategoryModel>>((ref) async {
  ref.listen(authProvider, (previous, next) {
    if (previous?.isLoggedIn != next.isLoggedIn) {
      ref.invalidateSelf();
    }
  });

  final cached = await GrowthTagCatalogCache.load();
  if (!ref.watch(authProvider).isLoggedIn) {
    return cached;
  }

  try {
    final fresh = await ref.read(appRepositoryProvider).listGrowthTags();
    await GrowthTagCatalogCache.save(fresh);
    return fresh;
  } catch (_) {
    return cached;
  }
});
