import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/emotion_catalog.dart';
import '../../core/constants/island_weather.dart';
import '../../core/growth/daily_level_unlock_prompt.dart';
import '../../core/growth/growth_system.dart';
import '../../core/growth/level_title_assets.dart';
import '../../core/models/character_mood.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/weather/weather_display.dart';
import '../../data/models/profile_models.dart';
import '../../data/models/story_island_models.dart';
import '../../design_system/island_decorations.dart';
import '../../island/providers/building_unlocks_provider.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/providers/island_world_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/building_info_bubble.dart';
import '../../island/service/building_display_names.dart';
import '../../providers/app_providers.dart';
import '../../providers/island_weather_provider.dart';
import '../../providers/main_shell_tab_provider.dart';
import '../../providers/story_day_provider.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../world/behaviors/companion_hit_test.dart';
import '../../world/engine/world_state.dart';
import '../shared/widgets/mood_companion_loading.dart';
import 'widgets/island_companion_speech_overlay.dart';
import '../today/add_moment_flow.dart';
import 'story_island_progress.dart';

class _CompanionSpeechState {
  const _CompanionSpeechState({
    required this.text,
    this.emptyDay = false,
    this.lines = const [],
    this.index = 0,
  });

  final String text;
  final bool emptyDay;
  final List<String> lines;
  final int index;
}

/// Growth Island 2.0：全屏成长世界 + HUD 叠层。
class IslandHomePage extends ConsumerStatefulWidget {
  const IslandHomePage({super.key});

  @override
  ConsumerState<IslandHomePage> createState() => _IslandHomePageState();
}

class _IslandHomePageState extends ConsumerState<IslandHomePage>
    with WidgetsBindingObserver {
  BuildingSnapshot? _selectedBuilding;
  Offset? _selectedBuildingAnchor;
  Timer? _bubbleDismissTimer;
  Timer? _companionSpeechTimer;
  final ValueNotifier<_CompanionSpeechState?> _companionSpeech =
      ValueNotifier(null);
  bool _dailyUnlockPromptChecked = false;
  List<String> _cachedCompanionSpeechLines = const [];
  StoryIslandModel? _activeStoryIsland;
  StorySeedAnimationRequest? _seedAnimationRequest;
  bool _showSeedAnimation = false;
  static const _viewportScale = 1.91;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  bool get _enginePaused {
    final onIslandTab = ref.watch(mainShellTabIndexProvider) == 0;
    final appActive = _lifecycle == AppLifecycleState.resumed;
    return !onIslandTab || !appActive;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listen<AsyncValue<List<DailyMomentModel>>>(todayMomentsProvider, (
      _,
      next,
    ) {
      next.whenData(_refreshCachedSpeechLines);
    });
    ref.listen<AsyncValue<GrowthSummary>>(growthSummaryProvider, (prev, next) {
      next.whenData((data) {
        if (_dailyUnlockPromptChecked || data.isGuest) return;
        _dailyUnlockPromptChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await maybeShowDailyLevelUnlockPrompt(context, ref, summary: data);
        });
      });
    });
    Future.microtask(() async {
      await ref.read(storyDayViewProvider.notifier).refresh();
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
      ref.invalidate(buildingUnlocksProvider);
      ref.invalidate(islandWeatherProvider);
      ref.invalidate(storyIslandGroupsProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bubbleDismissTimer?.cancel();
    _companionSpeechTimer?.cancel();
    _companionSpeech.dispose();
    super.dispose();
  }

  List<String> _buildCompanionSpeechLines(List<DailyMomentModel> moments) {
    final nickname = ref.read(profileProvider).valueOrNull?.nickname;
    final lines = <String>[];
    for (final moment in moments) {
      lines.addAll(moment.storySummaryLinesFor(nickname));
      lines.addAll(moment.waitingLinesFor(nickname));
    }
    return lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _refreshCachedSpeechLines(List<DailyMomentModel> moments) {
    _cachedCompanionSpeechLines = _buildCompanionSpeechLines(moments);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lifecycle == state) return;
    setState(() => _lifecycle = state);
  }

  void _clearCompanionSpeech() {
    _companionSpeechTimer?.cancel();
    _companionSpeech.value = null;
  }

  void _scheduleCompanionSpeechDismiss() {
    _companionSpeechTimer?.cancel();
    _companionSpeechTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) _clearCompanionSpeech();
    });
  }

  void _onCompanionTap() {
    final cleaned = _cachedCompanionSpeechLines.isNotEmpty
        ? _cachedCompanionSpeechLines
        : _buildCompanionSpeechLines(
            ref.read(todayMomentsProvider).valueOrNull ?? const [],
          );
    _companionSpeechTimer?.cancel();
    if (cleaned.isEmpty) {
      _companionSpeech.value = const _CompanionSpeechState(
        text: '今天还没有写下日常呢，快去写今天的日常哦～',
        emptyDay: true,
      );
      _scheduleCompanionSpeechDismiss();
      return;
    }

    final current = _companionSpeech.value;
    if (current != null && current.lines.isNotEmpty) {
      final nextIndex = (current.index + 1) % current.lines.length;
      _companionSpeech.value = _CompanionSpeechState(
        text: current.lines[nextIndex],
        lines: current.lines,
        index: nextIndex,
      );
      _scheduleCompanionSpeechDismiss();
      return;
    }

    final startIndex = Random().nextInt(cleaned.length);
    _companionSpeech.value = _CompanionSpeechState(
      text: cleaned[startIndex],
      lines: cleaned,
      index: startIndex,
    );
    _scheduleCompanionSpeechDismiss();
  }

  Future<void> _refresh() async {
    await ref.read(storyDayViewProvider.notifier).refresh();
    await ref.read(todayMomentsProvider.notifier).refresh();
    ref.invalidate(moodReportCheckInProvider);
    ref.invalidate(growthSummaryProvider);
    ref.invalidate(buildingUnlocksProvider);
    ref.invalidate(islandWeatherProvider);
    ref.invalidate(storyIslandGroupsProvider);
  }

  Future<void> _addMomentToActiveStoryIsland() async {
    final island = _activeStoryIsland;
    if (island == null) return;
    final saved = await showAddMomentFlow(
      context,
      ref,
      forcedStoryIslandId: island.id,
      forcedStoryIslandName: island.name,
    );
    if (saved != true || !mounted) return;
    await _refresh();
    await ref.read(storyIslandGroupsProvider.notifier).refresh();
    final groups = ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
    final updated = _findStoryIsland(groups, island.id);
    if (updated != null && mounted) {
      setState(() => _activeStoryIsland = updated);
    }
  }

  void _onBuildingTap(BuildingSnapshot building) {
    _bubbleDismissTimer?.cancel();
    setState(() {
      _selectedBuilding = building;
      _selectedBuildingAnchor = building.anchor;
    });
    _bubbleDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _selectedBuilding = null;
          _selectedBuildingAnchor = null;
        });
      }
    });
  }

  void _dismissBuildingBubble() {
    _bubbleDismissTimer?.cancel();
    setState(() {
      _selectedBuilding = null;
      _selectedBuildingAnchor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final growthAsync = ref.watch(growthSummaryProvider);
    final buildingUnlocks =
        ref.watch(buildingUnlocksProvider).valueOrNull ?? const {};
    final summary = growthAsync.valueOrNull ?? GrowthSummary.guest();
    final storyGroupsAsync = ref.watch(storyIslandGroupsProvider);
    final storyGroups = storyGroupsAsync.valueOrNull ?? const [];
    final pendingSeedAnimation = ref.watch(pendingStorySeedAnimationProvider);
    if (pendingSeedAnimation != null && storyGroups.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target =
            _findStoryIsland(storyGroups, pendingSeedAnimation.toIslandId);
        if (target == null) return;
        ref.read(pendingStorySeedAnimationProvider.notifier).state = null;
        setState(() {
          _activeStoryIsland = target;
          _selectedBuilding = null;
          _selectedBuildingAnchor = null;
          _seedAnimationRequest = pendingSeedAnimation;
          _showSeedAnimation = true;
        });
      });
    }

    final moments = ref.watch(todayMomentsProvider).valueOrNull ?? const [];
    if (_cachedCompanionSpeechLines.isEmpty && moments.isNotEmpty) {
      _cachedCompanionSpeechLines = _buildCompanionSpeechLines(moments);
    }

    final weatherAsync = ref.watch(islandWeatherProvider);
    final weather = weatherAsync.valueOrNull;
    final weatherKind = islandWeatherKind(weather);
    final weatherLabelText = weatherDisplayLabelFromSnapshot(weather);
    final geoLocationLabel = weatherLocationLabelFromSnapshot(weather);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      extendBodyBehindAppBar: true,
      body: growthAsync.when(
        loading: () => const MoodCompanionLoadingBody(
          message: '正在唤醒你的成长世界…',
        ),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (_) => RefreshIndicator(
          color: palette.accent,
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_activeStoryIsland == null) {
                return _IslandDirectoryHome(
                  palette: palette,
                  groups: storyGroups,
                  baseWorldState: ref.watch(islandWorldProvider),
                  summary: summary,
                  moments: moments,
                  weatherKind: weatherKind,
                  weatherLabel: weatherLabelText,
                  geoLocationLabel: geoLocationLabel,
                  loading: storyGroupsAsync.isLoading,
                  onRefresh: _refresh,
                  onIslandSelected: (island) {
                    setState(() => _activeStoryIsland = island);
                  },
                  onCreateIsland: _createStoryIsland,
                  onEditIsland: _editStoryIsland,
                  onCreateTask: _createStoryIslandTask,
                  onEditTask: _editStoryIslandTask,
                  onDeleteTask: _deleteStoryIslandTask,
                  onCompleteTask: _completeStoryIslandTask,
                  onUncompleteTask: _uncompleteStoryIslandTask,
                  onRecordTap: () => context.go('/records'),
                );
              }

              final selected = _selectedBuilding;
              final anchor = _selectedBuildingAnchor;
              final unlockDate = selected == null
                  ? null
                  : selected.unlockedAt ??
                      buildingUnlocks[selected.definitionId];
              final storyIslandWorld = _storyIslandWorldState(
                ref.watch(islandWorldProvider),
                _activeStoryIsland!,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(0, 52),
                      child: GrowthWorldViewport(
                        key: ValueKey(
                          'story_island_${_activeStoryIsland!.id}_${_activeStoryIsland!.currentLevel}',
                        ),
                        worldState: storyIslandWorld,
                        interactive: true,
                        enginePaused: _enginePaused,
                        scale: 1.91,
                        force2D: true,
                        onBuildingTap: _onBuildingTap,
                        onCharacterInteraction: (_, __, characterId) {
                          if (characterId == 'protagonist') _onCompanionTap();
                        },
                      ),
                    ),
                  ),
                  if (_showSeedAnimation && _seedAnimationRequest != null)
                    Positioned.fill(
                      child: _SeedTransferOverlay(
                        request: _seedAnimationRequest!,
                        islandName: _activeStoryIsland!.name,
                        palette: palette,
                        onCompleted: () {
                          if (!mounted) return;
                          setState(() => _showSeedAnimation = false);
                        },
                      ),
                    ),
                  if (selected != null)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _dismissBuildingBubble,
                      ),
                    ),
                  if (selected != null && anchor != null)
                    Positioned(
                      left: (anchor.dx * constraints.maxWidth - 110)
                          .clamp(8.0, constraints.maxWidth - 228),
                      top: (anchor.dy * constraints.maxHeight - 132)
                          .clamp(72.0, constraints.maxHeight - 140),
                      child: BuildingInfoBubble(
                        buildingName: selected.displayName ??
                            BuildingDisplayNames.nameFor(selected.definitionId),
                        unlockedAt: unlockDate,
                        unlockLevel: selected.unlockLevel,
                        palette: palette,
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: MediaQuery.paddingOf(context).top + 52,
                    child: _StoryIslandHudOverlay(
                      island: _activeStoryIsland!,
                      weatherKind: weatherKind,
                      weatherLabel: weatherLabelText,
                      geoLocationLabel: geoLocationLabel,
                      palette: palette,
                      onEdit: () => _editStoryIsland(_activeStoryIsland!),
                      onBack: () {
                        _clearCompanionSpeech();
                        setState(() => _activeStoryIsland = null);
                      },
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.paddingOf(context).bottom + 92,
                    child: _StoryIslandAddMomentButton(
                      palette: palette,
                      islandName: _activeStoryIsland!.name,
                      onTap: _addMomentToActiveStoryIsland,
                    ),
                  ),
                  ValueListenableBuilder<_CompanionSpeechState?>(
                    valueListenable: _companionSpeech,
                    builder: (context, speech, _) {
                      if (speech == null) return const SizedBox.shrink();
                      final viewportSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapUp: (details) {
                                if (CompanionHitTest.containsScreenTap(
                                  details.localPosition,
                                  viewportSize,
                                  viewportScale: _viewportScale,
                                )) {
                                  _onCompanionTap();
                                } else {
                                  _clearCompanionSpeech();
                                }
                              },
                            ),
                          ),
                          IslandCompanionSpeechOverlay(
                            palette: palette,
                            text: speech.text,
                            viewportSize: viewportSize,
                            showWriteStoryAction: speech.emptyDay,
                            onWriteStory: () {
                              _clearCompanionSpeech();
                              _addMomentToActiveStoryIsland();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  StoryIslandModel? _findStoryIsland(
    List<StoryIslandCategoryModel> groups,
    String islandId,
  ) {
    for (final group in groups) {
      for (final island in group.islands) {
        if (island.id == islandId) return island;
      }
    }
    return null;
  }

  WorldState _storyIslandWorldState(
    WorldState base,
    StoryIslandModel island,
  ) {
    final storyBuildings = _storyIslandBuildings(island);
    return WorldState(
      island: base.island,
      characters: base.characters,
      buildings: storyBuildings,
      flora: const [],
      environment: base.environment,
      zones: const [],
      decorations: const [],
      paths: const [],
      effects: base.effects,
      anchors: [
        ...base.anchors,
        WorldAnchorSnapshot(
          id: 'story_island_${island.id}',
          type: 'story_island',
          position: const Offset(0.5, 0.5),
          visualWeight: 0,
          cameraFocus: false,
        ),
      ],
      companionGender: base.companionGender,
      schemaVersion: base.schemaVersion,
    );
  }

  List<BuildingSnapshot> _storyIslandBuildings(StoryIslandModel island) {
    final out = <BuildingSnapshot>[];
    for (final level in island.progressionPlan) {
      if (!level.unlocked) continue;
      final lv = level.level.clamp(1, 10);
      out.add(
        BuildingSnapshot(
          definitionId:
              'story_island_${island.id}_lv${lv.toString().padLeft(2, '0')}',
          level: lv,
          anchor: _storyBuildingAnchor(level),
          type: 'story_${level.ring}',
          size: _storyBuildingSize(level),
          sprite:
              'islands/${island.categoryId}/buildings/lv${lv.toString().padLeft(2, '0')}.png',
          displayName: level.buildingType,
          unlockLevel: lv,
          unlockedAt: level.unlockedAt,
        ),
      );
    }
    return out..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
  }

  Offset _storyBuildingAnchor(StoryIslandProgressLevelModel level) {
    return switch (level.level) {
      1 => const Offset(0.24, 0.63),
      2 => const Offset(0.76, 0.62),
      3 => const Offset(0.50, 0.70),
      4 => const Offset(0.32, 0.54),
      5 => const Offset(0.68, 0.54),
      6 => const Offset(0.50, 0.58),
      7 => const Offset(0.38, 0.45),
      8 => const Offset(0.62, 0.45),
      9 => const Offset(0.50, 0.40),
      _ => const Offset(0.50, 0.49),
    };
  }

  Offset _storyBuildingSize(StoryIslandProgressLevelModel level) {
    return switch (level.ring) {
      'outer' => const Offset(0.14, 0.15),
      'middle' => const Offset(0.17, 0.18),
      'inner' => const Offset(0.19, 0.21),
      'center' => const Offset(0.24, 0.27),
      _ => const Offset(0.16, 0.18),
    };
  }

  Future<void> _createStoryIsland(StoryIslandCategoryModel category) async {
    final result = await _showStoryIslandEditorDialog(
      context: context,
      title: '新建${category.label}岛屿',
    );
    if (result == null || !mounted) return;
    await ref.read(storyIslandGroupsProvider.notifier).createIsland(
          categoryId: category.id,
          name: result.name,
          targetCompletionDays: result.targetCompletionDays,
          completionTargetDate: result.completionTargetDate,
          sizeKind: result.sizeKind,
        );
  }

  Future<void> _editStoryIsland(StoryIslandModel island) async {
    final result = await _showStoryIslandEditorDialog(
      context: context,
      title: '编辑${island.name}',
      island: island,
    );
    if (result == null || !mounted) return;
    final daysChanged =
        result.targetCompletionDays != island.targetCompletionDays;
    if (daysChanged) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('重新计算岛屿进度？'),
          content: Text(
            '目标完成时间将从 ${island.targetCompletionDays} 天改为 ${result.targetCompletionDays} 天。'
            '系统会重新评估小岛等级、建筑解锁节奏和首次解锁时间。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认修改'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final updated =
        await ref.read(storyIslandGroupsProvider.notifier).updateIsland(
              id: island.id,
              name: result.name,
              targetCompletionDays: result.targetCompletionDays,
              completionTargetDate: result.completionTargetDate,
              sizeKind: result.sizeKind,
            );
    if (_activeStoryIsland?.id == updated.id) {
      setState(() => _activeStoryIsland = updated);
    }
  }

  Future<void> _createStoryIslandTask(StoryIslandModel island) async {
    final result = await _showStoryIslandTaskDialog(context: context);
    if (result == null || !mounted) return;
    await ref.read(storyIslandGroupsProvider.notifier).createTask(
          islandId: island.id,
          title: result.title,
          isDaily: result.isDaily,
        );
  }

  Future<void> _editStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    final result = await _showStoryIslandTaskDialog(
      context: context,
      task: task,
    );
    if (result == null || !mounted) return;
    await ref.read(storyIslandGroupsProvider.notifier).updateTask(
          islandId: island.id,
          taskId: task.id,
          title: result.title,
          isDaily: result.isDaily,
        );
  }

  Future<void> _deleteStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    await ref.read(storyIslandGroupsProvider.notifier).deleteTask(
          islandId: island.id,
          taskId: task.id,
        );
  }

  Future<void> _syncActiveStoryIsland(String islandId) async {
    final groups = ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
    for (final group in groups) {
      for (final island in group.islands) {
        if (island.id == islandId) {
          if (mounted) setState(() => _activeStoryIsland = island);
          return;
        }
      }
    }
  }

  Future<void> _completeStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    if (task.completedToday) return;
    await ref.read(storyIslandGroupsProvider.notifier).completeTask(
          islandId: island.id,
          taskId: task.id,
        );
    await _syncActiveStoryIsland(island.id);
  }

  Future<void> _uncompleteStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    if (!task.completedToday) return;
    await ref.read(storyIslandGroupsProvider.notifier).uncompleteTask(
          islandId: island.id,
          taskId: task.id,
        );
    await _syncActiveStoryIsland(island.id);
  }
}

class _IslandDirectoryHome extends StatefulWidget {
  const _IslandDirectoryHome({
    required this.palette,
    required this.groups,
    required this.baseWorldState,
    required this.summary,
    required this.moments,
    required this.weatherKind,
    required this.weatherLabel,
    required this.geoLocationLabel,
    required this.loading,
    required this.onRefresh,
    required this.onIslandSelected,
    required this.onCreateIsland,
    required this.onEditIsland,
    required this.onCreateTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onCompleteTask,
    required this.onUncompleteTask,
    required this.onRecordTap,
  });

  final MoodPalette palette;
  final List<StoryIslandCategoryModel> groups;
  final WorldState baseWorldState;
  final GrowthSummary summary;
  final List<DailyMomentModel> moments;
  final IslandWeather weatherKind;
  final String weatherLabel;
  final String geoLocationLabel;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<StoryIslandModel> onIslandSelected;
  final ValueChanged<StoryIslandCategoryModel> onCreateIsland;
  final ValueChanged<StoryIslandModel> onEditIsland;
  final ValueChanged<StoryIslandModel> onCreateTask;
  final void Function(StoryIslandModel island, StoryIslandTaskModel task)
      onEditTask;
  final void Function(StoryIslandModel island, StoryIslandTaskModel task)
      onDeleteTask;
  final void Function(StoryIslandModel island, StoryIslandTaskModel task)
      onCompleteTask;
  final void Function(StoryIslandModel island, StoryIslandTaskModel task)
      onUncompleteTask;
  final VoidCallback onRecordTap;

  @override
  State<_IslandDirectoryHome> createState() => _IslandDirectoryHomeState();
}

class _IslandDirectoryHomeState extends State<_IslandDirectoryHome> {
  String? _categoryId;

  @override
  void didUpdateWidget(covariant _IslandDirectoryHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_categoryId == null && widget.groups.isNotEmpty) {
      _categoryId = widget.groups.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final groups = widget.groups;
    StoryIslandCategoryModel? selectedGroup;
    for (final group in groups) {
      if (group.id == _categoryId) {
        selectedGroup = group;
        break;
      }
    }
    selectedGroup ??= groups.isNotEmpty ? groups.first : null;

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: true,
            child: IslandScaffold(
              palette: palette,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HomeGrowthLevelCard(
                        summary: widget.summary,
                        palette: palette,
                        weatherKind: widget.weatherKind,
                        weatherLabel: widget.weatherLabel,
                        geoLocationLabel: widget.geoLocationLabel,
                      ),
                      const SizedBox(height: 16),
                      if (widget.loading && groups.isEmpty)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (groups.isEmpty)
                        Expanded(
                          child: _EmptyIslandDirectory(
                              onRecordTap: widget.onRecordTap),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 28,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: groups.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final group = groups[index];
                                    final selected =
                                        group.id == selectedGroup?.id;
                                    return _StoryCategoryCard(
                                      group: group,
                                      selected: selected,
                                      palette: palette,
                                      onTap: () => setState(
                                          () => _categoryId = group.id),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.86),
                            itemCount: (selectedGroup?.islands.length ?? 0) + 1,
                            itemBuilder: (context, index) {
                              final islands = selectedGroup!.islands;
                              if (index >= islands.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      right: 14, bottom: 8),
                                  child: _CreateStoryIslandCard(
                                    palette: palette,
                                    onTap: () =>
                                        widget.onCreateIsland(selectedGroup!),
                                  ),
                                );
                              }
                              final island = islands[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 14, bottom: 8),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: _StoryIslandCard(
                                        island: island,
                                        palette: palette,
                                        previewWorldState:
                                            _storyIslandCardWorldState(
                                          widget.baseWorldState,
                                          island,
                                          island.dominantMood ??
                                              _dominantMoodForIsland(
                                                widget.moments,
                                                island.id,
                                              ),
                                        ),
                                        onTap: () =>
                                            widget.onIslandSelected(island),
                                        onEdit: () =>
                                            widget.onEditIsland(island),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _TodayTaskListCard(
                                      island: island,
                                      palette: palette,
                                      onAdd: () => widget.onCreateTask(island),
                                      onEdit: (task) =>
                                          widget.onEditTask(island, task),
                                      onDelete: (task) =>
                                          widget.onDeleteTask(island, task),
                                      onComplete: (task) =>
                                          widget.onCompleteTask(island, task),
                                      onUncomplete: (task) => widget
                                          .onUncompleteTask(island, task),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeGrowthLevelCard extends StatelessWidget {
  const _HomeGrowthLevelCard({
    required this.summary,
    required this.palette,
    required this.weatherKind,
    required this.weatherLabel,
    required this.geoLocationLabel,
  });

  final GrowthSummary summary;
  final MoodPalette palette;
  final IslandWeather weatherKind;
  final String weatherLabel;
  final String geoLocationLabel;

  @override
  Widget build(BuildContext context) {
    final nextLabel = summary.nextLevel == null
        ? '已满级 · 岛屿传说'
        : '下一级 Lv.${summary.nextLevel} ${summary.nextLevelTitle ?? ''}'.trim();
    final place = geoLocationLabel.isEmpty ? '成长世界' : geoLocationLabel;
    final weather = weatherLabel.isEmpty ? '多云' : weatherLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EA).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GrowthSystem.levelDisplayLabel(summary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '🔥  ${summary.streakDays} 天',
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6D8B74),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '当前位置 · $place',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primary.withValues(alpha: 0.54),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _weatherIcon(weatherKind),
                        size: 14,
                        color: const Color(0xFF75A9D6),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        weather,
                        style: TextStyle(
                          color: palette.primary.withValues(alpha: 0.54),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            LevelTitleBadgeImage(
              level: summary.level,
              size: 38,
              borderRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  IconData _weatherIcon(IslandWeather weather) {
    return switch (weather) {
      IslandWeather.sunny => Icons.wb_sunny_rounded,
      IslandWeather.softCloud => Icons.cloud_queue_rounded,
      IslandWeather.overcast => Icons.cloud_rounded,
      IslandWeather.drizzle => Icons.water_drop_rounded,
      IslandWeather.windy => Icons.air_rounded,
    };
  }
}

class _StoryCategoryCard extends StatelessWidget {
  const _StoryCategoryCard({
    required this.group,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final StoryIslandCategoryModel group;
  final bool selected;
  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFF6658) : Colors.white;
    final foreground = selected ? Colors.white : palette.primary;
    return Material(
      color: color.withValues(alpha: selected ? 1 : 0.78),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.36)
                  : Colors.white.withValues(alpha: 0.72),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6658).withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _categoryIcon(group.id),
                color: selected ? Colors.white : palette.accent,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                group.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String id) {
    return switch (id) {
      'work' => Icons.work_rounded,
      'study' => Icons.school_rounded,
      'health' => Icons.eco_rounded,
      'social' => Icons.favorite_border_rounded,
      'life' => Icons.home_rounded,
      'finance' || 'wealth' => Icons.shield_outlined,
      _ => Icons.auto_awesome_rounded,
    };
  }
}

WorldState _storyIslandCardWorldState(
  WorldState base,
  StoryIslandModel island,
  String? moodId,
) {
  final mood = CharacterMood.fromString(
    emotionById(moodId ?? defaultEmotionId).legacyMoodId,
  );
  return WorldState(
    island: base.island,
    characters: [
      CharacterSnapshot(
        id: 'story_island_card_companion_${island.id}',
        mood: mood,
        level: max(1, island.currentLevel),
        accessoryIds: const [],
        animationKey: 'idle',
        normalizedPos: const Offset(0.52, 0.54),
        expression: mood.name,
        companionPose: 'breathing',
        scale: _storyIslandCompanionScale(island.sizeKind),
      ),
    ],
    buildings: _storyIslandCardBuildings(island),
    flora: const [],
    environment: base.environment,
    zones: const [],
    decorations: const [],
    paths: const [],
    effects: const [],
    anchors: [
      WorldAnchorSnapshot(
        id: 'story_island_card_${island.id}',
        type: 'story_island',
        position: const Offset(0.5, 0.5),
        visualWeight: 0,
        cameraFocus: false,
      ),
    ],
    companionGender: base.companionGender,
    schemaVersion: base.schemaVersion,
  );
}

String? _dominantMoodForIsland(
  List<DailyMomentModel> moments,
  String islandId,
) {
  final counts = <String, int>{};
  for (final moment in moments) {
    final id = moment.storyIslandId ??
        moment.visualPayload['story_island_id'] as String?;
    if (id != islandId) continue;
    final moodId = effectiveEmotionIdForMoment(moment);
    counts[moodId] = (counts[moodId] ?? 0) + 1;
  }
  String? best;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}

double _storyIslandCompanionScale(String sizeKind) {
  return switch (sizeKind) {
    'small' => 0.78,
    'medium' => 0.92,
    'large' => 1.08,
    _ => 0.9,
  };
}

List<BuildingSnapshot> _storyIslandCardBuildings(StoryIslandModel island) {
  final out = <BuildingSnapshot>[];
  for (final level in island.progressionPlan) {
    if (!level.unlocked) continue;
    final lv = level.level.clamp(1, 10);
    out.add(
      BuildingSnapshot(
        definitionId:
            'story_island_card_${island.id}_lv${lv.toString().padLeft(2, '0')}',
        level: lv,
        anchor: _storyIslandCardBuildingAnchor(level),
        type: 'story_${level.ring}',
        size: _storyIslandCardBuildingSize(level),
        sprite:
            'islands/${island.categoryId}/buildings/lv${lv.toString().padLeft(2, '0')}.png',
        displayName: level.buildingType,
        unlockLevel: lv,
        unlockedAt: level.unlockedAt,
      ),
    );
  }
  return out..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
}

Offset _storyIslandCardBuildingAnchor(StoryIslandProgressLevelModel level) {
  return switch (level.level) {
    1 => const Offset(0.24, 0.63),
    2 => const Offset(0.76, 0.62),
    3 => const Offset(0.50, 0.70),
    4 => const Offset(0.32, 0.54),
    5 => const Offset(0.68, 0.54),
    6 => const Offset(0.50, 0.58),
    7 => const Offset(0.38, 0.45),
    8 => const Offset(0.62, 0.45),
    9 => const Offset(0.50, 0.40),
    _ => const Offset(0.50, 0.49),
  };
}

Offset _storyIslandCardBuildingSize(StoryIslandProgressLevelModel level) {
  return switch (level.ring) {
    'outer' => const Offset(0.14, 0.15),
    'middle' => const Offset(0.17, 0.18),
    'inner' => const Offset(0.19, 0.21),
    'center' => const Offset(0.24, 0.27),
    _ => const Offset(0.16, 0.18),
  };
}

class _StoryIslandCard extends StatelessWidget {
  const _StoryIslandCard({
    required this.island,
    required this.palette,
    required this.previewWorldState,
    required this.onTap,
    required this.onEdit,
  });

  final StoryIslandModel island;
  final MoodPalette palette;
  final WorldState previewWorldState;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final levelProgress = storyIslandLevelProgress(island);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: const Color(0xFFFFF1E2).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 118,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Transform.translate(
                        offset: const Offset(0, 16),
                        child: GrowthWorldViewport(
                          key: ValueKey(
                            'story_island_card_${island.id}_${island.currentLevel}',
                          ),
                          worldState: previewWorldState,
                          compact: true,
                          interactive: false,
                          enginePaused: false,
                          previewZoom: _storyIslandPreviewZoom(island.sizeKind),
                          scale: 1.0,
                          islandOnly: true,
                          force2D: true,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton.filledTonal(
                        onPressed: onEdit,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        tooltip: '编辑岛屿目标',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFFF7EF).withValues(alpha: 0.86),
                          foregroundColor: palette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                island.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${storyIslandLevelLabel(island)} · 连续${island.activeDays}天',
                style: TextStyle(
                  color: palette.primary.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '成长值',
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${island.growthValue}',
                    style: const TextStyle(
                      color: Color(0xFFFF5A52),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 7,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: const Color(0xFFFF635C),
                        inactiveTrackColor: const Color(0xFFF1E6DB),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: levelProgress.progressToNext,
                        onChanged: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${levelProgress.percentToNext}%',
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _nextUnlockLabel(island, levelProgress),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.primary.withValues(alpha: 0.52),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _EnterIslandButton(onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }

  String _nextUnlockLabel(
    StoryIslandModel island,
    StoryIslandLevelProgress levelProgress,
  ) {
    if (levelProgress.isMaxLevel) {
      return '全部 10 阶段建筑已解锁';
    }
    final nextBuilding = levelProgress.nextBuildingName ?? '下一建筑';
    return '距离 Lv.${levelProgress.nextLevel} $nextBuilding 还差 ${levelProgress.percentToNext}%';
  }
}

double _storyIslandPreviewZoom(String sizeKind) {
  return switch (sizeKind) {
    'small' => 1.18,
    'medium' => 1.42,
    'large' => 1.68,
    _ => 1.36,
  };
}

class _CreateStoryIslandCard extends StatelessWidget {
  const _CreateStoryIslandCard({
    required this.palette,
    required this.onTap,
  });

  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.44),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.28),
                    width: 1.4,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 42,
                  color: palette.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnterIslandButton extends StatelessWidget {
  const _EnterIslandButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A66), Color(0xFFFF3F4D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5A52).withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '进入岛屿',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayTaskListCard extends StatelessWidget {
  const _TodayTaskListCard({
    required this.island,
    required this.palette,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onUncomplete,
  });

  final StoryIslandModel island;
  final MoodPalette palette;
  final VoidCallback onAdd;
  final ValueChanged<StoryIslandTaskModel> onEdit;
  final ValueChanged<StoryIslandTaskModel> onDelete;
  final ValueChanged<StoryIslandTaskModel> onComplete;
  final ValueChanged<StoryIslandTaskModel> onUncomplete;

  @override
  Widget build(BuildContext context) {
    final tasks = island.todayTasks;
    const headerHeight = 30.0;
    const rowHeight = 34.0;
    const verticalPadding = 14.0;
    const emptyBodyHeight = 28.0;
    final visibleRows = tasks.isEmpty ? 0 : tasks.length.clamp(1, 3);
    final bodyHeight =
        tasks.isEmpty ? emptyBodyHeight : visibleRows * rowHeight;
    final cardHeight = headerHeight + bodyHeight + verticalPadding;

    return SizedBox(
      height: cardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6EA),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '今日任务',
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('添加', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: bodyHeight,
                child: tasks.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          '添加任务后，完成一项岛屿成长值 +5',
                          style: TextStyle(
                            color: palette.primary.withValues(alpha: 0.52),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: tasks.length > 3
                            ? const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              )
                            : const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _TodayTaskRow(
                            task: task,
                            palette: palette,
                            onComplete: () => onComplete(task),
                            onUncomplete: () => onUncomplete(task),
                            onEdit: () => onEdit(task),
                            onDelete: () => onDelete(task),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayTaskRow extends StatelessWidget {
  const _TodayTaskRow({
    required this.task,
    required this.palette,
    required this.onComplete,
    required this.onUncomplete,
    required this.onEdit,
    required this.onDelete,
  });

  final StoryIslandTaskModel task;
  final MoodPalette palette;
  final VoidCallback onComplete;
  final VoidCallback onUncomplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = task.completedToday;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          InkWell(
            onTap: done ? onUncomplete : onComplete,
            borderRadius: BorderRadius.circular(999),
            child: Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 18,
              color: done
                  ? const Color(0xFFFF6658)
                  : palette.primary.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.isDaily ? '${task.title}  · 每日' : task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: done
                    ? palette.primary.withValues(alpha: 0.52)
                    : palette.primary.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (done)
            TextButton(
              onPressed: onUncomplete,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: palette.primary.withValues(alpha: 0.58),
              ),
              child: const Text('取消', style: TextStyle(fontSize: 11)),
            ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 15),
            tooltip: '修改任务',
            visualDensity: VisualDensity.compact,
            color: palette.primary.withValues(alpha: 0.52),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 15),
            tooltip: '删除任务',
            visualDensity: VisualDensity.compact,
            color: palette.primary.withValues(alpha: 0.42),
          ),
        ],
      ),
    );
  }
}

class _StoryIslandHudOverlay extends StatelessWidget {
  const _StoryIslandHudOverlay({
    required this.island,
    required this.weatherKind,
    required this.weatherLabel,
    required this.geoLocationLabel,
    required this.palette,
    required this.onBack,
    required this.onEdit,
  });

  final StoryIslandModel island;
  final IslandWeather weatherKind;
  final String weatherLabel;
  final String geoLocationLabel;
  final MoodPalette palette;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final levelProgress = storyIslandLevelProgress(island);
    final targetLabel = island.completionTargetDate == null
        ? '${island.targetCompletionDays} 天目标'
        : '截止 ${_formatDate(island.completionTargetDate!)}';
    final levelBadgeLabel = island.currentLevel <= 0
        ? 'Lv.0/10'
        : storyIslandLevelLabel(island);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        island.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      tooltip: '编辑岛屿截止时间',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.72),
                        foregroundColor: palette.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _IslandHudMetric(
                      icon: Icons.auto_awesome_rounded,
                      label: levelBadgeLabel,
                      color: const Color(0xFFFF6658),
                    ),
                    const SizedBox(width: 8),
                    _IslandHudMetric(
                      icon: Icons.local_fire_department_rounded,
                      label: '${island.growthValue}/${island.growthTarget}',
                      color: const Color(0xFFFF9E3D),
                    ),
                    const SizedBox(width: 8),
                    _IslandHudMetric(
                      icon: _weatherIcon(weatherKind),
                      label: weatherLabel.isEmpty ? '天气' : weatherLabel,
                      color: const Color(0xFF5AA9E6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: levelProgress.progressToNext,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1E6DB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6658)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        levelProgress.isMaxLevel
                            ? '全部建筑已解锁'
                            : '距离 Lv.${levelProgress.nextLevel} ${levelProgress.nextBuildingName ?? ''} 还差 ${levelProgress.percentToNext}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primary.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      targetLabel,
                      style: TextStyle(
                        color: const Color(0xFF5E8570),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (geoLocationLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    geoLocationLabel,
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.48),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 20, color: palette.primary),
                  const SizedBox(width: 6),
                  Text(
                    '返回我的岛屿',
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  IconData _weatherIcon(IslandWeather weather) {
    return switch (weather) {
      IslandWeather.sunny => Icons.wb_sunny_rounded,
      IslandWeather.softCloud => Icons.cloud_queue_rounded,
      IslandWeather.overcast => Icons.cloud_rounded,
      IslandWeather.drizzle => Icons.water_drop_rounded,
      IslandWeather.windy => Icons.air_rounded,
    };
  }
}

class _IslandHudMetric extends StatelessWidget {
  const _IslandHudMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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

class _StoryIslandEditorResult {
  const _StoryIslandEditorResult({
    required this.name,
    required this.targetCompletionDays,
    required this.sizeKind,
    this.completionTargetDate,
  });

  final String name;
  final int targetCompletionDays;
  final String sizeKind;
  final DateTime? completionTargetDate;
}

Future<_StoryIslandEditorResult?> _showStoryIslandEditorDialog({
  required BuildContext context,
  required String title,
  StoryIslandModel? island,
}) {
  final nameCtrl = TextEditingController(text: island?.name ?? '');
  final daysCtrl = TextEditingController(
    text: '${island?.targetCompletionDays ?? 90}',
  );
  DateTime? targetDate = island?.completionTargetDate;
  String sizeKind = island?.sizeKind ?? 'small';

  return showDialog<_StoryIslandEditorResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: now.add(const Duration(days: 10)),
              lastDate: now.add(const Duration(days: 365)),
              initialDate: targetDate ??
                  now.add(Duration(
                    days: (int.tryParse(daysCtrl.text.trim()) ?? 90)
                        .clamp(10, 365),
                  )),
            );
            if (picked == null) return;
            final days = picked
                .difference(DateTime(now.year, now.month, now.day))
                .inDays;
            setState(() {
              targetDate = picked;
              daysCtrl.text = '${days.clamp(10, 365)}';
            });
          }

          void submit() {
            final name = nameCtrl.text.trim();
            final days = int.tryParse(daysCtrl.text.trim()) ?? 90;
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              _StoryIslandEditorResult(
                name: name,
                targetCompletionDays: days.clamp(10, 365),
                sizeKind: sizeKind,
                completionTargetDate: targetDate,
              ),
            );
          }

          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '岛屿名称',
                    hintText: '例如：高考岛',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysCtrl,
                  decoration: const InputDecoration(
                    labelText: '目标完成天数',
                    helperText: '系统会按前期快、后期慢生成 10 阶段建筑节奏',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text(
                  '岛屿规模',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('小岛 1000'),
                      selected: sizeKind == 'small',
                      onSelected: (_) => setState(() => sizeKind = 'small'),
                    ),
                    ChoiceChip(
                      label: const Text('中岛 5000'),
                      selected: sizeKind == 'medium',
                      onSelected: (_) => setState(() => sizeKind = 'medium'),
                    ),
                    ChoiceChip(
                      label: const Text('大岛 10000'),
                      selected: sizeKind == 'large',
                      onSelected: (_) => setState(() => sizeKind = 'large'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: pickDate,
                  icon: const Icon(Icons.event_available_rounded),
                  label: Text(
                    targetDate == null
                        ? '选择目标完成日期（可选）'
                        : '目标日期：${targetDate!.year}-${targetDate!.month.toString().padLeft(2, '0')}-${targetDate!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(() {
    nameCtrl.dispose();
    daysCtrl.dispose();
  });
}

class _StoryIslandAddMomentButton extends StatelessWidget {
  const _StoryIslandAddMomentButton({
    required this.palette,
    required this.islandName,
    required this.onTap,
  });

  final MoodPalette palette;
  final String islandName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A66), Color(0xFFFF3F4D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5A52).withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '添加一个日常到「$islandName」',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
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

class _StoryIslandTaskEditorResult {
  const _StoryIslandTaskEditorResult({
    required this.title,
    required this.isDaily,
  });

  final String title;
  final bool isDaily;
}

Future<_StoryIslandTaskEditorResult?> _showStoryIslandTaskDialog({
  required BuildContext context,
  StoryIslandTaskModel? task,
}) {
  final titleCtrl = TextEditingController(text: task?.title ?? '');
  var isDaily = task?.isDaily ?? false;
  return showDialog<_StoryIslandTaskEditorResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          void submit() {
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;
            Navigator.of(context).pop(
              _StoryIslandTaskEditorResult(
                title: title,
                isDaily: isDaily,
              ),
            );
          }

          return AlertDialog(
            title: Text(task == null ? '添加今日任务' : '修改今日任务'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '任务内容',
                    hintText: '例如：阅读20分钟',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isDaily,
                  onChanged: (value) => setState(() => isDaily = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('每日任务'),
                  subtitle: const Text('开启后每天都会出现在该岛屿今日任务里'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(titleCtrl.dispose);
}

class _SeedTransferOverlay extends StatefulWidget {
  const _SeedTransferOverlay({
    required this.request,
    required this.islandName,
    required this.palette,
    required this.onCompleted,
  });

  final StorySeedAnimationRequest request;
  final String islandName;
  final MoodPalette palette;
  final VoidCallback onCompleted;

  @override
  State<_SeedTransferOverlay> createState() => _SeedTransferOverlayState();
}

class _SeedTransferOverlayState extends State<_SeedTransferOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final fromName = widget.request.fromIslandName;
    final toName = widget.request.toIslandName ?? widget.islandName;
    final label = fromName == null || fromName == toName
        ? '故事种子正在落入「$toName」'
        : '故事种子正从「$fromName」移到「$toName」';

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final glow = Curves.easeOut.transform(
            (_controller.value - 0.52).clamp(0.0, 1.0),
          );
          final width = MediaQuery.sizeOf(context).width;
          final height = MediaQuery.sizeOf(context).height;
          final x = lerpDouble(width * 0.18, width * 0.52, t)!;
          final y =
              lerpDouble(height * 0.16, height * 0.52, t)! - sin(t * pi) * 86;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.glow.withValues(alpha: 0.18 * glow),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.5 - 135,
                top: height * 0.50 - 135,
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.34 * glow),
                        blurRadius: 70 * glow,
                        spreadRadius: 24 * glow,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: x - 18,
                top: y - 18,
                child: Transform.scale(
                  scale: 0.75 + sin(t * pi) * 0.35,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          palette.accent,
                          palette.primary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accent.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: MediaQuery.paddingOf(context).bottom + 92,
                child: Opacity(
                  opacity:
                      (1 - (_controller.value - 0.72).clamp(0.0, 1.0) / 0.28)
                          .clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyIslandDirectory extends StatelessWidget {
  const _EmptyIslandDirectory({required this.onRecordTap});

  final VoidCallback onRecordTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRecordTap,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('先写一篇日常'),
      ),
    );
  }
}
