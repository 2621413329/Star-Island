import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/utils/moment_tags.dart';
import '../../design_system/moment_tag_chips.dart';
import '../../core/layout/app_layout.dart';
import '../../core/models/user_companion.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/companion_speech_bubble.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../design_system/pressable_feedback.dart';
import '../../design_system/user_companion_view.dart';
import '../../providers/app_providers.dart';
import '../../providers/story_day_provider.dart';
import 'edit_moment_sheet.dart';
import 'edit_moment_tags_page.dart';
import 'moment_photo_section.dart';

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
    final primary = momentPrimaryCategory(_moment);
    final secondary = momentSecondaryTags(_moment);
    if (primary == null) return secondary;
    return [primary, ...secondary];
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

  Future<void> _openEditTags() async {
    final saved = await openEditMomentTagsPage(context, moment: _moment);
    if (saved == true && mounted) {
      await _refreshMoment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标签已更新')),
      );
    }
  }

  Future<void> _openEdit() async {
    final saved = await showEditMomentSheet(context, ref, moment: _moment);
    if (saved == true && mounted) {
      await _refreshMoment();
      if (!mounted) return;
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
    final aiEmotion = momentAiEmotionLabel(_moment);
    final note = _moment.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final storyDay = momentCalendarDate(_moment);

    const companionBottomInset = 12.0;
    const companionReserve =
        companionBottomInset + _FloatingCompanion.companionDisplaySize * 1.15 + 96;

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: palette.card.withValues(alpha: 0.94),
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    title: Text(
                      '故事详情',
                      style: appTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF5D4E44),
                    ),
                    actions: [
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.pageHorizontal,
                      8,
                      AppLayout.pageHorizontal,
                      companionBottomInset + companionReserve,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _TagBreadcrumb(path: _tagPath, palette: palette),
                        const SizedBox(height: 10),
                        _MoodMetaRow(
                          mood: mood,
                          palette: palette,
                          gender: companion.gender,
                          aiEmotionLabel: aiEmotion,
                        ),
                        const SizedBox(height: 10),
                        MomentTagChipRow(
                          moment: _moment,
                          palette: palette,
                          maxSecondary: 6,
                        ),
                        if (_editable) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _openEditTags,
                              icon: const Icon(Icons.sell_outlined, size: 18),
                              label: const Text('编辑标签'),
                              style: TextButton.styleFrom(
                                foregroundColor: palette.accent,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _StoryBodyCard(
                          palette: palette,
                          note: hasNote ? note : null,
                          photos: _moment.photos,
                        ),
                        const SizedBox(height: 20),
                        _RecordMetaRow(
                          palette: palette,
                          storyDayLabel: formatMomentDateLabel(storyDay),
                          recordTime: formatMomentRecordTime(_moment),
                        ),
                        if (_editable) ...[
                          const SizedBox(height: 24),
                          IslandPrimaryAction(
                            label: '编辑这条故事',
                            palette: palette,
                            onPressed: _openEdit,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ]),
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
                  summaryLines: _moment.storySummaryLines,
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.primary.withValues(alpha: 0.88),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodMetaRow extends StatelessWidget {
  const _MoodMetaRow({
    required this.mood,
    required this.palette,
    this.gender,
    this.aiEmotionLabel,
  });

  final MoodOption mood;
  final MoodPalette palette;
  final String? gender;
  final String? aiEmotionLabel;

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
          child: MoodFaceIcon(
            type: mood.faceType,
            color: mood.color,
            size: 28,
            strokeWidth: 2,
            moodId: mood.id,
            gender: gender,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'AI 感受 · ${aiEmotionLabel ?? mood.label}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A4E44),
          ),
        ),
      ],
    );
  }
}

class _StoryBodyCard extends StatelessWidget {
  const _StoryBodyCard({
    required this.palette,
    this.note,
    this.photos = const [],
  });

  final MoodPalette palette;
  final String? note;
  final List<MomentPhotoModel> photos;

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
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in photos)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      momentPhotoFullUrl(photo.urlPath),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 96,
                        height: 96,
                        color: const Color(0xFFECEFF1),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
              ],
            ),
          ],
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

class _FloatingCompanion extends StatefulWidget {
  static const companionDisplaySize = 216.0;

  const _FloatingCompanion({
    required this.palette,
    required this.companionKey,
    required this.companion,
    required this.story,
    required this.summaryLines,
  });

  final MoodPalette palette;
  final GlobalKey<UserCompanionViewState> companionKey;
  final UserCompanion companion;
  final CompanionStoryContext story;
  final List<String> summaryLines;

  @override
  State<_FloatingCompanion> createState() => _FloatingCompanionState();
}

class _FloatingCompanionState extends State<_FloatingCompanion> {
  static final _rnd = Random();
  String? _speechText;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
    final lines = widget.summaryLines;
    if (lines.isEmpty) return;
    _hideTimer?.cancel();
    setState(() {
      _speechText = lines[_rnd.nextInt(lines.length)];
    });
    await widget.companionKey.currentState?.playPerformance();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _speechText = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_speechText != null)
          Transform.translate(
            offset: const Offset(0, 28),
            child: CompanionSpeechBubble(
              text: _speechText!,
              palette: widget.palette,
              maxWidth: 260,
              tailTipInsetFromRight: _FloatingCompanion.companionDisplaySize / 2,
            ),
          ),
        PressableFeedback(
          onTap: () => unawaited(_onTap()),
          pressedScale: 0.94,
          semanticLabel: '点击小人听故事总结',
          child: UserCompanionView(
            key: widget.companionKey,
            companion: widget.companion,
            story: widget.story,
            size: _FloatingCompanion.companionDisplaySize,
            palette: widget.palette,
            showAura: false,
          ),
        ),
      ],
    );
  }
}
