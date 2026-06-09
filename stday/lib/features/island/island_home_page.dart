import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final moodId = summary.todayMood ?? profile?.todayMood ?? 'calm';
    final moodLabel = summary.todayWeatherLabel
        .replaceFirst(RegExp(r'^[^\u4e00-\u9fa5A-Za-z0-9]+\s*'), '');

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
              const Positioned.fill(
                child: GrowthWorldViewport(
                  useIslandWorldProvider: true,
                  interactive: false,
                  scale: 1.06,
                ),
              ),
              Positioned.fill(
                child: IslandHudOverlay(
                  summary: summary,
                  todayMoodId: moodId,
                  todayMoodLabel: moodLabel.isEmpty ? '平静' : moodLabel,
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
