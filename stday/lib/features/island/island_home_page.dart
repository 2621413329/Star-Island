import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/daily_level_unlock_prompt.dart';
import '../../core/growth/growth_system.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/weather/weather_display.dart';
import '../../data/models/profile_models.dart';
import '../../data/models/story_island_models.dart';
import '../../island/providers/building_unlocks_provider.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/building_info_bubble.dart';
import '../../island/service/building_display_names.dart';
import '../../island/widgets/island_hud_overlay.dart';
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
                  loading: storyGroupsAsync.isLoading,
                  onRefresh: _refresh,
                  onIslandSelected: (island) {
                    setState(() => _activeStoryIsland = island);
                  },
                  onCreateIsland: _createStoryIsland,
                  onEditIsland: _editStoryIsland,
                  onRecordTap: () => context.go('/records'),
                );
              }

              final selected = _selectedBuilding;
              final anchor = _selectedBuildingAnchor;
              final unlockDate = selected == null
                  ? null
                  : buildingUnlocks[selected.definitionId] ??
                      selected.unlockedAt;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: GrowthWorldViewport(
                      key: ValueKey(
                        'island_${summary.level}_${summary.growthValue}',
                      ),
                      useIslandWorldProvider: true,
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
                  Positioned(
                    left: 16,
                    top: MediaQuery.paddingOf(context).top + 10,
                    child: _IslandBackButton(
                      islandName: _activeStoryIsland!.name,
                      onBack: () {
                        _clearCompanionSpeech();
                        setState(() => _activeStoryIsland = null);
                      },
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
                  Positioned.fill(
                    child: IslandHudOverlay(
                      summary: summary,
                      weatherKind: weatherKind,
                      weatherLabel: weatherLabelText,
                      geoLocationLabel: geoLocationLabel,
                      onRecordTap: () => context.go('/records'),
                      onLevelTap: () =>
                          context.push('/more/my-level?scrollTo=titles'),
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
                              context.go('/records');
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                showAddMomentFlow(context, ref);
                              });
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
            );
    if (_activeStoryIsland?.id == updated.id) {
      setState(() => _activeStoryIsland = updated);
    }
  }
}

class _IslandDirectoryHome extends StatefulWidget {
  const _IslandDirectoryHome({
    required this.palette,
    required this.groups,
    required this.loading,
    required this.onRefresh,
    required this.onIslandSelected,
    required this.onCreateIsland,
    required this.onEditIsland,
    required this.onRecordTap,
  });

  final MoodPalette palette;
  final List<StoryIslandCategoryModel> groups;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<StoryIslandModel> onIslandSelected;
  final ValueChanged<StoryIslandCategoryModel> onCreateIsland;
  final ValueChanged<StoryIslandModel> onEditIsland;
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.gradientStart,
                    palette.gradientEnd,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '我的岛屿',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: palette.primary,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '先选择标签，再进入对应岛屿。每篇日常都会化作一颗种子落到岛上。',
                        style: TextStyle(
                          color: palette.primary.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
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
                        SizedBox(
                          height: 104,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: groups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              final selected = group.id == selectedGroup?.id;
                              return _StoryCategoryCard(
                                group: group,
                                selected: selected,
                                palette: palette,
                                onTap: () =>
                                    setState(() => _categoryId = group.id),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedGroup?.label ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: palette.primary,
                                    ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: selectedGroup == null
                                  ? null
                                  : () => widget.onCreateIsland(selectedGroup!),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('新建岛屿'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.86),
                            itemCount: selectedGroup?.islands.length ?? 0,
                            itemBuilder: (context, index) {
                              final island = selectedGroup!.islands[index];
                              return _StoryIslandCard(
                                island: island,
                                palette: palette,
                                onTap: () => widget.onIslandSelected(island),
                                onEdit: () => widget.onEditIsland(island),
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
    return Material(
      color: selected ? palette.card : palette.card.withValues(alpha: 0.66),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.72),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: palette.accent),
              const Spacer(),
              Text(
                group.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${group.islands.length} 座岛屿',
                style: TextStyle(
                  color: palette.primary.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryIslandCard extends StatelessWidget {
  const _StoryIslandCard({
    required this.island,
    required this.palette,
    required this.onTap,
    required this.onEdit,
  });

  final StoryIslandModel island;
  final MoodPalette palette;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14, bottom: 8),
      child: Material(
        color: palette.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 92,
                      color: palette.accent.withValues(alpha: 0.52),
                    ),
                  ),
                ),
                Text(
                  island.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lv.${island.currentLevel}/10 · ${island.activeDays}/${island.targetCompletionDays} 活跃天',
                  style: TextStyle(
                    color: palette.primary.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _nextUnlockLabel(island),
                  style: TextStyle(
                    color: palette.primary.withValues(alpha: 0.52),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressionLevelStrip(island: island, palette: palette),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.travel_explore_rounded),
                        label: const Text('穿梭进入'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: onEdit,
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: '编辑岛屿目标',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _nextUnlockLabel(StoryIslandModel island) {
    for (final level in island.progressionPlan) {
      if (!level.unlocked) {
        final remain = (level.thresholdDay - island.activeDays).clamp(0, 999);
        return '再活跃 $remain 天解锁 Lv.${level.level} ${level.buildingType}';
      }
    }
    return '全部 10 阶段建筑已解锁';
  }
}

class _ProgressionLevelStrip extends StatelessWidget {
  const _ProgressionLevelStrip({
    required this.island,
    required this.palette,
  });

  final StoryIslandModel island;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    final levels = island.progressionPlan;
    if (levels.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final level in levels)
          InkWell(
            onTap: () => _showUnlockInfo(context, level),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: level.unlocked
                    ? palette.accent.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.72),
                border: Border.all(
                  color: level.unlocked
                      ? palette.accent
                      : palette.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                '${level.level}',
                style: TextStyle(
                  color: level.unlocked ? palette.accent : palette.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showUnlockInfo(
    BuildContext context,
    StoryIslandProgressLevelModel level,
  ) {
    final unlockedText = level.unlockedAt == null
        ? '尚未解锁'
        : '${level.unlockedAt!.year}-${level.unlockedAt!.month.toString().padLeft(2, '0')}-${level.unlockedAt!.day.toString().padLeft(2, '0')} 首次解锁';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lv.${level.level} ${level.buildingType}'),
        content: Text(
          '解锁阈值：第 ${level.thresholdDay} 个活跃天\n'
          '空间位置：${_ringLabel(level.ring)}\n'
          '首次解锁：$unlockedText\n\n'
          '${level.visualDescription ?? ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  String _ringLabel(String ring) {
    return switch (ring) {
      'outer' => '外圈',
      'middle' => '中圈',
      'inner' => '内圈',
      'center' => '中心地标',
      _ => ring,
    };
  }
}

class _IslandBackButton extends StatelessWidget {
  const _IslandBackButton({
    required this.islandName,
    required this.onBack,
  });

  final String islandName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, size: 20),
              const SizedBox(width: 6),
              Text(
                islandName,
                style: const TextStyle(fontWeight: FontWeight.w800),
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
    this.completionTargetDate,
  });

  final String name;
  final int targetCompletionDays;
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
