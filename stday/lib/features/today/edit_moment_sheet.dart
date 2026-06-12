import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/models/companion_spec.dart';
import '../../core/models/user_companion.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/client_moment_factory.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/utils/moment_form_state.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/mood_face_selector.dart';
import '../../design_system/slow_progress_bar.dart';
import '../../providers/app_providers.dart';
import '../../design_system/user_companion_view.dart';
import 'moment_form_widgets.dart';
import 'moment_generating_panel.dart';

Future<bool?> showEditMomentSheet(
  BuildContext context,
  WidgetRef ref, {
  required DailyMomentModel moment,
}) {
  if (!isMomentToday(moment)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('仅今日故事可以修改')),
    );
    return Future.value(false);
  }
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: EditMomentSheet(moment: moment),
    ),
  );
}

class EditMomentSheet extends ConsumerStatefulWidget {
  const EditMomentSheet({super.key, required this.moment});

  final DailyMomentModel moment;

  @override
  ConsumerState<EditMomentSheet> createState() => _EditMomentSheetState();
}

class _EditMomentSheetState extends ConsumerState<EditMomentSheet> {
  late final MomentFormState _form;
  late final TextEditingController _noteCtrl;
  bool _saving = false;
  bool _performing = false;
  String _waitLine = defaultWaitingLines.first;
  List<String> _waitLines = defaultWaitingLines;
  Timer? _lineTimer;
  Timer? _previewDebounce;
  String _genScene = 'stargaze';
  CompanionSpec? _genSpec;
  final GlobalKey<UserCompanionViewState> _previewKey = GlobalKey();
  final GlobalKey<UserCompanionViewState> _companionKey = GlobalKey();
  final GlobalKey<SlowProgressBarState> _progressKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _form = MomentFormState.fromMoment(widget.moment);
    _noteCtrl = TextEditingController(text: widget.moment.note ?? '');
    _applyMomentPreview(widget.moment);
    _noteCtrl.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    _previewDebounce?.cancel();
    _noteCtrl.removeListener(_onNoteChanged);
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    _previewDebounce?.cancel();
    _previewDebounce =
        Timer(const Duration(milliseconds: 280), _refreshLivePreview);
  }

  void _applyMomentPreview(DailyMomentModel moment) {
    _genScene = moment.companionScene;
    _genSpec = moment.companionSpec;
  }

  void _refreshLivePreview() {
    if (!mounted || _saving) return;
    if (!_form.isValid) {
      setState(() => _applyMomentPreview(widget.moment));
      return;
    }
    final style =
        ref.read(profileProvider).valueOrNull?.companionStyle ?? 'chibi';
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final draft = ClientMomentFactory.build(
      eventTags: _form.eventTags,
      emotionTag: _form.mood!,
      note: note,
      companionStyle: style,
    );
    setState(() {
      _genScene = draft.companionScene;
      _genSpec = draft.companionSpec;
    });
  }

  void _onFormChanged() {
    _refreshLivePreview();
  }

  Future<void> _playPreviewCompanion() async {
    HapticFeedback.lightImpact();
    await _previewKey.currentState?.playPerformance();
  }

  String get _noteHint {
    if (_form.isStudyEvent && _form.studySubject != null) {
      return '例如：今天${_form.studySubject}学习时，想改一改记录';
    }
    if (_form.event != null && _form.eventKeyword != null) {
      return '例如：关于${_form.eventKeyword}的${_form.event}故事';
    }
    final tag = _form.event ?? '其它';
    final prompts = notePromptPools[tag] ?? notePromptPools['其它']!;
    return prompts.first;
  }

  void _startWaitLines(List<String> lines) {
    _waitLines = lines.isNotEmpty ? lines : defaultWaitingLines;
    var idx = 0;
    _waitLine = _waitLines.first;
    _lineTimer?.cancel();
    _lineTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (!mounted) return;
      setState(() {
        idx = (idx + 1) % _waitLines.length;
        _waitLine = _waitLines[idx];
      });
    });
  }

  Future<void> _save() async {
    if (!isMomentToday(widget.moment)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('仅今日故事可以修改')),
        );
      }
      return;
    }
    if (!_form.isValid || _saving) return;
    final style =
        ref.read(profileProvider).valueOrNull?.companionStyle ?? 'chibi';
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final preview = ClientMomentFactory.build(
      eventTags: _form.eventTags,
      emotionTag: _form.mood!,
      note: note,
      companionStyle: style,
    );

    setState(() {
      _saving = true;
      _performing = false;
      _genScene = preview.companionScene;
      _genSpec = preview.companionSpec;
    });
    _startWaitLines(preview.waitingLines);

    try {
      final moment = await ref.read(todayMomentsProvider.notifier).updateMoment(
            id: widget.moment.id,
            eventTags: _form.eventTags,
            emotionTag: _form.mood!,
            note: note,
          );
      if (moment.waitingLines.isNotEmpty) {
        _startWaitLines(moment.waitingLines);
      }
      _progressKey.currentState?.complete();
      if (mounted) {
        setState(() {
          _genScene = moment.companionScene;
          _genSpec = moment.companionSpec;
          _performing = true;
          _waitLine = moment.performanceHint ?? moment.sceneTitle ?? '小星更新好啦～';
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 2400));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
        setState(() {
          _saving = false;
          _performing = false;
        });
      }
    } finally {
      _lineTimer?.cancel();
    }
  }

  CompanionStoryContext get _previewStory => CompanionStoryContext(
        spec: _genSpec ?? widget.moment.companionSpec,
        scene: _genScene,
        pose: widget.moment.companionPose,
      );

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final companion = ref.watch(userCompanionProvider);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      height: sheetHeight,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 4, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      '编辑今日故事',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_saving) ...[
                _CompanionPreviewStrip(
                  palette: palette,
                  companion: companion,
                  story: _previewStory,
                  previewKey: _previewKey,
                  onTap: _playPreviewCompanion,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('发生了什么？'),
                        const SizedBox(height: 10),
                        MomentTagSelector(
                          selected: _form.event,
                          storyCardLayout: true,
                          options: eventTags
                              .map(
                                (t) => MomentTagChoice(
                                  id: t.id,
                                  label: t.label,
                                  emoji: t.emoji,
                                  color: t.color,
                                  asset: t.asset,
                                ),
                              )
                              .toList(),
                          onPick: (e) {
                            _form.event = e;
                            _form.eventKeyword = null;
                            _form.studySubject = null;
                            _form.studyState = null;
                            _onFormChanged();
                          },
                        ),
                        if (_form.isStudyEvent) ...[
                          const SizedBox(height: 20),
                          _sectionTitle('学科'),
                          const SizedBox(height: 10),
                          MomentTagSelector(
                            selected: _form.studySubject,
                            options: studySubjectTags
                                .map(
                                  (t) => MomentTagChoice(
                                    id: t.id,
                                    label: t.label,
                                    icon: t.icon,
                                    color: t.color,
                                    asset: t.asset,
                                  ),
                                )
                                .toList(),
                            onPick: (v) {
                              _form.studySubject = v;
                              if (v == '其他') _form.studyState = null;
                              _onFormChanged();
                            },
                          ),
                          if (_form.studySubject != null &&
                              _form.studySubject != '其他') ...[
                            const SizedBox(height: 20),
                            _sectionTitle('学习状态'),
                            const SizedBox(height: 10),
                            MomentTagSelector(
                              selected: _form.studyState,
                              options: studyStateTags
                                  .map(
                                    (t) => MomentTagChoice(
                                      id: t.id,
                                      label: t.label,
                                      icon: t.icon,
                                      color: t.color,
                                      asset: t.asset,
                                    ),
                                  )
                                  .toList(),
                              onPick: (v) {
                                _form.studyState = v;
                                _onFormChanged();
                              },
                            ),
                          ],
                        ] else if (_form.event != null) ...[
                          const SizedBox(height: 20),
                          _sectionTitle('关键词'),
                          const SizedBox(height: 10),
                          MomentTagSelector(
                            selected: _form.eventKeyword,
                            options: (momentKeywordTags[_form.event] ??
                                    momentKeywordTags['其它']!)
                                .map(
                                  (t) => MomentTagChoice(
                                    id: t.id,
                                    label: t.label,
                                    icon: t.icon,
                                    color: t.color,
                                    asset: t.asset,
                                  ),
                                )
                                .toList(),
                            onPick: (v) {
                              _form.eventKeyword = v;
                              _onFormChanged();
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        _sectionTitle('当时心情'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: MoodFaceSelector(
                            selectedId: _form.mood,
                            size: 48,
                            gender: ref.watch(profileProvider).valueOrNull?.gender,
                            onSelected: (m) {
                              _form.mood = m;
                              _onFormChanged();
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle('补充说明'),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: MomentNoteField(
                            controller: _noteCtrl,
                            textAlign: TextAlign.center,
                            hintText: _noteHint,
                            fillColor: palette.primaryContainer
                                .withValues(alpha: 0.35),
                            minLines: 4,
                            maxLines: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: IslandPrimaryAction(
                    label: '保存修改',
                    palette: palette,
                    onPressed: _form.isValid ? _save : null,
                  ),
                ),
              ],
            ],
          ),
          if (_saving)
            Container(
              decoration: BoxDecoration(
                color: palette.card.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
              ),
              child: MomentGeneratingPanel(
                palette: palette,
                companion: companion,
                story: _previewStory,
                line: _waitLine,
                companionKey: _companionKey,
                progressKey: _progressKey,
                performing: _performing,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      );
}

class _CompanionPreviewStrip extends StatelessWidget {
  const _CompanionPreviewStrip({
    required this.palette,
    required this.companion,
    required this.story,
    required this.previewKey,
    required this.onTap,
  });

  final MoodPalette palette;
  final UserCompanion companion;
  final CompanionStoryContext story;
  final GlobalKey<UserCompanionViewState> previewKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: palette.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.accent.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 108,
                width: 108,
                child: UserCompanionView(
                  key: previewKey,
                  companion: companion,
                  story: story,
                  size: 92,
                  palette: palette,
                ),
              ),
              Text(
                '点我互动',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
