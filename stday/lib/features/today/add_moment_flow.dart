import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/constants/catalog.dart';
import '../../core/models/companion_spec.dart';
import '../../core/models/mood_island_config.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../core/utils/client_moment_factory.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/mood_face_selector.dart';
import '../../design_system/slow_progress_bar.dart';
import '../../providers/app_providers.dart';
import 'widgets/growth_world_viewport.dart';

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
  final GlobalKey<CompanionAvatarState> _previewCompanionKey = GlobalKey();
  final GlobalKey<SlowProgressBarState> _generatingProgressKey = GlobalKey();
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
        if (_isStudyEvent && _studySubject != '自定义' && _studyState != null)
          _studyState!,
      ];

  String get _noteHint {
    if (_isStudyEvent && _studySubject != null) {
      final subject = _studySubject!;
      final state =
          _studyState == null || _studyState == '自定义' ? '学习' : _studyState!;
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

  Future<void> _submit() async {
    if (_eventTags.isEmpty || _mood == null) return;
    final style =
        ref.read(profileProvider).valueOrNull?.companionStyle ?? 'chibi';
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
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
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _previewCompanionKey.currentState?.playPerformance();
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：$e\n请确认后端已启动')),
        );
      }
    } finally {
      _lineTimer?.cancel();
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final style = profile?.companionStyle == 'chibi'
        ? 'mindscape'
        : (profile?.companionStyle ?? 'mindscape');
    final moodId = _mood ?? profile?.todayMood;
    final islandRegistry = ref.watch(moodIslandRegistryProvider).valueOrNull ??
        MoodIslandRegistry.defaults();
    final islandConfig = islandRegistry.resolve(moodId);
    final islandScale =
        _generating ? 0.35 : (1.0 - _step * 0.12).clamp(0.55, 1.0);
    final previewMoment = _buildPreviewMoment(style);

    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _generating ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOutCubic,
                height: _generating ? 120 : 200 - _step * 24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: GrowthWorldViewport(
                  moodId: moodId,
                  palette: palette,
                  islandConfig: islandConfig,
                  companionStyle: style,
                  moments: previewMoment == null ? const [] : [previewMoment],
                  scale: islandScale,
                  compact: false,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _generating
                      ? _GeneratingPanel(
                          key: ValueKey('g$_performing'),
                          palette: palette,
                          style: style,
                          scene: _genScene,
                          actionType: _genAction,
                          spec: _genSpec,
                          gender: profile?.gender,
                          line: _waitLine,
                          companionKey: _previewCompanionKey,
                          progressKey: _generatingProgressKey,
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
                                        _step = subject == '自定义' ? 3 : 2;
                                      }),
                                    )
                                  : _KeywordStep(
                                      key: ValueKey('keyword-${_event ?? ''}'),
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
          _MomentTagSelector(
            selected: selected,
            options: eventTags
                .map((t) => _MomentTagChoice(
                      id: t.id,
                      label: t.label,
                      emoji: t.emoji,
                      color: t.color,
                    ))
                .toList(),
            onPick: onPick,
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
              child: _MomentTagSelector(
                selected: selected,
                options: studySubjectTags
                    .map((t) => _MomentTagChoice(
                          id: t.id,
                          label: t.label,
                          icon: t.icon,
                          color: t.color,
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
          _MomentTagSelector(
            selected: selected,
            options: studyStateTags
                .map((t) => _MomentTagChoice(
                      id: t.id,
                      label: t.label,
                      icon: t.icon,
                      color: t.color,
                    ))
                .toList(),
            onPick: onPick,
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
              child: _MomentTagSelector(
                selected: selected,
                options: options
                    .map((t) => _MomentTagChoice(
                          id: t.id,
                          label: t.label,
                          icon: t.icon,
                          color: t.color,
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

class _MomentTagChoice {
  const _MomentTagChoice({
    required this.id,
    required this.label,
    required this.color,
    this.emoji,
    this.icon,
  });

  final String id;
  final String label;
  final Color color;
  final String? emoji;
  final IconData? icon;
}

class _MomentTagSelector extends StatelessWidget {
  const _MomentTagSelector({
    required this.selected,
    required this.options,
    required this.onPick,
  });

  final String? selected;
  final List<_MomentTagChoice> options;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: options
          .map((option) => _MomentTagButton(
                option: option,
                selected: selected == option.id,
                onTap: () => onPick(option.id),
              ))
          .toList(),
    );
  }
}

class _MomentTagButton extends StatefulWidget {
  const _MomentTagButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _MomentTagChoice option;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MomentTagButton> createState() => _MomentTagButtonState();
}

class _MomentTagButtonState extends State<_MomentTagButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _MomentTagButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _pulse.forward(from: 0).then((_) => _pulse.reverse());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.option.color;
    final scale = 1.0 + (_pulse.value * 0.12);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: widget.selected ? 1.08 * scale : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  border: Border.all(
                      color: color, width: widget.selected ? 3 : 1.5),
                  boxShadow: widget.selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.32),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: widget.option.icon != null
                    ? Icon(widget.option.icon, color: color, size: 30)
                    : Text(widget.option.emoji ?? '•',
                        style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.option.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({super.key, required this.selected, required this.onPick});
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text('此刻心情如何？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          MoodFaceSelector(selectedId: selected, onSelected: onPick, size: 50),
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
          TextField(
            controller: controller,
            maxLength: 80,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: palette.card,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const Spacer(),
          IslandPrimaryAction(
              label: '把这段经历放进世界', palette: palette, onPressed: onSubmit),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GeneratingPanel extends StatefulWidget {
  const _GeneratingPanel({
    super.key,
    required this.palette,
    required this.style,
    required this.scene,
    required this.actionType,
    this.spec,
    this.gender,
    required this.line,
    required this.companionKey,
    required this.progressKey,
  });

  final MoodPalette palette;
  final String style;
  final String scene;
  final String actionType;
  final CompanionSpec? spec;
  final String? gender;
  final String line;
  final GlobalKey<CompanionAvatarState> companionKey;
  final GlobalKey<SlowProgressBarState> progressKey;

  @override
  State<_GeneratingPanel> createState() => _GeneratingPanelState();
}

class _GeneratingPanelState extends State<_GeneratingPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.companionKey.currentState?.playPerformance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CompanionAvatar(
          key: widget.companionKey,
          style: widget.style,
          scene: widget.scene,
          actionType: widget.actionType,
          spec: widget.spec,
          gender: widget.gender,
          size: 120,
          palette: widget.palette,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(widget.line,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SlowProgressBar(
            key: widget.progressKey,
            palette: widget.palette,
            duration: const Duration(seconds: 14),
          ),
        ),
      ],
    );
  }
}
