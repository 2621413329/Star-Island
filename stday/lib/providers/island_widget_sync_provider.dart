import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/island_widget_models.dart';
import '../services/island_widget_service.dart';
import 'app_providers.dart';
import 'auth_provider.dart';
import 'current_island_provider.dart';
import '../island/providers/growth_summary_provider.dart';

/// 将当前岛屿上下文同步到 iOS / Android 桌面小组件（严格单岛隔离）。
Future<void> syncIslandWidget(
  T Function<T>(ProviderListenable<T> provider) read,
) async {
  final auth = read(authProvider);
  if (!auth.isLoggedIn) {
    await IslandWidgetService.clear();
    return;
  }

  final current = read(currentIslandProvider);
  if (current == null) {
    await IslandWidgetService.clear();
    return;
  }

  final groups = read(storyIslandGroupsProvider).valueOrNull ?? const [];
  final growthMain = read(growthMainIslandProvider).valueOrNull;
  final ordered = orderedWidgetIslands(
    growthMainIsland: growthMain,
    groups: groups,
  );
  final island = findStoryIslandById(
    groups,
    current.id,
    growthMainIsland: growthMain,
  );
  if (island == null || island.id != current.id) {
    await IslandWidgetService.clear();
    return;
  }

  final index = ordered.indexWhere((item) => item.id == island.id);
  final todayDate = islandWidgetTodayDateIso(DateTime.now());
  final mainLevel = read(growthSummaryProvider).valueOrNull?.level;
  final payload = buildIslandWidgetPayload(
    island: island,
    todayDate: todayDate,
    islandIndex: index < 0 ? 0 : index,
    islandTotal: ordered.isEmpty ? 1 : ordered.length,
    orderedIslandIds: ordered.map((e) => e.id).toList(),
    mainIslandUserLevel: mainLevel,
  );
  await IslandWidgetService.saveCatalogFromIslands(
    ordered: ordered,
    todayDate: todayDate,
    mainIslandUserLevel: mainLevel,
  );
  await IslandWidgetService.syncPayload(payload);
}

Future<void> syncIslandWidgetFromRef(Ref ref) => syncIslandWidget(ref.read);

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
  ref.listen(growthSummaryProvider, (_, __) {
    unawaited(syncIslandWidgetFromRef(ref));
  });
  unawaited(syncIslandWidgetFromRef(ref));
});
