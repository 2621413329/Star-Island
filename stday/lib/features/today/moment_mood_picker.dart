import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/emotion_catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/utils/moment_tags.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/companion_loading.dart';
import '../../design_system/mood_face_selector.dart';
import '../../providers/app_providers.dart';
import '../../providers/story_day_provider.dart';
import '../../providers/member_provider.dart';
import '../../core/membership/vip_guard.dart';

Future<bool?> showMomentMoodPicker(
  BuildContext context,
  WidgetRef ref, {
  required DailyMomentModel moment,
}) {
  if (!isMomentToday(moment) && !ref.read(isVipProvider)) {
    return showVipRequiredDialog(
      context,
      message: '修改历史日期的心情感受需要开通 VIP',
    ).then((_) => null);
  }
  final palette = ref.read(moodPaletteProvider);
  final gender = ref.read(profileProvider).valueOrNull?.gender;

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) {
      return _MomentMoodSheet(
        palette: palette,
        gender: gender,
        moment: moment,
        hostContext: context,
      );
    },
  );
}

class _MomentMoodSheet extends ConsumerStatefulWidget {
  const _MomentMoodSheet({
    required this.palette,
    required this.gender,
    required this.moment,
    required this.hostContext,
  });

  final MoodPalette palette;
  final String? gender;
  final DailyMomentModel moment;
  final BuildContext hostContext;

  @override
  ConsumerState<_MomentMoodSheet> createState() => _MomentMoodSheetState();
}

class _MomentMoodSheetState extends ConsumerState<_MomentMoodSheet> {
  bool _saving = false;
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = effectiveEmotionIdForMoment(widget.moment);
  }

  Future<void> _onSelected(String id) async {
    if (_saving) return;
    final emotion = emotionById(id);
    final primary = momentPrimaryCategory(widget.moment);
    if (primary == null) {
      if (widget.hostContext.mounted) {
        AppFeedback.showWeak(widget.hostContext, '日常尚未完成标签分析，请稍后再试');
      }
      return;
    }
    setState(() {
      _saving = true;
      _selectedId = id;
    });
    try {
      await ref.read(momentRepositoryProvider).updateMoment(
            id: widget.moment.id,
            note: momentStoryNote(widget.moment),
            primaryTag: primary,
            secondaryTags: momentSecondaryTags(widget.moment),
            aiEmotion: emotion.label,
          );
      await refreshAfterMomentMutation(
        ref,
        momentDay: momentCalendarDate(widget.moment),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      if (widget.hostContext.mounted) {
        AppFeedback.showWeak(widget.hostContext, '感受已改为${emotion.label}');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (widget.hostContext.mounted) {
        AppFeedback.showWeak(widget.hostContext, '保存失败：$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final palette = widget.palette;
    final today = isMomentToday(widget.moment);
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: keyboard + MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '修改这条日常的感受',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                today ? '会同步更新小人表情与今日心情统计' : '会同步更新小人表情与对应日期的心情统计',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.primary.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: _saving
                    ? CompanionLoadingView(
                        palette: palette,
                        companion: ref.watch(userCompanionProvider),
                        moodId: _selectedId,
                        message: '正在保存感受…',
                        size: 108,
                      )
                    : MoodFaceSelector(
                        selectedId: _selectedId,
                        size: 52,
                        gender: widget.gender,
                        onSelected: _onSelected,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
