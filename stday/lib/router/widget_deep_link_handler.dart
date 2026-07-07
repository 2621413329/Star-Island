import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../data/models/story_island_models.dart';
import '../features/today/add_moment_flow.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/current_island_provider.dart';
import '../providers/island_widget_sync_provider.dart';
import '../providers/main_shell_tab_provider.dart';
import '../providers/widget_navigation_provider.dart';
import '../services/island_widget_models.dart';

enum WidgetDeepLinkAction { openIsland, openTask, quickRecord, cycleIsland }

class WidgetDeepLinkIntent {
  const WidgetDeepLinkIntent({
    required this.action,
    this.islandId,
    this.taskId,
    this.islandName,
    this.direction,
  });

  final WidgetDeepLinkAction action;
  final String? islandId;
  final String? taskId;
  final String? islandName;
  final String? direction;
}

final pendingWidgetDeepLinkProvider =
    StateProvider<WidgetDeepLinkIntent?>((_) => null);

WidgetDeepLinkIntent? parseWidgetDeepLink(Uri uri) {
  if (uri.scheme != 'stday') return null;

  final route = [
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments,
  ].join('/');

  switch (route) {
    case 'island':
    case 'widget/island':
      final islandId = uri.queryParameters['islandId'];
      if (islandId == null || islandId.isEmpty) return null;
      return WidgetDeepLinkIntent(
        action: WidgetDeepLinkAction.openIsland,
        islandId: islandId,
      );
    case 'task':
    case 'widget/task':
      final islandId = uri.queryParameters['islandId'];
      final taskId = uri.queryParameters['taskId'];
      if (islandId == null ||
          islandId.isEmpty ||
          taskId == null ||
          taskId.isEmpty) {
        return null;
      }
      return WidgetDeepLinkIntent(
        action: WidgetDeepLinkAction.openTask,
        islandId: islandId,
        taskId: taskId,
      );
    case 'quick-record':
    case 'widget/quick-record':
      final islandId = uri.queryParameters['islandId'];
      if (islandId == null || islandId.isEmpty) return null;
      return WidgetDeepLinkIntent(
        action: WidgetDeepLinkAction.quickRecord,
        islandId: islandId,
      );
    case 'cycle':
    case 'widget/cycle':
      final direction = uri.queryParameters['direction'];
      if (direction != 'prev' && direction != 'next') return null;
      return WidgetDeepLinkIntent(
        action: WidgetDeepLinkAction.cycleIsland,
        direction: direction,
      );
    default:
      return null;
  }
}

/// 监听 Widget deep link，并在主壳就绪后执行导航。
class WidgetDeepLinkHost extends ConsumerStatefulWidget {
  const WidgetDeepLinkHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WidgetDeepLinkHost> createState() => _WidgetDeepLinkHostState();
}

class _WidgetDeepLinkHostState extends ConsumerState<WidgetDeepLinkHost> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _bootstrapLinks();
  }

  Future<void> _bootstrapLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _enqueue(initial);
    } catch (_) {}
    try {
      final fromWidget = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (fromWidget != null) {
        _enqueue(fromWidget);
      }
    } catch (_) {}
    _linkSub = _appLinks.uriLinkStream.listen(_enqueue);
  }

  void _enqueue(Uri uri) {
    final intent = parseWidgetDeepLink(uri);
    if (intent == null) return;
    ref.read(pendingWidgetDeepLinkProvider.notifier).state = intent;
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(islandWidgetSyncProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isLoggedIn && next.ready) {
        final pending = ref.read(pendingWidgetDeepLinkProvider);
        if (pending != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleIntent(context, pending);
          });
        }
      }
    });

    ref.listen<WidgetDeepLinkIntent?>(pendingWidgetDeepLinkProvider, (
      previous,
      next,
    ) {
      if (next == null) return;
      final auth = ref.read(authProvider);
      if (!auth.ready || !auth.isLoggedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleIntent(context, next);
      });
    });

    return widget.child;
  }

  Future<void> _handleIntent(
    BuildContext context,
    WidgetDeepLinkIntent intent,
  ) async {
    final auth = ref.read(authProvider);
    if (!auth.ready || !auth.isLoggedIn) return;

    ref.read(pendingWidgetDeepLinkProvider.notifier).state = null;

    if (intent.action == WidgetDeepLinkAction.cycleIsland) {
      await _handleCycleIsland(intent.direction ?? 'next');
      return;
    }

    final islandId = intent.islandId;
    if (islandId == null || islandId.isEmpty) return;

    StoryIslandModel? island = await _resolveIsland(islandId);
    if (island == null) return;

    await ref.read(currentIslandProvider.notifier).selectFromIsland(island);

    ref.read(pendingIslandWidgetNavigationProvider.notifier).state =
        PendingIslandWidgetNavigation(
      action: intent.action,
      islandId: island.id,
      taskId: intent.taskId,
      islandName: island.name,
    );

    if (!context.mounted) return;
    ref.read(mainShellTabIndexProvider.notifier).state = 0;
    context.go('/island');
  }

  Future<void> _handleCycleIsland(String direction) async {
    final groups =
        ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
    final growthMain = ref.read(growthMainIslandProvider).valueOrNull;
    if (groups.isEmpty && growthMain == null) {
      unawaited(ref.read(storyIslandGroupsProvider.notifier).refresh());
      unawaited(ref.read(growthMainIslandProvider.notifier).refresh());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    final ordered = orderedWidgetIslands(
      growthMainIsland: ref.read(growthMainIslandProvider).valueOrNull,
      groups: ref.read(storyIslandGroupsProvider).valueOrNull ?? const [],
    );
    if (ordered.isEmpty) return;

    await ref.read(currentIslandProvider.notifier).cycleIsland(
          delta: direction == 'prev' ? -1 : 1,
          ordered: ordered,
          wrap: true,
        );
    await syncIslandWidget(ref.read);
  }

  Future<StoryIslandModel?> _resolveIsland(String islandId) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final groups =
          ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
      final growthMain = ref.read(growthMainIslandProvider).valueOrNull;
      final island = findStoryIslandById(
        groups,
        islandId,
        growthMainIsland: growthMain,
      );
      if (island != null) return island;
      if (attempt == 0 &&
          ref.read(storyIslandGroupsProvider).isLoading == false &&
          groups.isEmpty) {
        unawaited(ref.read(storyIslandGroupsProvider.notifier).refresh());
        unawaited(ref.read(growthMainIslandProvider.notifier).refresh());
      }
      await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
    }
    return null;
  }
}

class PendingIslandWidgetNavigation {
  const PendingIslandWidgetNavigation({
    required this.action,
    required this.islandId,
    this.taskId,
    this.islandName,
  });

  final WidgetDeepLinkAction action;
  final String islandId;
  final String? taskId;
  final String? islandName;
}

final pendingIslandWidgetNavigationProvider =
    StateProvider<PendingIslandWidgetNavigation?>((_) => null);

Future<void> handlePendingIslandWidgetNavigation({
  required BuildContext context,
  required WidgetRef ref,
  required PendingIslandWidgetNavigation navigation,
  required Future<void> Function(StoryIslandModel island) openIslandDetail,
}) async {
  final groups = ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
  final growthMain = ref.read(growthMainIslandProvider).valueOrNull;
  final island = findStoryIslandById(
    groups,
    navigation.islandId,
    growthMainIsland: growthMain,
  );
  if (island == null) return;

  await openIslandDetail(island);

  if (!context.mounted) return;
  await Future<void>.delayed(const Duration(milliseconds: 420));

  if (!context.mounted) return;

  switch (navigation.action) {
    case WidgetDeepLinkAction.openIsland:
    case WidgetDeepLinkAction.cycleIsland:
      return;
    case WidgetDeepLinkAction.openTask:
      ref.read(pendingTaskDockIslandIdProvider.notifier).state = island.id;
      return;
    case WidgetDeepLinkAction.quickRecord:
      await showAddMomentFlow(
        context,
        ref,
        forcedStoryIslandId: island.id,
        forcedStoryIslandName: island.name,
      );
  }
}
