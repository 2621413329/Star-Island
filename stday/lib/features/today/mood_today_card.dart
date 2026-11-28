import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/emotion_catalog.dart';
import '../../core/growth/growth_system.dart';
import '../../core/storage/daily_mood_prompt_store.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../design_system/companion_loading.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../design_system/mood_face_selector.dart';
import '../../design_system/pressable_feedback.dart';
import '../../providers/app_providers.dart';
import '../../providers/story_day_provider.dart';
import '../achievement/growth_reward_actions.dart';

class MoodTodayCard extends ConsumerWidget {
  const MoodTodayCard({
    super.key,
    required this.palette,
    required this.selectedDay,
    required this.displayMoodId,
    this.canEdit = true,
    this.hasStoryStats = false,
  });

  final MoodPalette palette;
  final DateTime selectedDay;
  final String? displayMoodId;
  final bool canEdit;
  final bool hasStoryStats;

  Future<void> _editMood(BuildContext context, WidgetRef ref) async {
    final current = ref.read(profileProvider).valueOrNull?.todayMood;
    final result = await showModalBottomSheet<_MoodEditResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (ctx) {
        return _MoodEditSheet(
          palette: palette,
          initialMoodId: current ?? defaultEmotionId,
          gender: ref.read(profileProvider).valueOrNull?.gender,
        );
      },
    );
    if (result == null || !context.mounted) return;
    ref.invalidate(storyDayViewProvider);
    await showGrowthRewardsAfterAction(
      context,
      ref,
      before: result.before,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotion = displayMoodId != null ? emotionById(displayMoodId!) : null;
    final gender = ref.watch(userCompanionProvider).gender;
    final viewingToday = isCalendarToday(selectedDay);
    final dateTitle = formatStoryDayMoodCardTitle(selectedDay);
    final subtitle = viewingToday
        ? (hasStoryStats ? '由当日日常统计' : '记录今天，小岛会随之变化')
        : (emotion != null ? '由当日日常回顾' : '当日未记录心情');

    final card = IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (emotion != null)
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: emotion.color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: emotion.color.withValues(alpha: 0.25),
                      blurRadius: 10),
                ],
              ),
              child: ClipOval(
                child: MoodFaceIcon(
                  type: emotion.faceType,
                  color: emotion.color,
                  size: 44,
                  moodId: emotion.id,
                  gender: gender,
                ),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateTitle,
                  style: TextStyle(
                    fontSize: viewingToday ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D3229),
                  ),
                ),
                if (emotion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    emotion.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: emotion.color,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.primary.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          if (canEdit && viewingToday)
            Icon(Icons.edit_rounded, color: palette.primary, size: 22),
        ],
      ),
    );

    if (!canEdit || !viewingToday) return card;
    return PressableFeedback(
      onTap: () => _editMood(context, ref),
      pressedScale: 0.98,
      semanticLabel: dateTitle,
      child: card,
    );
  }
}

class _MoodEditResult {
  const _MoodEditResult(this.before);

  final GrowthSummary? before;
}

class _MoodEditSheet extends ConsumerStatefulWidget {
  const _MoodEditSheet({
    required this.palette,
    required this.initialMoodId,
    required this.gender,
  });

  final MoodPalette palette;
  final String initialMoodId;
  final String? gender;

  @override
  ConsumerState<_MoodEditSheet> createState() => _MoodEditSheetState();
}

class _MoodEditSheetState extends ConsumerState<_MoodEditSheet> {
  bool _saving = false;
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialMoodId;
  }

  Future<void> _onSelected(String id) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _selectedId = id;
    });
    try {
      final before = await fetchCurrentGrowthSummary(ref);
      await ref.read(profileProvider.notifier).updateMood(id);
      final profile = ref.read(profileProvider).valueOrNull;
      try {
        await DailyMoodPromptStore(
          sync: ref.read(userAppPreferencesSyncProvider),
          userId: profile?.userId,
        ).markPickedToday();
      } catch (_) {}
      if (!mounted) return;
      Navigator.pop(context, _MoodEditResult(before));
    } on ApiException catch (error) {
      _showFailure(error.message);
    } catch (_) {
      _showFailure('心情修改失败，请稍后重试');
    }
  }

  void _showFailure(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.maybeOf(context) ??
        ScaffoldMessenger.maybeOf(
          Navigator.of(context, rootNavigator: true).context,
        );
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
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
            color: widget.palette.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '编辑今日感受',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: _saving
                    ? CompanionLoadingView(
                        palette: widget.palette,
                        companion: ref.watch(userCompanionProvider),
                        moodId: _selectedId,
                        message: '正在保存心情…',
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
