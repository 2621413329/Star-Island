import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/models/companion_spec.dart';
import '../../core/models/user_companion.dart';
import '../../core/sync/client_event_id.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../core/utils/client_moment_factory.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/mood_face_selector.dart';
import '../../design_system/slow_progress_bar.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/mood_status_provider.dart';
import '../../design_system/user_companion_view.dart';
import '../../island/service/island_style_resolver.dart';
import 'moment_form_widgets.dart';
import 'moment_generating_panel.dart';
import 'widgets/story_flow_capsule_progress.dart';
import '../../island/viewport/growth_world_viewport.dart';

Future<void> showAddMomentFlow(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey<GrowthWorldViewportState>? islandKey,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => AddMomentFlowPage(islandKey: islandKey),
      transitionsBuilder: (_, animation, __, child) {
        final curve =
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    ),
  );
}

class AddMomentFlowPage extends ConsumerStatefulWidget {
  const AddMomentFlowPage({super.key, this.islandKey});

  final GlobalKey<GrowthWorldViewportState>? islandKey;

  @override
  ConsumerState<AddMomentFlowPage> createState() => _AddMomentFlowPageState();
}

class _AddMomentFlowPageState extends ConsumerState<AddMomentFlowPage> {
  int _step = 0;
  String? _event;
  String? _eventKeyword;
  String? _studySubject;
  String? _studyState;
  String? _mood;
  final _noteCtrl = TextEditingController();
  bool _generating = false;
  bool _performing = false;
  String _waitLine = defaultWaitingLines.first;
  Timer? _lineTimer;
  List<String> _waitLines = defaultWaitingLines;
  String _genScene = 'stargaze';
  String _genAction = 'wave';
  CompanionSpec? _genSpec;
  final GlobalKey<UserCompanionViewState> _previewCompanionKey = GlobalKey();
  final GlobalKey<SlowProgressBarState> _generatingProgressKey = GlobalKey();
  String? _pendingClientEventId;
  String? _pendingClientEventFingerprint;
  static const _previewMomentId = 'preview-mindscape-moment';

  @override
  void initState() {
    super.initState();
    _mood = ref.read(profileProvider).valueOrNull?.todayMood;
    _noteCtrl.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _noteCtrl.removeListener(_onDraftChanged);
    _noteCtrl.dispose();
    _lineTimer?.cancel();
    super.dispose();
  }

  void _onDraftChanged() {
    if (_eventTags.isNotEmpty && _mood != null && mounted) setState(() {});
  }

  bool get _isStudyEvent => _event == '学习';

  List<String> get _eventTags => [
        if (_event != null) _event!,
        if (!_isStudyEvent && _eventKeyword != null) _eventKeyword!,
        if (_isStudyEvent && _studySubject != null) _studySubject!,
        if (_isStudyEvent && _studySubject != '其他' && _studyState != null)
          _studyState!,
      ];

  String get _noteHint {
    if (_isStudyEvent && _studySubject != null) {
      final subject = _studySubject!;
      final state =
          _studyState == null || _studyState == '其他' ? '学习' : _studyState!;
      final prompts = [
        '例如：今天$subject$state时，我想记录一个卡住又想通的地方',
        '例如：这次$subject$state让我发现了一个还要继续练的小问题',
        '例如：今天$subject$state的过程里，有个瞬间让我很有感觉',
      ];
      return _pickDailyPrompt(prompts);
    }
    if (_event != null && _eventKeyword != null) {
      final prompts = [
        '例如：今天的$_eventKeyword和${_eventLabel(_event!)}有关，我想把这个瞬间说清楚',
        '例如：这次$_eventKeyword让我心里有点变化，想记录下来',
        '例如：今天$_eventKeyword发生后，我最想留住的是那一刻的感觉',
      ];
      return _pickDailyPrompt(prompts);
    }
    final tag = _event ?? '其它';
    final prompts = notePromptPools[tag] ?? notePromptPools['其它']!;
    return _pickDailyPrompt(prompts);
  }

  String _eventLabel(String eventId) {
    return eventTags
        .firstWhere((tag) => tag.id == eventId, orElse: () => eventTags.last)
        .label;
  }

  String _draftFingerprint(String? note) {
    return '${_eventTags.join('|')}::${_mood ?? ''}::${note ?? ''}';
  }

  String _pickDailyPrompt(List<String> prompts) {
    final today = DateTime.now();
    final seedText =
        '${today.year}-${today.month}-${today.day}-${_event ?? ''}-${_studySubject ?? ''}-${_studyState ?? ''}-${_mood ?? ''}';
    final seed = seedText.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return prompts[seed % prompts.length];
  }

  DailyMomentModel? _buildPreviewMoment(String companionStyle) {
    if (_eventTags.isEmpty || _mood == null) return null;
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final draft = ClientMomentFactory.build(
      eventTags: _eventTags,
      emotionTag: _mood!,
      note: note,
      companionStyle: companionStyle,
    );
    return DailyMomentModel(
      id: _previewMomentId,
      eventTags: draft.eventTags,
      emotionTag: draft.emotionTag,
      note: draft.note,
      companionScene: draft.companionScene,
      companionPose: draft.companionPose,
      momentDate: draft.momentDate,
      createdAt: draft.createdAt,
      visualPayload: draft.visualPayload,
    );
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

  void _goBack() {
    if (_generating) return;
    if (_step <= 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step = _previousStep(_step));
  }

  void _goForward() {
    if (_generating || !_canGoForward()) return;
    setState(() => _step = _nextStep(_step));
  }

  int _nextStep(int current) {
    switch (current) {
      case 0:
        return _event != null ? 1 : 0;
      case 1:
        if (_isStudyEvent) {
          if (_studySubject == null) return 1;
          return _studySubject == '其他' ? 3 : 2;
        }
        return _eventKeyword != null ? 3 : 1;
      case 2:
        return _studyState != null ? 3 : 2;
      case 3:
        return _mood != null ? 4 : 3;
      default:
        return current;
    }
  }

  bool _canGoForward() => !_generating && _nextStep(_step) != _step;

  bool _canSwipeBack() => !_generating && _step > 0;

  int get _flowStepCount {
    if (_event == null) return 4;
    if (!_isStudyEvent) return 4;
    if (_studySubject == null) return 5;
    if (_studySubject == '其他') return 4;
    return 5;
  }

  int get _flowStepIndex {
    if (_step <= 1) return _step;
    if (_step == 2) return 2;
    final skipStudyState = !_isStudyEvent || _studySubject == '其他';
    if (_step == 3) return skipStudyState ? 2 : 3;
    if (_step == 4) return skipStudyState ? 3 : 4;
    return 0;
  }

  double get _flowProgress => (_flowStepIndex + 1) / _flowStepCount;

  String get _stepTitle {
    switch (_step) {
      case 0:
        return '选分类';
      case 1:
        return _isStudyEvent ? '选学科' : '选关键词';
      case 2:
        return '学习状态';
      case 3:
        return '选心情';
      case 4:
        return '写记录';
      default:
        return '';
    }
  }

  int _previousStep(int current) {
    switch (current) {
      case 4:
        return 3;
      case 3:
        if (_isStudyEvent) {
          return _studySubject == '其他' ? 1 : 2;
        }
        return 1;
      case 2:
        return 1;
      case 1:
        return 0;
      default:
        return 0;
    }
  }

  Future<void> _submit() async {
    if (_generating) return;
    if (_eventTags.isEmpty || _mood == null) return;
    final style =
        ref.read(profileProvider).valueOrNull?.companionStyle ?? 'chibi';
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final fingerprint = _draftFingerprint(note);
    if (_pendingClientEventId == null ||
        _pendingClientEventFingerprint != fingerprint) {
      _pendingClientEventId = ClientEventId.next('daily-moment');
      _pendingClientEventFingerprint = fingerprint;
    }
    final clientEventId = _pendingClientEventId!;
    final preview = ClientMomentFactory.build(
      eventTags: _eventTags,
      emotionTag: _mood!,
      note: note,
      companionStyle: style,
    );
    setState(() {
      _generating = true;
      _genScene = preview.companionScene;
      _genAction = preview.actionType;
      _genSpec = preview.companionSpec;
      _performing = false;
    });
    _startWaitLines(preview.waitingLines);
    try {
      final moment = await ref.read(todayMomentsProvider.notifier).add(
            eventTags: _eventTags,
            emotionTag: _mood!,
            clientEventId: clientEventId,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (moment.waitingLines.isNotEmpty) _startWaitLines(moment.waitingLines);
      _generatingProgressKey.currentState?.complete();
      if (mounted) {
        setState(() {
          _genScene = moment.companionScene;
          _genAction = moment.actionType;
          _genSpec = moment.companionSpec;
          _performing = true;
          _waitLine = moment.performanceHint ?? moment.sceneTitle ?? '小星来岛上啦！';
        });
      }
      _syncDailyMoodReportSilently();
      ref.invalidate(growthSummaryProvider);
      await ref.read(growthSummaryProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 2400));
      _pendingClientEventId = null;
      _pendingClientEventFingerprint = null;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：$e\n请确认后端已启动')),
        );
        setState(() => _performing = false);
      }
    } finally {
      _lineTimer?.cancel();
      if (mounted) setState(() => _generating = false);
    }
  }

  void _syncDailyMoodReportSilently() {
    unawaited(
      ref.read(appRepositoryProvider).uploadDailyMoodReport().then((_) {
        ref.invalidate(moodReportCheckInProvider);
        ref.invalidate(moodStatusViewProvider);
        ref.invalidate(growthSummaryProvider);
      }).catchError((_) {
        // 整理失败不阻塞继续记录，可稍后重试。
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final companion = ref.watch(userCompanionProvider);
    final style = companion.renderStyle;
    final moodId = _mood ?? profile?.todayMood;
    final islandConfig = const IslandStyleResolver().resolve(moodId: moodId);
    final previewMoment = _buildPreviewMoment(style);
    const previewHeight = 180.0;
    const previewZoom = 1.28;

    return PopScope(
      canPop: !_generating && _step <= 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _generating) return;
        _goBack();
      },
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        child: IslandScaffold(
          palette: palette,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _generating ? null : _goBack,
                    tooltip: _step <= 0 ? '返回' : '返回上一级',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOutCubic,
                  height: _generating ? 120 : previewHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: IslandPreviewWindow(
                    child: GrowthWorldViewport(
                      moodId: moodId,
                      palette: palette,
                      islandConfig: islandConfig,
                      companionStyle: style,
                      moments: previewMoment == null ? const [] : [previewMoment],
                      compact: true,
                      previewZoom: previewZoom,
                      interactive: false,
                      force2D: true,
                    ),
                  ),
                ),
                if (!_generating)
                  StoryFlowCapsuleProgress(
                    progress: _flowProgress,
                    stepIndex: _flowStepIndex,
                    stepCount: _flowStepCount,
                    stepTitle: _stepTitle,
                    palette: palette,
                    canSwipeBack: _canSwipeBack(),
                    canSwipeForward: _canGoForward(),
                    onSwipeBack: _goBack,
                    onSwipeForward: _goForward,
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _generating
                        ? MomentGeneratingPanel(
                            key: const ValueKey('generating'),
                            palette: palette,
                            companion: companion,
                            story: CompanionStoryContext(
                              spec: _genSpec ??
                                  CompanionSpec(
                                    expression: 'calm',
                                    prop: 'none',
                                    animationType: _genAction,
                                    tint: palette.accent,
                                  ),
                              scene: _genScene,
                            ),
                            line: _waitLine,
                            companionKey: _previewCompanionKey,
                            progressKey: _generatingProgressKey,
                            performing: _performing,
                          )
                        : _step == 0
                            ? _EventStep(
                                key: const ValueKey('e'),
                                selected: _event,
                                onPick: (e) => setState(() {
                                  _event = e;
                                  _eventKeyword = null;
                                  _studySubject = null;
                                  _studyState = null;
                                  _step = 1;
                                }),
                              )
                            : _step == 1
                                ? _isStudyEvent
                                    ? _StudySubjectStep(
                                        key: const ValueKey('subject'),
                                        selected: _studySubject,
                                        onPick: (subject) => setState(() {
                                          _studySubject = subject;
                                          _studyState = null;
                                          _step = subject == '其他' ? 3 : 2;
                                        }),
                                      )
                                    : _KeywordStep(
                                        key:
                                            ValueKey('keyword-${_event ?? ''}'),
                                        title: '选择一个关键词',
                                        selected: _eventKeyword,
                                        options: momentKeywordTags[_event] ??
                                            momentKeywordTags['其它']!,
                                        onPick: (keyword) => setState(() {
                                          _eventKeyword = keyword;
                                          _step = 3;
                                        }),
                                      )
                                : _step == 2
                                    ? _StudyStateStep(
                                        key: const ValueKey('study-state'),
                                        selected: _studyState,
                                        onPick: (state) => setState(() {
                                          _studyState = state;
                                          _step = 3;
                                        }),
                                      )
                                    : _step == 3
                                        ? _MoodStep(
                                            key: const ValueKey('m'),
                                            selected: _mood,
                                            gender: ref
                                                .watch(profileProvider)
                                                .valueOrNull
                                                ?.gender,
                                            onPick: (m) => setState(() {
                                              _mood = m;
                                              _step = 4;
                                            }),
                                          )
                                        : _NoteStep(
                                            key: const ValueKey('n'),
                                            controller: _noteCtrl,
                                            palette: palette,
                                            hintText: _noteHint,
                                            onSubmit: _submit,
                                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventStep extends StatelessWidget {
  const _EventStep({super.key, required this.selected, required this.onPick});
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('发生了什么？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: MomentTagSelector(
                selected: selected,
                storyCardLayout: true,
                options: eventTags
                    .map((t) => MomentTagChoice(
                          id: t.id,
                          label: t.label,
                          emoji: t.emoji,
                          color: t.color,
                          asset: t.asset,
                        ))
                    .toList(),
                onPick: onPick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudySubjectStep extends StatelessWidget {
  const _StudySubjectStep(
      {super.key, required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('是哪门学科？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: MomentTagSelector(
                selected: selected,
                options: studySubjectTags
                    .map((t) => MomentTagChoice(
                          id: t.id,
                          label: t.label,
                          icon: t.icon,
                          color: t.color,
                          asset: t.asset,
                        ))
                    .toList(),
                onPick: onPick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyStateStep extends StatelessWidget {
  const _StudyStateStep(
      {super.key, required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今天的学习状态？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: MomentTagSelector(
                selected: selected,
                options: studyStateTags
                    .map((t) => MomentTagChoice(
                          id: t.id,
                          label: t.label,
                          icon: t.icon,
                          color: t.color,
                          asset: t.asset,
                        ))
                    .toList(),
                onPick: onPick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordStep extends StatelessWidget {
  const _KeywordStep({
    super.key,
    required this.title,
    required this.selected,
    required this.options,
    required this.onPick,
  });

  final String title;
  final String? selected;
  final List<MomentDetailOption> options;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: MomentTagSelector(
                selected: selected,
                options: options
                    .map((t) => MomentTagChoice(
                          id: t.id,
                          label: t.label,
                          icon: t.icon,
                          color: t.color,
                          asset: t.asset,
                        ))
                    .toList(),
                onPick: onPick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({
    super.key,
    required this.selected,
    required this.onPick,
    this.gender,
  });
  final String? selected;
  final ValueChanged<String> onPick;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text('此刻心情如何？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: MoodFaceSelector(
                selectedId: selected,
                onSelected: onPick,
                size: 50,
                gender: gender,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteStep extends StatelessWidget {
  const _NoteStep(
      {super.key,
      required this.controller,
      required this.palette,
      required this.hintText,
      required this.onSubmit});
  final TextEditingController controller;
  final MoodPalette palette;
  final String hintText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('有什么想说的吗？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: MomentNoteField(
                controller: controller,
                hintText: hintText,
                fillColor: palette.card,
                minLines: 4,
                maxLines: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          IslandPrimaryAction(
              label: '把这段经历放进世界', palette: palette, onPressed: onSubmit),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
