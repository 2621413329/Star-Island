import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/island_widget_sync_provider.dart';
import '../../services/island_widget_models.dart';

/// 监听本地日历日切换：0 点或回到前台跨日后，刷新今日数据并同步桌面小组件。
class IslandWidgetDayRolloverHost extends ConsumerStatefulWidget {
  const IslandWidgetDayRolloverHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<IslandWidgetDayRolloverHost> createState() =>
      _IslandWidgetDayRolloverHostState();
}

class _IslandWidgetDayRolloverHostState
    extends ConsumerState<IslandWidgetDayRolloverHost>
    with WidgetsBindingObserver {
  String _syncedDayIso = islandWidgetTodayDateIso(DateTime.now());
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRollover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_rolloverIfNeeded(forceSync: true));
      _scheduleMidnightRollover();
    }
  }

  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 2);
    _midnightTimer = Timer(delay, () {
      unawaited(_rolloverIfNeeded(forceSync: true));
      _scheduleMidnightRollover();
    });
  }

  Future<void> _rolloverIfNeeded({bool forceSync = false}) async {
    final todayIso = islandWidgetTodayDateIso(DateTime.now());
    if (!forceSync && todayIso == _syncedDayIso) return;
    final dayChanged = todayIso != _syncedDayIso;
    _syncedDayIso = todayIso;

    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;

    if (dayChanged) {
      try {
        await ref.read(todayMomentsProvider.notifier).refresh();
      } catch (_) {}
    }
    await syncIslandWidgetFromRef(ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(islandWidgetSyncProvider);
    return widget.child;
  }
}
