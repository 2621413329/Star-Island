import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/daily_level_unlock_store.dart';
import 'growth_system.dart';
import '../../design_system/growth_reward_dialog.dart';
import '../../providers/app_providers.dart';

/// 进入岛屿/欢迎页时：若等级高于上次已确认等级，补弹解锁提示。
Future<void> maybeShowDailyLevelUnlockPrompt(
  BuildContext context,
  WidgetRef ref, {
  required GrowthSummary summary,
  DailyLevelUnlockStore? store,
}) async {
  if (!context.mounted || summary.isGuest) return;

  final userId = ref.read(profileProvider).valueOrNull?.userId;
  final levelStore = store ?? DailyLevelUnlockStore();
  final lastAck = await levelStore.lastAckLevel(userId);
  if (!context.mounted || summary.level <= lastAck) return;

  await showLevelUnlockCelebration(
    context,
    summary: summary,
    fromLevel: lastAck,
    store: levelStore,
    userId: userId,
    markAck: true,
  );
}
