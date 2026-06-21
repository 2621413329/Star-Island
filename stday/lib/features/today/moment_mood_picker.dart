import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/utils/moment_tags.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/mood_face_selector.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/mood_status_provider.dart';
import '../../providers/story_day_provider.dart';

Future<bool?> showMomentMoodPicker(
  BuildContext context,
  WidgetRef ref, {
  required DailyMomentModel moment,
}) {
  if (!isMomentToday(moment)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('仅今日日常可以修改心情')),
    );
    return Future.value(false);
  }

  final palette = ref.read(moodPaletteProvider);
  final gender = ref.read(profileProvider).valueOrNull?.gender;

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '修改这条日常的心情',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '会同步更新小人表情与今日心情统计',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.primary.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 20),
              MoodFaceSelector(
                selectedId: moment.emotionTag,
                size: 52,
                gender: gender,
                onSelected: (id) async {
                  try {
                    final primary = momentPrimaryCategory(moment);
                    if (primary == null) {
                      throw Exception('日常尚未完成标签分析，请稍后再试');
                    }
                    await ref.read(appRepositoryProvider).updateMoment(
                          id: moment.id,
                          note: moment.note ?? '',
                          primaryTag: primary,
                          secondaryTags: momentSecondaryTags(moment),
                          emotionTag: id,
                          aiEmotion: moment.aiEmotion,
                        );
                    ref.invalidate(todayMomentsProvider);
                    ref.invalidate(storyDayViewProvider);
                    ref.invalidate(moodStatusViewProvider);
                    ref.invalidate(moodReportCheckInProvider);
                    ref.invalidate(growthSummaryProvider);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('心情已改为${moodLabel(id)}')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) Navigator.pop(ctx, false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('保存失败：$e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
