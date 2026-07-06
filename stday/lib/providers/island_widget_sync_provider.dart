import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/island_widget_models.dart';
import '../services/island_widget_service.dart';
import 'app_providers.dart';
import 'auth_provider.dart';
import 'current_island_provider.dart';

/// 将当前岛屿上下文同步到 iOS / Android 桌面小组件（严格单岛隔离）。
Future<void> syncIslandWidgetFromRef(Ref ref) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) {
    await IslandWidgetService.clear();
    return;
  }

  final current = ref.read(currentIslandProvider);
  if (current == null) {
    await IslandWidgetService.clear();
    return;
  }

  final groups = ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
  final growthMain = ref.read(growthMainIslandProvider).valueOrNull;
  final island = findStoryIslandById(
    groups,
    current.id,
    growthMainIsland: growthMain,
  );
  if (island == null || island.id != current.id) {
    await IslandWidgetService.clear();
    return;
  }

  final todayDate = islandWidgetTodayDateIso(DateTime.now());
  final payload = buildIslandWidgetPayload(
    island: island,
    todayDate: todayDate,
  );
  await IslandWidgetService.syncPayload(payload);
}

final islandWidgetSyncProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (_, __) {
    unawaited(syncIslandWidgetFromRef(ref));
  });
  ref.listen(currentIslandProvider, (_, __) {
    unawaited(syncIslandWidgetFromRef(ref));
  });
  ref.listen(storyIslandGroupsProvider, (_, __) {
    unawaited(syncIslandWidgetFromRef(ref));
  });
  ref.listen(growthMainIslandProvider, (_, __) {
    unawaited(syncIslandWidgetFromRef(ref));
  });
  unawaited(syncIslandWidgetFromRef(ref));
});
