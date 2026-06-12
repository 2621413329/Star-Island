import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/catalog.dart';
import '../../core/growth/growth_system.dart';
import '../../design_system/companion_loading.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/island_hud_overlay.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/story_day_provider.dart';

/// Growth Island 2.0：全屏成长世界 + HUD 叠层。
class IslandHomePage extends ConsumerStatefulWidget {
  const IslandHomePage({super.key});

  @override
  ConsumerState<IslandHomePage> createState() => _IslandHomePageState();
}

class _IslandHomePageState extends ConsumerState<IslandHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(storyDayViewProvider.notifier).refresh();
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
    });
  }

  Future<void> _refresh() async {
    await ref.read(storyDayViewProvider.notifier).refresh();
    await ref.read(todayMomentsProvider.notifier).refresh();
    ref.invalidate(moodReportCheckInProvider);
    ref.invalidate(growthSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final growthAsync = ref.watch(growthSummaryProvider);
    final summary = growthAsync.valueOrNull ?? GrowthSummary.guest();
    final profile = ref.watch(profileProvider).valueOrNull;
    final moments = ref.watch(todayMomentsProvider).valueOrNull ?? const [];
    final moodId = summary.todayMood ?? profile?.todayMood ?? 'calm';
    final moodLabelText = moodLabel(moodId);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      extendBodyBehindAppBar: true,
      body: growthAsync.when(
        loading: () => const MoodCompanionLoadingBody(
          message: '正在唤醒你的成长世界…',
        ),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (_) => RefreshIndicator(
          color: palette.accent,
          onRefresh: _refresh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GrowthWorldViewport(
                  key: ValueKey(
                    'island_${summary.level}_${summary.growthValue}_${moments.length}',
                  ),
                  useIslandWorldProvider: true,
                  interactive: true,
                  scale: 1.06,
                  force2D: true,
                ),
              ),
              Positioned.fill(
                child: IslandHudOverlay(
                  summary: summary,
                  todayMoodId: moodId,
                  todayMoodLabel: moodLabelText,
                  onRecordTap: () => context.go('/records'),
                  onMoodTap: () => context.go('/records'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
