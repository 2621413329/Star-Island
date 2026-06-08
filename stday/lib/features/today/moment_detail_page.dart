import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/layout/app_layout.dart';
import '../../core/models/user_companion.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_painter.dart';
import '../../design_system/pressable_feedback.dart';
import '../../design_system/user_companion_view.dart';
import '../../providers/app_providers.dart';
import '../../providers/story_day_provider.dart';
import 'edit_moment_sheet.dart';

Future<void> openMomentDetailPage(
  BuildContext context, {
  required DailyMomentModel moment,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => MomentDetailPage(moment: moment),
    ),
  );
}

class MomentDetailPage extends ConsumerStatefulWidget {
  const MomentDetailPage({super.key, required this.moment});

  final DailyMomentModel moment;

  @override
  ConsumerState<MomentDetailPage> createState() => _MomentDetailPageState();
}

class _MomentDetailPageState extends ConsumerState<MomentDetailPage> {
  final GlobalKey<UserCompanionViewState> _companionKey = GlobalKey();
  late DailyMomentModel _moment;

  @override
  void initState() {
    super.initState();
    _moment = widget.moment;
  }

  bool get _editable => isMomentToday(_moment);

  List<String> get _tagPath {
    final tags = _moment.eventTags;
    if (tags.isEmpty) return const [];
    final labels = <String>[];
    final primary = eventTags.firstWhere(
      (e) => e.id == tags.first,
      orElse: () => eventTags.last,
    );
    labels.add(primary.label);
    for (var i = 1; i < tags.length; i++) {
      if (tags[i] != '其他') labels.add(tags[i]);
    }
    return labels;
  }

  Future<void> _refreshMoment() async {
    await ref.read(storyDayViewProvider.notifier).refresh();
    await ref.read(todayMomentsProvider.notifier).refresh();
    if (!mounted) return;
    final view = ref.read(storyDayViewProvider).valueOrNull;
    final updated = view?.moments
        .where((m) => m.id == _moment.id)
        .firstOrNull;
    if (updated != null) {
      setState(() => _moment = updated);
    }
  }

  Future<void> _openEdit() async {
    final saved = await showEditMomentSheet(context, ref, moment: _moment);
    if (saved == true && mounted) {
      await _refreshMoment();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('故事已更新')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final companion = ref.watch(userCompanionProvider);
    final mood = moodById(_moment.emotionTag);
    final note = _moment.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final storyDay = momentCalendarDate(_moment);

    final companionBottomInset = _editable ? 92.0 : 20.0;

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      4,
                      4,
                      AppLayout.pageHorizontal,
                      0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: const Color(0xFF5D4E44),
                        ),
                        Expanded(
                          child: Text(
                            '故事详情',
                            style: appTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D3229),
                            ),
                          ),
                        ),
                        if (_editable)
                          TextButton.icon(
                            onPressed: _openEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('编辑'),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppLayout.pageHorizontal,
                        8,
                        AppLayout.pageHorizontal,
                        companionBottomInset + 88,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TagBreadcrumb(path: _tagPath, palette: palette),
                          const SizedBox(height: 10),
                          _MoodMetaRow(mood: mood, palette: palette),
                          const SizedBox(height: 20),
                          _StoryBodyCard(
                            palette: palette,
                            note: hasNote ? note! : null,
                          ),
                          const SizedBox(height: 20),
                          _RecordMetaRow(
                            palette: palette,
                            storyDayLabel: formatMomentDateLabel(storyDay),
                            recordTime: formatMomentRecordTime(_moment),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_editable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.pageHorizontal,
                        0,
                        AppLayout.pageHorizontal,
                        16,
                      ),
                      child: IslandPrimaryAction(
                        label: '编辑这条故事',
                        palette: palette,
                        onPressed: _openEdit,
                      ),
                    ),
                ],
              ),
              Positioned(
                right: AppLayout.pageHorizontal,
                bottom: companionBottomInset,
                child: _FloatingCompanion(
                  palette: palette,
                  companionKey: _companionKey,
                  companion: companion,
                  story: CompanionStoryContext.fromMoment(_moment),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagBreadcrumb extends StatelessWidget {
  const _TagBreadcrumb({required this.path, required this.palette});

  final List<String> path;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Text(
        '未分类瞬间',
        style: TextStyle(
          fontSize: 12,
          color: palette.primary.withValues(alpha: 0.5),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: [
        for (var i = 0; i < path.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: palette.primary.withValues(alpha: 0.35),
              ),
            ),
          Text(
            path[i],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.primary.withValues(alpha: 0.55),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodMetaRow extends StatelessWidget {
  const _MoodMetaRow({required this.mood, required this.palette});

  final MoodOption mood;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mood.color.withValues(alpha: 0.12),
          ),
          child: CustomPaint(
            painter: MoodFacePainter(
              type: mood.faceType,
              color: mood.color,
              strokeWidth: 2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '当时心情 · ${mood.label}',
          style: TextStyle(
            fontSize: 13,
            color: palette.primary.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _StoryBodyCard extends StatelessWidget {
  const _StoryBodyCard({required this.palette, this.note});

  final MoodPalette palette;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: palette.card.withValues(alpha: 0.96),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.1),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我的记录',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: palette.accent.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          if (hasNote)
            SelectableText(
              note!,
              style: appTextStyle(
                fontSize: 18,
                height: 1.7,
                color: const Color(0xFF4A3F36),
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              '这一刻没有写下文字，但心情已经被小岛记住了。',
              style: appTextStyle(
                fontSize: 16,
                height: 1.6,
                color: palette.primary.withValues(alpha: 0.45),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordMetaRow extends StatelessWidget {
  const _RecordMetaRow({
    required this.palette,
    required this.storyDayLabel,
    required this.recordTime,
  });

  final MoodPalette palette;
  final String storyDayLabel;
  final String recordTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 15,
          color: palette.primary.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        Text(
          '$storyDayLabel · $recordTime',
          style: TextStyle(
            fontSize: 13,
            color: palette.primary.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _FloatingCompanion extends StatelessWidget {
  const _FloatingCompanion({
    required this.palette,
    required this.companionKey,
    required this.companion,
    required this.story,
  });

  final MoodPalette palette;
  final GlobalKey<UserCompanionViewState> companionKey;
  final UserCompanion companion;
  final CompanionStoryContext story;

  @override
  Widget build(BuildContext context) {
    return PressableFeedback(
      onTap: () => companionKey.currentState?.playPerformance(),
      pressedScale: 0.94,
      semanticLabel: '播放故事小人表演',
      child: UserCompanionView(
        key: companionKey,
        companion: companion,
        story: story,
        size: 72,
        palette: palette,
        showAura: false,
      ),
    );
  }
}
