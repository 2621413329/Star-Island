import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/growth/growth_system.dart';
import '../../core/storage/daily_level_unlock_store.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/growth_reward_dialog.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

Future<GrowthSummary?> fetchCurrentGrowthSummary(WidgetRef ref) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) return null;
  try {
    return GrowthSystem.enrich(
      await ref.read(growthRepositoryProvider).getGrowthSummary(),
    );
  } catch (_) {
    try {
      final moments =
          await ref.read(momentRepositoryProvider).listRecentMoments(days: 365);
      final mood = ref.read(profileProvider).valueOrNull?.todayMood;
      return GrowthSystem.compute(moments: moments, profileTodayMood: mood);
    } catch (_) {
      return null;
    }
  }
}

Future<void> showGrowthRewardsAfterAction(
  BuildContext context,
  WidgetRef ref, {
  GrowthSummary? before,
}) async {
  if (!context.mounted) return;
  final after = await fetchCurrentGrowthSummary(ref);
  if (!context.mounted || after == null) return;

  if (after.level > (before?.level ?? after.level)) {
    await refreshGrowthSummary(ref);
  } else {
    ref.invalidate(growthSummaryProvider);
  }
  if (!context.mounted) return;

  final prev = before;
  if (prev == null) {
    if (after.growthValue > 0) {
      GrowthValueOverlay.show(context, xp: after.growthValue);
    }
    return;
  }

  if (after.level > prev.level) {
    final userId = ref.read(profileProvider).valueOrNull?.userId;
    final lastAck = await DailyLevelUnlockStore().lastAckLevel(userId);
    if (!context.mounted) return;
    await showLevelUnlockCelebration(
      context,
      summary: after,
      fromLevel: prev.level > lastAck ? prev.level : lastAck,
      userId: userId,
    );
    if (!context.mounted) return;
    await refreshGrowthSummary(ref);
    return;
  }

  for (final days in GrowthSystem.streakMilestoneXp.keys.toList()..sort()) {
    if (prev.maxStreakDays < days && after.maxStreakDays >= days) {
      final xp = GrowthSystem.streakMilestoneXp[days] ?? 0;
      if (!context.mounted) return;
      await GrowthRewardDialog.show(
        context,
        payload: GrowthRewardPayload(
          kind: GrowthRewardKind.streak,
          xp: xp,
          headline: '🔥 连续成长$days天',
          body: '坚持不是一件轰轰烈烈的事',
          subline: '而是一次次没有缺席',
        ),
      );
      return;
    }
  }

  final delta = after.growthValue - prev.growthValue;
  if (delta > 0) {
    if (!context.mounted) return;
    GrowthValueOverlay.show(context, xp: delta);
  }
}
