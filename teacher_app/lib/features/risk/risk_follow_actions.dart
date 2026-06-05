import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/teacher_repository.dart';
import '../../providers/growth_providers.dart';
import 'risk_follow_sheet.dart';

Future<bool> markRiskFollowed(
  WidgetRef ref, {
  required BuildContext context,
  required String momentId,
  String? initialNote,
  String? studentName,
}) async {
  final note = await showRiskFollowNoteSheet(
    context,
    initialNote: initialNote,
    studentName: studentName,
  );
  if (note == null) return false;
  await ref.read(teacherRepositoryProvider).markCriticalRiskFollowed(
        momentId: momentId,
        note: note.isEmpty ? null : note,
      );
  _refreshFollowState(ref, momentId);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已标记为已关注'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return true;
}

Future<bool> reactivateRiskFollow(
  WidgetRef ref, {
  required BuildContext context,
  required String momentId,
}) async {
  final ok = await showRiskReactivateSheet(context);
  if (ok != true) return false;
  await ref.read(teacherRepositoryProvider).reactivateCriticalRisk(momentId);
  _refreshFollowState(ref, momentId);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已恢复为待关注'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return true;
}

void _refreshFollowState(WidgetRef ref, String momentId) {
  ref.invalidate(criticalRiskListProvider);
  ref.invalidate(pendingGrowthFocusCountProvider);
  ref.invalidate(criticalRiskDetailProvider(momentId));
}

void invalidateRiskFollowState(WidgetRef ref, String momentId) {
  _refreshFollowState(ref, momentId);
}
