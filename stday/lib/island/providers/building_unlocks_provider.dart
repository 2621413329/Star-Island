import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/app_repository.dart';
import '../../providers/auth_provider.dart';
import 'growth_summary_provider.dart';

/// 用户已解锁建筑及获得时间（来自服务端数据库）。
final buildingUnlocksProvider =
    FutureProvider<Map<String, DateTime>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return const {};

  ref.watch(growthSummaryProvider);

  try {
    final rows = await ref.read(appRepositoryProvider).listBuildingUnlocks();
    return {
      for (final row in rows) row.buildingId: row.unlockedAt,
    };
  } catch (_) {
    return const {};
  }
});

/// 刷新建筑解锁记录（成长值变化后调用）。
Future<void> refreshBuildingUnlocks(WidgetRef ref) async {
  ref.invalidate(buildingUnlocksProvider);
  await ref.read(buildingUnlocksProvider.future);
}
