import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/daily_mood_prompt_store.dart';
import '../../core/storage/user_app_preferences_sync.dart';
import '../../design_system/growth_island_rules_sheet.dart';
import '../../design_system/growth_reward_dialog.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/story_day_provider.dart';
import '../onboarding/time_travel_page.dart';
import 'add_moment_flow.dart';
import 'daily_mood_prompt.dart';

bool _dailyEntryRunning = false;

/// 每日首次进入主界面：选今日心情 → 穿梭动画 → 引导记录今日故事。
Future<void> runDailyEntryFlowIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  if (_dailyEntryRunning) return;
  _dailyEntryRunning = true;
  try {
    if (!context.mounted) return;
    await ref.read(profileProvider.future);
    if (!context.mounted) return;

    final store = DailyMoodPromptStore(
      sync: ref.read(userAppPreferencesSyncProvider),
    );
    final needMood = await store.shouldPromptMoodToday();
    final needStory = await store.shouldPromptStoryToday();
    if (!needMood && !needStory) return;

    final hasTodayStory = await _hasTodayStory(ref);
    if (!needMood && (!needStory || hasTodayStory)) return;
    if (!context.mounted) return;

    await showGrowthIslandRulesIfNeeded(
      context,
      sync: ref.read(userAppPreferencesSyncProvider),
    );
    if (!context.mounted) return;

    String? moodId;
    if (needMood) {
      moodId = await showDailyMoodPicker(context, ref);
      if (moodId == null || !context.mounted) return;
      await ref.read(profileProvider.notifier).updateMood(moodId);
      await store.markMoodPickedToday();
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodReportCheckInProvider);
      await ref.read(moodIslandRegistryProvider.notifier).refresh();
      if (!context.mounted) return;
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => TimeTravelArrivalPage(
            moodId: moodId!,
            exitWithPop: true,
          ),
        ),
      );
      if (!context.mounted) return;
    }

    if (!await store.shouldPromptStoryToday()) return;
    if (await _hasTodayStory(ref)) {
      await store.markStoryPromptedToday();
      return;
    }
    if (!context.mounted) return;
    await _openDailyStoryFlow(context, ref, store);
  } finally {
    _dailyEntryRunning = false;
  }
}

Future<bool> _hasTodayStory(WidgetRef ref) async {
  final moments = await ref.read(todayMomentsProvider.future);
  return moments.isNotEmpty;
}

Future<void> _openDailyStoryFlow(
  BuildContext context,
  WidgetRef ref,
  DailyMoodPromptStore store,
) async {
  await store.markStoryPromptedToday();
  final growthBefore = await fetchCurrentGrowthSummary(ref);
  if (!context.mounted) return;
  await showAddMomentFlow(context, ref);
  if (!context.mounted) return;
  await ref.read(todayMomentsProvider.notifier).refresh();
  ref.invalidate(storyDayViewProvider);
  ref.invalidate(moodReportCheckInProvider);
  if (!context.mounted) return;
  await showGrowthRewardsAfterAction(
    context,
    ref,
    before: growthBefore,
  );
}
