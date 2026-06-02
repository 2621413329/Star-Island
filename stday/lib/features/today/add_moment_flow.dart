import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/models/companion_spec.dart';
import '../../core/models/mood_island_config.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/growth_island_scene.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../core/utils/client_moment_factory.dart';
import '../../design_system/mood_face_selector.dart';
import '../../design_system/slow_progress_bar.dart';
import '../../providers/app_providers.dart';

Future<void> showAddMomentFlow(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey<GrowthIslandSceneState>? islandKey,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => AddMomentFlowPage(islandKey: islandKey),
      transitionsBuilder: (_, animation, __, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
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

  final GlobalKey<GrowthIslandSceneState>? islandKey;

  @override
  ConsumerState<AddMomentFlowPage> createState() => _AddMomentFlowPageState();
}

class _AddMomentFlowPageState extends ConsumerState<AddMomentFlowPage> {
  int _step = 0;
  String? _event;
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

  @override
  void initState() {
    super.initState();
    _mood = ref.read(profileProvider).valueOrNull?.todayMood;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _lineTimer?.cancel();
    super.dispose();
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
    if (_event == null || _mood == null) return;
    final style = ref.read(profileProvider).valueOrNull?.companionStyle ?? 'chibi';
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final preview = ClientMomentFactory.build(
      eventTags: [_event!],
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
            eventTags: [_event!],
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
    final style = profile?.companionStyle ?? 'chibi';
    final moodId = _mood ?? profile?.todayMood;
    final islandRegistry = ref.watch(moodIslandRegistryProvider).valueOrNull ?? MoodIslandRegistry.defaults();
    final islandConfig = islandRegistry.resolve(moodId);
    final islandScale = _generating ? 0.35 : (1.0 - _step * 0.12).clamp(0.55, 1.0);

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
                child: GrowthIslandScene(
                  moodId: moodId,
                  palette: palette,
                  islandConfig: islandConfig,
                  companionStyle: style,
                  moments: const [],
                  scale: islandScale,
                  compact: true,
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
                          line: _waitLine,
                          companionKey: _previewCompanionKey,
                          progressKey: _generatingProgressKey,
                        )
                      : _step == 0
                          ? _EventStep(
                              key: const ValueKey('e'),
                              selected: _event,
                              palette: palette,
                              onPick: (e) => setState(() {
                                _event = e;
                                _step = 1;
                              }),
                            )
                          : _step == 1
                              ? _MoodStep(
                                  key: const ValueKey('m'),
                                  selected: _mood,
                                  onPick: (m) => setState(() {
                                    _mood = m;
                                    _step = 2;
                                  }),
                                )
                              : _NoteStep(
                                  key: const ValueKey('n'),
                                  controller: _noteCtrl,
                                  palette: palette,
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
  const _EventStep({super.key, required this.selected, required this.palette, required this.onPick});
  final String? selected;
  final MoodPalette palette;
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: eventTags.map((t) {
              return IslandChip(
                label: t.label,
                emoji: t.emoji,
                selected: selected == t.id,
                palette: palette,
                onTap: () => onPick(t.id),
              );
            }).toList(),
          ),
        ],
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
  const _NoteStep({super.key, required this.controller, required this.palette, required this.onSubmit});
  final TextEditingController controller;
  final MoodPalette palette;
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
              hintText: '可选，说完就生成岛上小伙伴',
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const Spacer(),
          IslandPrimaryAction(label: '让小星上岛', palette: palette, onPressed: onSubmit),
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
    required this.line,
    required this.companionKey,
    required this.progressKey,
  });

  final MoodPalette palette;
  final String style;
  final String scene;
  final String actionType;
  final CompanionSpec? spec;
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
          size: 120,
          palette: widget.palette,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(widget.line, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
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
