import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/growth_tag_seed.dart';
import '../../data/local/growth_tag_catalog_cache.dart';
import '../../data/models/growth_tag_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/auth_provider.dart';

List<GrowthTagCategoryModel> _resolveGrowthTagCatalog({
  required List<GrowthTagCategoryModel> cached,
  required List<GrowthTagCategoryModel> remote,
}) {
  if (remote.isNotEmpty) return remote;
  if (cached.isNotEmpty) return cached;
  return bundledGrowthTagCatalog;
}

final growthTagCatalogProvider =
    FutureProvider<List<GrowthTagCategoryModel>>((ref) async {
  ref.listen(authProvider, (previous, next) {
    if (previous?.isLoggedIn != next.isLoggedIn) {
      ref.invalidateSelf();
    }
  });

  final cached = await GrowthTagCatalogCache.load();
  if (!ref.watch(authProvider).isLoggedIn) {
    return _resolveGrowthTagCatalog(cached: cached, remote: const []);
  }

  try {
    final fresh = await ref.read(appRepositoryProvider).listGrowthTags();
    if (fresh.isNotEmpty) {
      await GrowthTagCatalogCache.save(fresh);
    }
    return _resolveGrowthTagCatalog(cached: cached, remote: fresh);
  } catch (_) {
    return _resolveGrowthTagCatalog(cached: cached, remote: const []);
  }
});
