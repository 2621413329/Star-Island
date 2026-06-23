import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/companion_roles.dart';
import '../../core/constants/catalog.dart';
import '../../core/utils/moment_tags.dart';
import '../../design_system/moment_tag_chips.dart';
import '../../core/layout/app_layout.dart';
import '../../core/models/user_companion.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../design_system/user_companion_view.dart';
import '../../providers/app_providers.dart';
import '../../providers/story_day_provider.dart';
import 'edit_moment_sheet.dart';
import 'edit_moment_tags_page.dart';
import 'moment_mood_picker.dart';
import 'moment_photo_gallery.dart';
import 'story_companion_floater.dart';
import 'widgets/story_voice_bubble.dart';
import '../more/widgets/more_subpage_header.dart';

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

  Future<void> _openMoodPicker() async {
    final saved = await showMomentMoodPicker(context, ref, moment: _moment);
    if (saved == true && mounted) {
      await _refreshMoment();
    }
  }

  Future<void> _openEdit() async {
    final saved = await showEditMomentSheet(context, ref, moment: _moment);
    if (saved == true && mounted) {
      await _refreshMoment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日常已更新')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final companion = ref.watch(userCompanionProvider);
    final nickname = ref.watch(profileProvider).valueOrNull?.nickname;
    final voiceAnalyzingMessage = CompanionRoles.analyzingVoiceMessage(
      companion.companionRoleId,
    );
    final mood = moodById(_moment.emotionTag);
    final aiEmotion = momentAiEmotionLabel(_moment);
    final emotionChipLabel = aiEmotion == null
        ? null
        : '${CompanionRoles.emotionInsightPrefix(companion.companionRoleId)} · $aiEmotion';
    final note = _moment.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final storyDay = momentCalendarDate(_moment);

    const companionBottomInset = 8.0;
    const companionReserve = 48.0;

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoreSubpageHeader(
                title: '日常详情',
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
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.pageHorizontal,
                        8,
                        AppLayout.pageHorizontal,
                        companionBottomInset + companionReserve,
                      ),
                      children: [
                        _TagBreadcrumb(path: _tagPath, palette: palette),
                        const SizedBox(height: 10),
                        _MoodMetaRow(
                          mood: mood,
                          palette: palette,
                          gender: companion.gender,
                        ),
                        const SizedBox(height: 10),
                        MomentTagChipRow(
                          moment: _moment,
                          palette: palette,
                          maxSecondary: 6,
                          aiEmotionLabel: emotionChipLabel,
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
                        if (_moment.photos.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          MomentPhotoThumbnailStrip(photos: _moment.photos),
                        ],
                        const SizedBox(height: 20),
                        _StoryBodyCard(
                          palette: palette,
                          moment: _moment,
                          voiceAnalyzingMessage: voiceAnalyzingMessage,
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
                            label: '编辑这条日常',
                            palette: palette,
                            onPressed: _openEdit,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                    Positioned(
                      right: AppLayout.pageHorizontal,
                      bottom: companionBottomInset,
                      child: StoryCompanionFloater(
                        palette: palette,
                        companionKey: _companionKey,
                        companion: companion,
                        story: CompanionStoryContext.fromMoment(_moment),
                        size: 120,
                        expandedSize: 188,
                        summaryLines: _moment.storySummaryLinesFor(nickname),
                        onMoodEdit: _editable ? _openMoodPicker : null,
                      ),
                    ),
                  ],
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
  });

  final MoodOption mood;
  final MoodPalette palette;
  final String? gender;

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
          mood.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: mood.color,
          ),
        ),
      ],
    );
  }
}

class _StoryBodyCard extends StatelessWidget {
  const _StoryBodyCard({
    required this.palette,
    required this.moment,
    required this.voiceAnalyzingMessage,
  });

  final MoodPalette palette;
  final DailyMomentModel moment;
  final String voiceAnalyzingMessage;

  @override
  Widget build(BuildContext context) {
    final note = moment.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final hasVoice = moment.isVoice &&
        moment.voiceUrl != null &&
        moment.voiceDuration != null;

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
          if (hasVoice) ...[
            Row(
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 18,
                  color: palette.accent.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  '语音记录',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.accent.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StoryVoiceBubble(
              key: ValueKey(moment.voiceUrl ?? moment.id),
              voiceUrl: moment.voiceUrl!,
              durationSec: moment.voiceDuration!,
              accentColor: palette.accent,
            ),
            if (moment.speechText != null &&
                moment.speechText!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              SelectableText(
                moment.speechText!.trim(),
                style: appTextStyle(
                  fontSize: 16,
                  height: 1.65,
                  color: const Color(0xFF4A3F36),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (moment.speechStatus == 'pending') ...[
              const SizedBox(height: 12),
              Text(
                voiceAnalyzingMessage,
                style: appTextStyle(
                  fontSize: 13,
                  color: palette.primary.withValues(alpha: 0.55),
                ),
              ),
            ],
          ] else if (hasNote)
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
