import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/daily_mood_prompt_store.dart';
import '../../design_system/growth_island_rules_sheet.dart';
import '../../design_system/growth_reward_dialog.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/mood_status_provider.dart';
import '../../providers/story_day_provider.dart';
import 'add_moment_flow.dart';

bool _dailyEntryRunning = false;

/// 每日首次进入：引导记录今日故事（不再强制选心情）。
Future<void> runDailyEntryFlowIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  if (_dailyEntryRunning) return;
  _dailyEntryRunning = true;
  try {
    if (!context.mounted) return;
    final profile = await ref.read(profileProvider.future);
    if (!context.mounted) return;

    final sync = ref.read(userAppPreferencesSyncProvider);
    final needStory = profile == null
        ? await DailyMoodPromptStore(sync: sync).shouldPromptStoryToday()
        : await DailyMoodPromptStore.needsStoryPrompt(
            appPreferences: profile.appPreferences,
            userId: profile.userId,
            sync: sync,
          );
    if (!needStory) return;

    final store = DailyMoodPromptStore(
      sync: sync,
      userId: profile?.userId,
    );

    final hasTodayStory = await _hasTodayStory(ref);
    if (!needStory || hasTodayStory) return;
    if (!context.mounted) return;

    await showGrowthIslandRulesIfNeeded(
      context,
      sync: ref.read(userAppPreferencesSyncProvider),
    );
    if (!context.mounted) return;

    await store.markStoryPromptedToday();
    final growthBefore = await fetchCurrentGrowthSummary(ref);
    if (!context.mounted) return;
    await showAddMomentFlow(context, ref);
    if (!context.mounted) return;
    await ref.read(todayMomentsProvider.notifier).refresh();
    ref.invalidate(storyDayViewProvider);
    ref.invalidate(moodStatusViewProvider);
    ref.invalidate(moodReportCheckInProvider);
    if (!context.mounted) return;
    await showGrowthRewardsAfterAction(
      context,
      ref,
      before: growthBefore,
    );
  } finally {
    _dailyEntryRunning = false;
  }
}

Future<bool> _hasTodayStory(WidgetRef ref) async {
  final moments = await ref.read(todayMomentsProvider.future);
  return moments.isNotEmpty;
}
