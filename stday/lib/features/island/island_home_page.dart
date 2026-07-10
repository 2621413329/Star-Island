import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/story_island_layout.dart';
import '../../core/constants/story_island_size.dart';
import '../../core/constants/emotion_catalog.dart';
import '../../core/constants/island_weather.dart';
import '../../core/growth/daily_level_unlock_prompt.dart';
import '../../core/growth/growth_system.dart';
import '../../core/growth/level_title_assets.dart';
import '../../core/models/character_mood.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/story_island_names.dart';
import '../../core/weather/weather_display.dart';
import '../../data/models/profile_models.dart';
import '../../data/models/story_island_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_decorations.dart';
import '../../island/providers/building_unlocks_provider.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/building_info_bubble.dart';
import '../../island/service/building_display_names.dart';
import '../../providers/app_providers.dart';
import '../../providers/current_island_provider.dart';
import '../../providers/island_weather_provider.dart';
import '../../providers/main_shell_tab_provider.dart';
import '../../providers/story_day_provider.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/membership_feature_provider.dart';
import '../../core/membership/vip_guard.dart';
import '../../router/widget_deep_link_handler.dart';
import '../../world/behaviors/companion_hit_test.dart';
import '../../world/engine/world_state.dart';
import 'widgets/island_companion_speech_overlay.dart';
import '../achievement/growth_reward_actions.dart';
import '../today/add_moment_flow.dart';
import '../home/home_page.dart';
import 'story_island_progress.dart';
import 'widgets/story_island_collapsible_task_dock.dart';
import 'widgets/story_island_static_detail_viewport.dart';

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
  bool _mainIslandDetailActive = false;
  StorySeedAnimationRequest? _seedAnimationRequest;
  bool _showSeedAnimation = false;
  int? _pendingIslandGrowthDelta;
  String? _creatingTaskIslandId;
  final Set<String> _busyTaskIds = <String>{};
  static const _viewportScale = 1.91;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  bool get _enginePaused {
    final onIslandTab = ref.watch(mainShellTabIndexProvider) == 0;
    final appActive = _lifecycle == AppLifecycleState.resumed;
    return !onIslandTab || !appActive || _isDetailVisible;
  }

  bool get _isDetailVisible =>
      _activeStoryIsland != null || _mainIslandDetailActive;

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
    Future.microtask(() => _scheduleSilentIslandRefresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumePendingWidgetNavigation());
    });
  }

  Future<void> _consumePendingWidgetNavigation() async {
    if (!mounted) return;
    final pending = ref.read(pendingIslandWidgetNavigationProvider);
    if (pending == null) return;
    ref.read(pendingIslandWidgetNavigationProvider.notifier).state = null;
    await handlePendingIslandWidgetNavigation(
      context: context,
      ref: ref,
      navigation: pending,
      openIslandDetail: _openIslandDetailForWidget,
    );
  }

  /// 首屏先出 UI，数据在后台静默刷新。
  void _scheduleSilentIslandRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_silentRefreshIslandData());
    });
  }

  Future<void> _silentRefreshIslandData() async {
    unawaited(ref.read(storyDayViewProvider.notifier).refresh());
    unawaited(ref.read(todayMomentsProvider.notifier).refresh());
    unawaited(ref.read(storyIslandGroupsProvider.notifier).refresh());
    unawaited(ref.read(growthMainIslandProvider.notifier).refresh());
    unawaited(ref.refresh(growthSummaryProvider.future));
    unawaited(ref.refresh(buildingUnlocksProvider.future));
    unawaited(ref.refresh(moodReportCheckInProvider.future));
    scheduleDeferredIslandWeatherFetch(ref);
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
    enableIslandWeatherFetch(ref);
    await Future.wait([
      ref.read(storyDayViewProvider.notifier).refresh(),
      ref.read(todayMomentsProvider.notifier).refresh(),
      ref.read(storyIslandGroupsProvider.notifier).refresh(),
      ref.read(growthMainIslandProvider.notifier).refresh(),
    ]);
    ref.invalidate(moodReportCheckInProvider);
    ref.invalidate(buildingUnlocksProvider);
    ref.invalidate(growthSummaryProvider);
    ref.invalidate(islandWeatherProvider);
    await Future.wait([
      ref.read(growthSummaryProvider.future),
      ref.read(islandWeatherProvider.future),
    ]);
  }

  Future<void> _addMomentToActiveStoryIsland() async {
    final island = _activeStoryIsland;
    if (island == null) return;
    final growthBefore = ref.read(growthSummaryProvider).valueOrNull;
    final islandGrowthBefore = island.growthValue;
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
      final islandGrowthDelta = updated.growthValue - islandGrowthBefore;
      setState(() {
        _activeStoryIsland = updated;
        _pendingIslandGrowthDelta =
            islandGrowthDelta > 0 ? islandGrowthDelta : null;
        _seedAnimationRequest = StorySeedAnimationRequest(
          momentId: '',
          toIslandId: updated.id,
          toIslandName: updated.name,
          growthDelta: islandGrowthDelta > 0 ? islandGrowthDelta : null,
        );
        _showSeedAnimation = true;
      });
    }
    if (mounted) {
      await showGrowthRewardsAfterAction(
        context,
        ref,
        before: growthBefore,
      );
    }
  }

  void _onSeedAnimationCompleted() {
    if (!mounted) return;
    setState(() => _showSeedAnimation = false);
    final islandGrowth = _pendingIslandGrowthDelta;
    _pendingIslandGrowthDelta = null;
    if (islandGrowth != null && islandGrowth > 0) {
      _showStoryIslandGrowthFeedback(islandGrowth);
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
    final growthMainAsync = ref.watch(growthMainIslandProvider);
    final growthMainIsland = growthMainAsync.valueOrNull;
    final pendingSeedAnimation = ref.watch(pendingStorySeedAnimationProvider);
    if (pendingSeedAnimation != null &&
        (storyGroups.isNotEmpty || growthMainIsland != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target =
            _findStoryIsland(storyGroups, pendingSeedAnimation.toIslandId) ??
                (growthMainIsland?.id == pendingSeedAnimation.toIslandId
                    ? growthMainIsland
                    : null);
        if (target == null) return;
        ref.read(pendingStorySeedAnimationProvider.notifier).state = null;
        setState(() {
          _activeStoryIsland = target;
          _selectedBuilding = null;
          _selectedBuildingAnchor = null;
          _seedAnimationRequest = pendingSeedAnimation;
          _showSeedAnimation = true;
        });
        ref.read(currentIslandProvider.notifier).selectFromIsland(target);
      });
    }

    _bootstrapCurrentIslandIfNeeded(storyGroups, growthMainIsland);

    ref.listen<PendingIslandWidgetNavigation?>(
      pendingIslandWidgetNavigationProvider,
      (previous, next) {
        if (next == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          ref.read(pendingIslandWidgetNavigationProvider.notifier).state = null;
          await handlePendingIslandWidgetNavigation(
            context: context,
            ref: ref,
            navigation: next,
            openIslandDetail: _openIslandDetailForWidget,
          );
        });
      },
    );

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
      backgroundColor:
          _isDetailVisible ? palette.gradientStart : Colors.transparent,
      extendBodyBehindAppBar: _isDetailVisible,
      body: _buildIslandScaffoldBody(
        growthAsync: growthAsync,
        palette: palette,
        storyGroups: storyGroups,
        storyGroupsAsync: storyGroupsAsync,
        growthMainAsync: growthMainAsync,
        growthMainIsland: growthMainIsland,
        summary: summary,
        moments: moments,
        weatherKind: weatherKind,
        weatherLabelText: weatherLabelText,
        geoLocationLabel: geoLocationLabel,
        buildingUnlocks: buildingUnlocks,
      ),
    );
  }

  Widget _buildIslandScaffoldBody({
    required AsyncValue<GrowthSummary> growthAsync,
    required MoodPalette palette,
    required List<StoryIslandCategoryModel> storyGroups,
    required AsyncValue<List<StoryIslandCategoryModel>> storyGroupsAsync,
    required AsyncValue<StoryIslandModel?> growthMainAsync,
    required StoryIslandModel? growthMainIsland,
    required GrowthSummary summary,
    required List<DailyMomentModel> moments,
    required IslandWeather weatherKind,
    required String weatherLabelText,
    required String geoLocationLabel,
    required Map<String, DateTime> buildingUnlocks,
  }) {
    if (growthAsync.hasError && growthAsync.valueOrNull == null) {
      return Center(child: Text('加载失败：${growthAsync.error}'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return IndexedStack(
          index: _isDetailVisible ? 1 : 0,
          sizing: StackFit.expand,
          children: [
            Stack(
              children: [
                HomePage(
                  enginePaused: _enginePaused,
                  onRefresh: _refresh,
                  onStoryIslandSelected: (island) {
                    setState(() {
                      _mainIslandDetailActive = false;
                      _activeStoryIsland = island;
                      _selectedBuilding = null;
                      _selectedBuildingAnchor = null;
                    });
                    ref
                        .read(currentIslandProvider.notifier)
                        .selectFromIsland(island);
                  },
                  onMainIslandSelected: () {
                    final mainIsland = growthMainIsland;
                    setState(() {
                      _activeStoryIsland = null;
                      _mainIslandDetailActive = true;
                    });
                    if (mainIsland != null) {
                      ref
                          .read(currentIslandProvider.notifier)
                          .selectFromIsland(mainIsland);
                    }
                  },
                  onCreateIslandForCategory: _createStoryIsland,
                ),
              ],
            ),
            if (!_isDetailVisible)
              const SizedBox.shrink()
            else if (_activeStoryIsland != null)
              _buildActiveStoryIslandLayer(
                constraints: constraints,
                palette: palette,
                weatherKind: weatherKind,
                weatherLabelText: weatherLabelText,
                geoLocationLabel: geoLocationLabel,
                buildingUnlocks: buildingUnlocks,
              )
            else
              _buildMainIslandDetailLayer(
                constraints: constraints,
                palette: palette,
                summary: summary,
                growthMainAsync: growthMainAsync,
                growthMainIsland: growthMainIsland,
                weatherKind: weatherKind,
                weatherLabelText: weatherLabelText,
                geoLocationLabel: geoLocationLabel,
                buildingUnlocks: buildingUnlocks,
              ),
          ],
        );
      },
    );
  }

  Widget _buildActiveStoryIslandLayer({
    required BoxConstraints constraints,
    required MoodPalette palette,
    required IslandWeather weatherKind,
    required String weatherLabelText,
    required String geoLocationLabel,
    required Map<String, DateTime> buildingUnlocks,
  }) {
    final selected = _selectedBuilding;
    final anchor = _selectedBuildingAnchor;
    final unlockDate = selected == null
        ? null
        : selected.unlockedAt ?? buildingUnlocks[selected.definitionId];
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: StoryIslandStaticDetailViewport(
            key: ValueKey(
              'story_island_${_activeStoryIsland!.id}_${_activeStoryIsland!.currentLevel}',
            ),
            island: _activeStoryIsland!,
            onBuildingTap: _onBuildingTap,
          ),
        ),
        if (_showSeedAnimation && _seedAnimationRequest != null)
          Positioned.fill(
            child: _SeedTransferOverlay(
              request: _seedAnimationRequest!,
              islandName: _activeStoryIsland!.name,
              palette: palette,
              onCompleted: _onSeedAnimationCompleted,
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
          top: MediaQuery.paddingOf(context).top + 8,
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
          right: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 78,
          child: StoryIslandCollapsibleTaskDock(
            island: _activeStoryIsland!,
            palette: palette,
            creatingTask: _creatingTaskIslandId == _activeStoryIsland!.id,
            busyTaskIds: _busyTaskIds,
            onAdd: () => _createStoryIslandTask(_activeStoryIsland!),
            onEdit: (task) => _editStoryIslandTask(_activeStoryIsland!, task),
            onDelete: (task) =>
                _deleteStoryIslandTask(_activeStoryIsland!, task),
            onComplete: (task) =>
                _completeStoryIslandTask(_activeStoryIsland!, task),
            onUncomplete: (task) =>
                _uncompleteStoryIslandTask(_activeStoryIsland!, task),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.paddingOf(context).bottom + 14,
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
  }

  Widget _buildMainIslandDetailLayer({
    required BoxConstraints constraints,
    required MoodPalette palette,
    required GrowthSummary summary,
    required AsyncValue<StoryIslandModel?> growthMainAsync,
    required StoryIslandModel? growthMainIsland,
    required IslandWeather weatherKind,
    required String weatherLabelText,
    required String geoLocationLabel,
    required Map<String, DateTime> buildingUnlocks,
  }) {
    final selected = _selectedBuilding;
    final anchor = _selectedBuildingAnchor;
    final unlockDate = selected == null
        ? null
        : selected.unlockedAt ?? buildingUnlocks[selected.definitionId];

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GrowthWorldViewport(
            key: ValueKey('main_island_detail_${summary.level}'),
            useIslandWorldProvider: true,
            interactive: true,
            enginePaused: false,
            enableDecor: true,
            onBuildingTap: _onBuildingTap,
            onCharacterInteraction: (_, __, characterId) {
              if (characterId == 'protagonist') _onCompanionTap();
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
          top: MediaQuery.paddingOf(context).top + 8,
          child: _MainIslandHudOverlay(
            summary: summary,
            weatherKind: weatherKind,
            weatherLabel: weatherLabelText,
            geoLocationLabel: geoLocationLabel,
            palette: palette,
            onBack: () {
              _clearCompanionSpeech();
              _dismissBuildingBubble();
              setState(() => _mainIslandDetailActive = false);
            },
          ),
        ),
        if (growthMainIsland != null || growthMainAsync.isLoading)
          Positioned(
            right: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 78,
            child: StoryIslandCollapsibleTaskDock(
              island: growthMainIsland,
              loading: growthMainAsync.isLoading && growthMainIsland == null,
              palette: palette,
              creatingTask: growthMainIsland != null &&
                  _creatingTaskIslandId == growthMainIsland.id,
              busyTaskIds: _busyTaskIds,
              onAdd: growthMainIsland == null
                  ? () {}
                  : () => _createStoryIslandTask(growthMainIsland),
              onEdit: growthMainIsland == null
                  ? (_) {}
                  : (task) => _editStoryIslandTask(growthMainIsland, task),
              onDelete: growthMainIsland == null
                  ? (_) {}
                  : (task) => _deleteStoryIslandTask(growthMainIsland, task),
              onComplete: growthMainIsland == null
                  ? (_) {}
                  : (task) => _completeStoryIslandTask(growthMainIsland, task),
              onUncomplete: growthMainIsland == null
                  ? (_) {}
                  : (task) =>
                      _uncompleteStoryIslandTask(growthMainIsland, task),
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
                  onWriteStory: () async {
                    _clearCompanionSpeech();
                    await showAddMomentFlow(context, ref);
                  },
                ),
              ],
            );
          },
        ),
      ],
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
    final groups = ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
    final islandCount = countActiveStoryIslands(groups);
    if (!ref.read(isVipProvider) && islandCount >= nonVipStoryIslandLimit) {
      await showVipRequiredDialog(
        context,
        message: '非 VIP 用户最多创建 $nonVipStoryIslandLimit 个小岛，开通 VIP 可创建更多',
      );
      return;
    }
    final defaultStem = storyIslandNameStem(
        defaultStoryIslandName(category.id, category.label));
    final palette = ref.read(moodPaletteProvider);
    final result = await _showStoryIslandEditorDialog(
      context: context,
      palette: palette,
      title: '新建${category.label}岛屿',
      defaultNameStem: defaultStem,
    );
    if (result == null || !mounted) return;
    if (result.deleted) return;
    await ref.read(storyIslandGroupsProvider.notifier).createIsland(
          categoryId: category.id,
          name: result.name,
          sizeKind: result.sizeKind,
        );
    if (result.sortOrders.isNotEmpty) {
      await _applyIslandSortOrders(result.sortOrders);
    }
  }

  Future<void> _editStoryIsland(StoryIslandModel island) async {
    final groups = ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
    StoryIslandCategoryModel? category;
    for (final group in groups) {
      if (group.id == island.categoryId) {
        category = group;
        break;
      }
    }
    final siblings = category?.islands ?? [island];
    final palette = ref.read(moodPaletteProvider);
    final result = await _showStoryIslandEditorDialog(
      context: context,
      palette: palette,
      title: '编辑${storyIslandNameStem(island.name)}',
      island: island,
      categoryIslands: siblings,
    );
    if (result == null || !mounted) return;
    if (result.deleted) {
      await ref.read(storyIslandGroupsProvider.notifier).updateIsland(
            id: island.id,
            isArchived: true,
          );
      if (_activeStoryIsland?.id == island.id) {
        setState(() => _activeStoryIsland = null);
      }
      return;
    }
    final updated =
        await ref.read(storyIslandGroupsProvider.notifier).updateIsland(
              id: island.id,
              name: result.name,
              sizeKind: result.sizeKind,
            );
    if (result.sortOrders.isNotEmpty) {
      await _applyIslandSortOrders(result.sortOrders);
    }
    if (_activeStoryIsland?.id == updated.id) {
      setState(() => _activeStoryIsland = updated);
    }
  }

  Future<void> _applyIslandSortOrders(Map<String, int> sortOrders) async {
    final repo = ref.read(storyIslandRepositoryProvider);
    for (final entry in sortOrders.entries) {
      await repo.updateStoryIsland(id: entry.key, sortOrder: entry.value);
    }
    await ref.read(storyIslandGroupsProvider.notifier).refresh();
  }

  Future<void> _createStoryIslandTask(StoryIslandModel island) async {
    if (_creatingTaskIslandId == island.id) return;
    final palette = ref.read(moodPaletteProvider);
    final result = await _showStoryIslandTaskDialog(
      context: context,
      palette: palette,
      categoryId: island.categoryId,
      islandNameStem: storyIslandNameStem(island.name),
    );
    if (result == null || !mounted) return;
    setState(() => _creatingTaskIslandId = island.id);
    try {
      if (island.isGrowthMainIsland) {
        await ref.read(storyIslandRepositoryProvider).createTask(
              islandId: island.id,
              title: result.title,
              isDaily: result.isDaily,
            );
        await _syncGrowthMainIsland();
        return;
      }
      await ref.read(storyIslandGroupsProvider.notifier).createTask(
            islandId: island.id,
            title: result.title,
            isDaily: result.isDaily,
          );
      await _syncActiveStoryIsland(island.id);
    } finally {
      if (mounted && _creatingTaskIslandId == island.id) {
        setState(() => _creatingTaskIslandId = null);
      }
    }
  }

  Future<void> _editStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    final palette = ref.read(moodPaletteProvider);
    final result = await _showStoryIslandTaskDialog(
      context: context,
      palette: palette,
      categoryId: island.categoryId,
      islandNameStem: storyIslandNameStem(island.name),
      task: task,
    );
    if (result == null || !mounted) return;
    if (island.isGrowthMainIsland) {
      await ref.read(storyIslandRepositoryProvider).updateTask(
            islandId: island.id,
            taskId: task.id,
            title: result.title,
            isDaily: result.isDaily,
          );
      await _syncGrowthMainIsland();
      return;
    }
    await ref.read(storyIslandGroupsProvider.notifier).updateTask(
          islandId: island.id,
          taskId: task.id,
          title: result.title,
          isDaily: result.isDaily,
        );
    await _syncActiveStoryIsland(island.id);
  }

  Future<void> _deleteStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    if (island.isGrowthMainIsland) {
      await ref.read(storyIslandRepositoryProvider).deleteTask(
            islandId: island.id,
            taskId: task.id,
          );
      await _syncGrowthMainIsland();
      return;
    }
    await ref.read(storyIslandGroupsProvider.notifier).deleteTask(
          islandId: island.id,
          taskId: task.id,
        );
    await _syncActiveStoryIsland(island.id);
  }

  Future<void> _syncActiveStoryIsland(String islandId) async {
    if (_activeStoryIsland?.id != islandId) return;
    await ref.read(storyIslandGroupsProvider.notifier).refresh();
    final groups = ref.read(storyIslandGroupsProvider).valueOrNull ?? const [];
    for (final group in groups) {
      for (final island in group.islands) {
        if (island.id == islandId) {
          if (!mounted) return;
          setState(() => _activeStoryIsland = island);
          return;
        }
      }
    }
  }

  void _showStoryIslandGrowthFeedback(int delta) {
    if (delta == 0) return;
    AppFeedback.showStrong(
      context,
      message: delta > 0 ? '岛屿成长值 +$delta' : '岛屿成长值 $delta',
      subtitle: delta > 0 ? '今日待办已完成' : '已撤销今日完成',
    );
  }

  void _showUserXpFeedback(int delta, {required bool completed}) {
    if (delta == 0) return;
    AppFeedback.showStrong(
      context,
      message: delta > 0 ? '经验值 +$delta' : '经验值 $delta',
      subtitle: completed ? '今日待办已完成' : '已撤销今日完成',
    );
  }

  StoryIslandTaskModel? _findTaskOnIsland(
    StoryIslandModel island,
    String taskId,
  ) {
    for (final task in island.todayTasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  Future<void> _syncGrowthMainIsland() async {
    await ref.read(growthMainIslandProvider.notifier).refresh();
  }

  Future<void> _completeStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    if (task.completedToday || _busyTaskIds.contains(task.id)) return;
    setState(() => _busyTaskIds.add(task.id));
    final StoryIslandModel updated;
    try {
      if (island.isGrowthMainIsland) {
        final growthBefore = ref.read(growthSummaryProvider).valueOrNull;
        updated = await ref.read(storyIslandRepositoryProvider).completeTask(
              islandId: island.id,
              taskId: task.id,
            );
        ref.read(growthMainIslandProvider.notifier).patchIsland(updated);
        ref.invalidate(growthSummaryProvider);
        if (mounted) {
          await showGrowthRewardsAfterAction(
            context,
            ref,
            before: growthBefore,
          );
        }
      } else {
        updated =
            await ref.read(storyIslandGroupsProvider.notifier).completeTask(
                  islandId: island.id,
                  taskId: task.id,
                );
        final latest = _findTaskOnIsland(updated, task.id);
        _showStoryIslandGrowthFeedback(latest?.growthDelta ?? task.growthDelta);
        if (_activeStoryIsland?.id == island.id) {
          setState(() => _activeStoryIsland = updated);
        }
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _busyTaskIds.remove(task.id));
      }
    }
  }

  Future<void> _uncompleteStoryIslandTask(
    StoryIslandModel island,
    StoryIslandTaskModel task,
  ) async {
    if (!task.completedToday || _busyTaskIds.contains(task.id)) return;
    setState(() => _busyTaskIds.add(task.id));
    final StoryIslandModel updated;
    try {
      if (island.isGrowthMainIsland) {
        final growthBefore = ref.read(growthSummaryProvider).valueOrNull;
        updated = await ref.read(storyIslandRepositoryProvider).uncompleteTask(
              islandId: island.id,
              taskId: task.id,
            );
        ref.read(growthMainIslandProvider.notifier).patchIsland(updated);
        ref.invalidate(growthSummaryProvider);
        if (task.growthDelta > 0) {
          _showUserXpFeedback(-task.growthDelta, completed: false);
        }
        if (mounted) {
          await showGrowthRewardsAfterAction(
            context,
            ref,
            before: growthBefore,
          );
        }
      } else {
        updated =
            await ref.read(storyIslandGroupsProvider.notifier).uncompleteTask(
                  islandId: island.id,
                  taskId: task.id,
                );
        if (task.growthDelta > 0) {
          _showStoryIslandGrowthFeedback(-task.growthDelta);
        }
        if (_activeStoryIsland?.id == island.id) {
          setState(() => _activeStoryIsland = updated);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _busyTaskIds.remove(task.id));
      }
    }
  }

  void _bootstrapCurrentIslandIfNeeded(
    List<StoryIslandCategoryModel> groups,
    StoryIslandModel? growthMainIsland,
  ) {
    final current = ref.read(currentIslandProvider);
    if (current != null) {
      final resolved = findStoryIslandById(
        groups,
        current.id,
        growthMainIsland: growthMainIsland,
      );
      if (resolved != null) return;
    }

    StoryIslandModel? fallback;
    if (_activeStoryIsland != null) {
      fallback = _activeStoryIsland;
    } else if (_mainIslandDetailActive && growthMainIsland != null) {
      fallback = growthMainIsland;
    } else {
      for (final group in groups) {
        if (group.islands.isNotEmpty) {
          fallback = group.islands.first;
          break;
        }
      }
      fallback ??= growthMainIsland;
    }
    if (fallback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(currentIslandProvider.notifier).selectFromIsland(fallback!);
    });
  }

  Future<void> _openIslandDetailForWidget(StoryIslandModel island) async {
    if (!mounted) return;
    if (island.isGrowthMainIsland) {
      setState(() {
        _activeStoryIsland = null;
        _mainIslandDetailActive = true;
        _selectedBuilding = null;
        _selectedBuildingAnchor = null;
      });
    } else {
      setState(() {
        _mainIslandDetailActive = false;
        _activeStoryIsland = island;
        _selectedBuilding = null;
        _selectedBuildingAnchor = null;
      });
    }
    await ref.read(currentIslandProvider.notifier).selectFromIsland(island);
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
    required this.onCategoryOrderChanged,
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
  final Future<void> Function(List<String> order) onCategoryOrderChanged;

  @override
  State<_IslandDirectoryHome> createState() => _IslandDirectoryHomeState();
}

class _IslandDirectoryHomeState extends State<_IslandDirectoryHome> {
  String? _categoryId;
  final Map<String, PageController> _pageControllers = {};
  final Map<String, int> _pageIndexByCategory = {};

  @override
  void initState() {
    super.initState();
    if (widget.groups.isNotEmpty) {
      _categoryId = widget.groups.first.id;
    }
  }

  @override
  void dispose() {
    for (final controller in _pageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PageController _pageControllerFor(String categoryId) {
    return _pageControllers.putIfAbsent(
      categoryId,
      () => PageController(
        viewportFraction: 0.86,
        initialPage: _pageIndexByCategory[categoryId] ?? 0,
      ),
    );
  }

  void _rememberPageIndex(String categoryId, int index) {
    _pageIndexByCategory[categoryId] = index;
  }

  void _restorePagePositions() {
    for (final group in widget.groups) {
      final saved = _pageIndexByCategory[group.id];
      if (saved == null) continue;
      final controller = _pageControllers[group.id];
      if (controller == null || !controller.hasClients) continue;
      final maxPage = group.islands.length;
      final target = saved.clamp(0, maxPage);
      if (controller.page?.round() != target) {
        controller.jumpToPage(target);
      }
    }
  }

  void _selectCategory(String categoryId) {
    if (_categoryId == categoryId) {
      final controller = _pageControllers[categoryId];
      if (controller != null && controller.hasClients) {
        controller.animateToPage(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
        _pageIndexByCategory[categoryId] = 0;
      }
      return;
    }
    setState(() => _categoryId = categoryId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _pageControllers[categoryId];
      if (controller != null && controller.hasClients) {
        final target = _pageIndexByCategory[categoryId] ?? 0;
        controller.jumpToPage(target);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _IslandDirectoryHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_categoryId == null && widget.groups.isNotEmpty) {
      _categoryId = widget.groups.first.id;
    }
    if (oldWidget.groups != widget.groups) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _restorePagePositions();
      });
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
                        _StoryCategoryTabBar(
                          groups: groups,
                          selectedCategoryId: _categoryId,
                          palette: palette,
                          onCategorySelected: _selectCategory,
                          onOrderChanged: widget.onCategoryOrderChanged,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PageView.builder(
                            key: ValueKey(selectedGroup!.id),
                            controller: _pageControllerFor(selectedGroup.id),
                            onPageChanged: (index) =>
                                _rememberPageIndex(selectedGroup!.id, index),
                            itemCount: selectedGroup.islands.length + 1,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _StoryIslandCard(
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
                                        userTitleLevel: widget.summary.level,
                                      ),
                                      onTap: () =>
                                          widget.onIslandSelected(island),
                                      onEdit: () => widget.onEditIsland(island),
                                    ),
                                    const SizedBox(height: 6),
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
                                      onUncomplete: (task) =>
                                          widget.onUncompleteTask(island, task),
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
    final place = geoLocationLabel.trim();
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
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
                  Row(
                    children: [
                      Text(
                        '🔥  ${summary.streakDays} 天',
                        style: TextStyle(
                          color: palette.primary.withValues(alpha: 0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (place.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.primary.withValues(alpha: 0.54),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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
                ],
              ),
            ),
            const SizedBox(width: 6),
            LevelTitleBadgeImage(
              level: summary.level,
              size: 52,
              borderRadius: 12,
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

class _StoryCategoryTabBar extends StatefulWidget {
  const _StoryCategoryTabBar({
    required this.groups,
    required this.selectedCategoryId,
    required this.palette,
    required this.onCategorySelected,
    required this.onOrderChanged,
  });

  final List<StoryIslandCategoryModel> groups;
  final String? selectedCategoryId;
  final MoodPalette palette;
  final ValueChanged<String> onCategorySelected;
  final Future<void> Function(List<String> order) onOrderChanged;

  @override
  State<_StoryCategoryTabBar> createState() => _StoryCategoryTabBarState();
}

class _StoryCategoryTabBarState extends State<_StoryCategoryTabBar> {
  bool _reordering = false;
  late List<String> _orderIds;
  List<String>? _orderAtReorderStart;

  @override
  void initState() {
    super.initState();
    _orderIds = widget.groups.map((group) => group.id).toList();
  }

  @override
  void didUpdateWidget(covariant _StoryCategoryTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reordering) {
      _syncOrderFromGroups();
      return;
    }
    final known = _orderIds.toSet();
    for (final group in widget.groups) {
      if (!known.contains(group.id)) {
        _orderIds.add(group.id);
      }
    }
  }

  void _syncOrderFromGroups() {
    final remoteOrder = widget.groups.map((group) => group.id).toList();
    if (!listEquals(remoteOrder, _orderIds)) {
      setState(() => _orderIds = remoteOrder);
    }
  }

  Map<String, StoryIslandCategoryModel> get _groupsById => {
        for (final group in widget.groups) group.id: group,
      };

  void _enterReorderMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _reordering = true;
      _orderAtReorderStart = List<String>.from(_orderIds);
    });
  }

  Future<void> _exitReorderMode({required bool save}) async {
    if (!_reordering) return;
    final changed = save &&
        _orderAtReorderStart != null &&
        !listEquals(_orderAtReorderStart, _orderIds);
    final orderToSave = List<String>.from(_orderIds);
    setState(() {
      _reordering = false;
      _orderAtReorderStart = null;
    });
    if (changed) {
      await widget.onOrderChanged(orderToSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_reordering)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  '拖动调整标签顺序',
                  style: TextStyle(
                    color: palette.primary.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: palette.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _exitReorderMode(save: true),
                  child: const Text(
                    '完成',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 36,
          child: _reordering
              ? ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.zero,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final id = _orderIds.removeAt(oldIndex);
                      _orderIds.insert(newIndex, id);
                    });
                  },
                  itemCount: _orderIds.length,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      elevation: 6,
                      shadowColor: Colors.black26,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final id = _orderIds[index];
                    final group = _groupsById[id];
                    if (group == null) {
                      return SizedBox(key: ValueKey(id));
                    }
                    final selected = id == widget.selectedCategoryId;
                    return Padding(
                      key: ValueKey(id),
                      padding: EdgeInsets.only(
                        right: index < _orderIds.length - 1 ? 8 : 0,
                      ),
                      child: ReorderableDragStartListener(
                        index: index,
                        child: _JigglingStoryCategoryCard(
                          active: true,
                          index: index,
                          child: _StoryCategoryCard(
                            group: group,
                            selected: selected,
                            palette: palette,
                            reordering: true,
                            onTap: () {},
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.groups.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final group = widget.groups[index];
                    final selected = group.id == widget.selectedCategoryId;
                    return _StoryCategoryCard(
                      group: group,
                      selected: selected,
                      palette: palette,
                      onTap: () => widget.onCategorySelected(group.id),
                      onLongPress: _enterReorderMode,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _JigglingStoryCategoryCard extends StatefulWidget {
  const _JigglingStoryCategoryCard({
    required this.active,
    required this.index,
    required this.child,
  });

  final bool active;
  final int index;
  final Widget child;

  @override
  State<_JigglingStoryCategoryCard> createState() =>
      _JigglingStoryCategoryCardState();
}

class _JigglingStoryCategoryCardState extends State<_JigglingStoryCategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _JigglingStoryCategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = widget.index * 0.7;
        final angle = sin((_controller.value * pi * 2) + phase) * 0.035;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 1.04,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _StoryCategoryCard extends StatelessWidget {
  const _StoryCategoryCard({
    required this.group,
    required this.selected,
    required this.palette,
    required this.onTap,
    this.onLongPress,
    this.reordering = false,
  });

  final StoryIslandCategoryModel group;
  final bool selected;
  final MoodPalette palette;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool reordering;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFF6658) : Colors.white;
    final foreground = selected ? Colors.white : palette.primary;
    return Material(
      color: color.withValues(alpha: selected ? 1 : 0.78),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: reordering ? null : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
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
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                group.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
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
  String? moodId, {
  required int userTitleLevel,
}) {
  if (island.isGrowthMainIsland) {
    final mood = CharacterMood.fromString(
      emotionById(moodId ?? defaultEmotionId).legacyMoodId,
    );
    return WorldState(
      island: base.island,
      characters: [
        CharacterSnapshot(
          id: 'protagonist',
          mood: mood,
          level: userTitleLevel.clamp(1, 20),
          accessoryIds: const [],
          animationKey: 'idle',
          normalizedPos: const Offset(0.52, 0.54),
          expression: mood.name,
          companionPose: 'breathing',
          scale: 0.92,
        ),
      ],
      buildings: const [],
      flora: const [],
      environment: base.environment,
      zones: base.zones,
      decorations: const [],
      paths: const [],
      effects: const [],
      anchors: base.anchors,
      companionGender: base.companionGender,
      schemaVersion: base.schemaVersion,
    );
  }

  final mood = CharacterMood.fromString(
    emotionById(moodId ?? defaultEmotionId).legacyMoodId,
  );
  return WorldState(
    island: base.island,
    characters: [
      CharacterSnapshot(
        id: 'story_island_card_companion_${island.id}',
        mood: mood,
        level: max(1, userTitleLevel),
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
        anchor: StoryIslandLayout.buildingAnchorForLevel(level),
        type: 'story_${level.ring}',
        size: StoryIslandLayout.buildingSize(level),
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
      padding: const EdgeInsets.only(top: 4),
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
            mainAxisSize: MainAxisSize.min,
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
                          previewZoom: island.isGrowthMainIsland
                              ? 2.1
                              : StoryIslandLayout.cardPreviewZoom(
                                  island.sizeKind,
                                ),
                          scale: 1.0,
                          islandOnly: true,
                          enableDecor: island.isGrowthMainIsland,
                          showBuildings: !island.isGrowthMainIsland,
                          showCharacters: false,
                          force2D: true,
                          clipCompactPreview: true,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton.filledTonal(
                        onPressed: onEdit,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        tooltip: '编辑岛屿',
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
                    '${island.growthValue}',
                    style: TextStyle(
                      color: palette.accent,
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
                        activeTrackColor: palette.accent,
                        inactiveTrackColor: palette.primaryContainer,
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
                storyIslandNextLevelHint(levelProgress),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.primary.withValues(alpha: 0.52),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _EnterIslandButton(palette: palette, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
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
  const _EnterIslandButton({required this.palette, required this.onTap});

  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    final gradientStart = Color.lerp(accent, Colors.white, 0.18)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStart, accent],
                ),
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
    final emptyHint = island.isGrowthMainIsland
        ? '添加待办后，完成一项经验值 +$storyIslandTaskGrowthDelta'
        : '添加待办后，完成一项岛屿成长值 +$storyIslandTaskGrowthDelta';
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
                      '今日待办',
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
                          emptyHint,
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
          Expanded(
            child: InkWell(
              onTap: done ? onUncomplete : onComplete,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: done
                          ? palette.accent
                          : palette.primary.withValues(alpha: 0.42),
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
                  ],
                ),
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
    final levelBadgeLabel =
        island.currentLevel <= 0 ? 'Lv.0/10' : storyIslandLevelLabel(island);
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
                      tooltip: '编辑岛屿',
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
                      color: palette.accent,
                    ),
                    const SizedBox(width: 8),
                    _IslandHudMetric(
                      icon: Icons.local_fire_department_rounded,
                      label: '${island.growthValue}/${island.growthTarget}',
                      color: Color.lerp(palette.accent, Colors.orange, 0.35)!,
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
                    backgroundColor: palette.primaryContainer,
                    valueColor: AlwaysStoppedAnimation(palette.accent),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        levelProgress.isMaxLevel
                            ? '全部建筑已解锁'
                            : storyIslandNextLevelHint(levelProgress),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primary.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

class _MainIslandHudOverlay extends StatelessWidget {
  const _MainIslandHudOverlay({
    required this.summary,
    required this.weatherKind,
    required this.weatherLabel,
    required this.geoLocationLabel,
    required this.palette,
    required this.onBack,
  });

  final GrowthSummary summary;
  final IslandWeather weatherKind;
  final String weatherLabel;
  final String geoLocationLabel;
  final MoodPalette palette;
  final VoidCallback onBack;

  IconData _weatherIcon(IslandWeather weather) {
    return switch (weather) {
      IslandWeather.sunny => Icons.wb_sunny_rounded,
      IslandWeather.softCloud => Icons.cloud_queue_rounded,
      IslandWeather.overcast => Icons.cloud_rounded,
      IslandWeather.drizzle => Icons.water_drop_rounded,
      IslandWeather.windy => Icons.air_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final next = summary.nextLevel;
    final need = summary.xpForNextLevel;
    final progress = need != null && need > 0
        ? (summary.xpIntoLevel / need).clamp(0.0, 1.0)
        : 1.0;

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
                Text(
                  '主岛',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _IslandHudMetric(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Lv.${summary.level}',
                      color: palette.accent,
                    ),
                    const SizedBox(width: 8),
                    _IslandHudMetric(
                      icon: Icons.local_fire_department_rounded,
                      label: '${summary.streakDays}天',
                      color: Color.lerp(palette.accent, Colors.orange, 0.35)!,
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
                    value: progress,
                    minHeight: 8,
                    backgroundColor: palette.primaryContainer,
                    valueColor: AlwaysStoppedAnimation(palette.accent),
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '距离 Lv.$next 还需 ${need ?? 0} 成长值',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
                    '返回我的世界',
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
    required this.sizeKind,
    this.sortOrders = const {},
    this.deleted = false,
  });

  final String name;
  final String sizeKind;
  final Map<String, int> sortOrders;
  final bool deleted;
}

Future<_StoryIslandEditorResult?> _showStoryIslandEditorDialog({
  required BuildContext context,
  required MoodPalette palette,
  required String title,
  StoryIslandModel? island,
  List<StoryIslandModel>? categoryIslands,
  String? defaultNameStem,
}) {
  final initialStem = island != null
      ? storyIslandNameStem(island.name)
      : (defaultNameStem ?? '');
  final nameCtrl = TextEditingController(text: initialStem);
  String sizeKind = island?.sizeKind ?? 'large';
  final orderedIslands = (categoryIslands ?? const <StoryIslandModel>[])
      .map((item) => item)
      .toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.name.compareTo(b.name);
    });
  var currentIndex = island == null
      ? -1
      : orderedIslands.indexWhere((item) => item.id == island.id);
  var swapTick = 0;

  return showDialog<_StoryIslandEditorResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Map<String, int> buildSortOrders() {
            final out = <String, int>{};
            for (var i = 0; i < orderedIslands.length; i++) {
              out[orderedIslands[i].id] = (i + 1) * 10;
            }
            return out;
          }

          void moveIsland(int delta) {
            if (currentIndex < 0) return;
            final target = currentIndex + delta;
            if (target < 0 || target >= orderedIslands.length) return;
            final moving = orderedIslands[currentIndex];
            orderedIslands.removeAt(currentIndex);
            orderedIslands.insert(target, moving);
            setState(() {
              currentIndex = target;
              swapTick++;
            });
          }

          void submit({bool deleted = false}) {
            if (deleted) {
              Navigator.of(context).pop(
                _StoryIslandEditorResult(
                  name: island?.name ?? '',
                  sizeKind: sizeKind,
                  deleted: true,
                ),
              );
              return;
            }
            final name = storyIslandFullName(nameCtrl.text);
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              _StoryIslandEditorResult(
                name: name,
                sizeKind: sizeKind,
                sortOrders: buildSortOrders(),
              ),
            );
          }

          Future<void> confirmDelete() async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('删除岛屿？'),
                content: Text(
                  '删除后「${island?.name ?? ''}」将不再显示，'
                  '已写入该岛屿的日常不会丢失。',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('删除'),
                  ),
                ],
              ),
            );
            if (ok == true) submit(deleted: true);
          }

          final canReorder = island != null && orderedIslands.length > 1;
          final canMoveEarlier = canReorder && currentIndex > 0;
          final canMoveLater = canReorder &&
              currentIndex >= 0 &&
              currentIndex < orderedIslands.length - 1;
          final previewName = currentIndex >= 0
              ? orderedIslands[currentIndex].name
              : storyIslandFullName(nameCtrl.text);

          final borderTint = Color.lerp(palette.accent, Colors.white, 0.55)!;
          final selectedSize = storyIslandSizeOptionFor(sizeKind);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E2A28),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (island != null)
                                IconButton(
                                  tooltip: '删除岛屿',
                                  onPressed: confirmDelete,
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 20),
                                  color: const Color(0xFFE4574C),
                                ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: palette.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: borderTint.withValues(alpha: 0.55),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (canReorder) ...[
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final offset = animation.drive(
                                  Tween<Offset>(
                                    begin: const Offset(0.12, 0),
                                    end: Offset.zero,
                                  ).chain(
                                    CurveTween(curve: Curves.easeOutCubic),
                                  ),
                                );
                                return SlideTransition(
                                  position: offset,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: ValueKey('preview_$swapTick'),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        palette.accent.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '当前顺序 ${currentIndex + 1}/${orderedIslands.length} · $previewName',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF5D4E44),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: '向前移动',
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      onPressed: canMoveEarlier
                                          ? () => moveIsland(-1)
                                          : null,
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 20,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: '向后移动',
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      onPressed: canMoveLater
                                          ? () => moveIsland(1)
                                          : null,
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Text(
                            '岛屿名称',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.primary.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderTint),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: nameCtrl,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '例如：高考',
                                      ),
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => submit(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      '岛',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '岛屿规模',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.primary.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '按每日任务上限 $storyIslandDailyTaskGrowthCap 计算，'
                            '满级需 ${selectedSize.growthTarget} 成长值',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: Color(0xFF8C7B6B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final option in storyIslandSizeOptions) ...[
                            _StoryIslandSizeTile(
                              option: option,
                              selected: sizeKind == option.kind,
                              palette: palette,
                              onTap: () =>
                                  setState(() => sizeKind = option.kind),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.accent,
                            ),
                            child: const Text(
                              '取消',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              onTap: submit,
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                width: 120,
                                height: 44,
                                alignment: Alignment.center,
                                child: const Text(
                                  '保存',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
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
        },
      );
    },
  ).whenComplete(() {
    nameCtrl.dispose();
  });
}

class _StoryIslandSizeTile extends StatelessWidget {
  const _StoryIslandSizeTile({
    required this.option,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final StoryIslandSizeOption option;
  final bool selected;
  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? palette.accent
        : Color.lerp(palette.accent, Colors.white, 0.55)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? palette.primaryContainer : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? palette.accent
                  : borderColor.withValues(alpha: 0.85),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: selected ? palette.accent : const Color(0xFFB0A090),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.cardTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? const Color(0xFF3D3229)
                              : const Color(0xFF5D4E44),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '成长值上限 ${option.growthTarget}',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.primary.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
            gradient: LinearGradient(
              colors: [
                Color.lerp(palette.accent, Colors.white, 0.18)!,
                palette.accent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.26),
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

String _taskInputExampleForCategory(String categoryId) {
  return switch (categoryId) {
    'work' => '例：完成项目进度汇报',
    'study' => '例：专注阅读20分钟',
    'health' => '例：晨跑20分钟',
    'social' => '例：给朋友发一条问候',
    'life' => '例：整理房间15分钟',
    'finance' || 'wealth' => '例：记录今日收支',
    'creation' => '例：写一段灵感笔记',
    _ => '例：专注完成一件事20分钟',
  };
}

IconData _taskInputIconForCategory(String categoryId) {
  return switch (categoryId) {
    'work' => Icons.work_outline_rounded,
    'study' => Icons.menu_book_outlined,
    'health' => Icons.eco_outlined,
    'social' => Icons.favorite_border_rounded,
    'life' => Icons.home_outlined,
    'finance' || 'wealth' => Icons.shield_outlined,
    'creation' => Icons.brush_outlined,
    _ => Icons.task_alt_outlined,
  };
}

Future<_StoryIslandTaskEditorResult?> _showStoryIslandTaskDialog({
  required BuildContext context,
  required MoodPalette palette,
  required String categoryId,
  required String islandNameStem,
  StoryIslandTaskModel? task,
}) {
  final titleCtrl = TextEditingController(text: task?.title ?? '');
  var isDaily = task?.isDaily ?? false;

  final borderTint = Color.lerp(palette.accent, Colors.white, 0.55)!;
  final exampleHint = _taskInputExampleForCategory(categoryId);
  final inputIcon = _taskInputIconForCategory(categoryId);
  final fieldTitle = '${islandNameStem.trim()}任务内容';

  return showDialog<_StoryIslandTaskEditorResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.42),
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

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            task == null ? '添加今日待办' : '修改今日待办',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E2A28),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: borderTint.withValues(alpha: 0.55),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderTint, width: 1),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        inputIcon,
                                        size: 22,
                                        color: palette.accent
                                            .withValues(alpha: 0.82),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          fieldTitle,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: palette.primary
                                                .withValues(alpha: 0.78),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: titleCtrl,
                                    autofocus: task == null,
                                    maxLines: 3,
                                    minLines: 1,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3D3229),
                                      height: 1.35,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: exampleHint,
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF8C7B6B)
                                            .withValues(alpha: 0.85),
                                        height: 1.35,
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => submit(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderTint, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_available_outlined,
                                    size: 22,
                                    color:
                                        palette.accent.withValues(alpha: 0.82),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '每日重复任务',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF3D3229),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '开启后每日自动同步至当前岛屿任务列表',
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.35,
                                            color: const Color(0xFF8C7B6B)
                                                .withValues(alpha: 0.92),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _DuolingoToggle(
                                    value: isDaily,
                                    activeColor: palette.accent,
                                    onChanged: (value) =>
                                        setState(() => isDaily = value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              '取消',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(22),
                            elevation: 0,
                            child: InkWell(
                              onTap: submit,
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                width: 132,
                                height: 46,
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.rocket_launch_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '保存',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        },
      );
    },
  ).whenComplete(titleCtrl.dispose);
}

class _DuolingoToggle extends StatelessWidget {
  const _DuolingoToggle({
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      label: '每日重复任务',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 54,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: value ? activeColor : const Color(0xFFE6E6E6),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
            (_controller.value - 0.45).clamp(0.0, 1.0),
          );
          final flash = Curves.easeOut.transform(
            (1 - (_controller.value - 0.78).abs() * 4).clamp(0.0, 1.0),
          );
          final width = MediaQuery.sizeOf(context).width;
          final height = MediaQuery.sizeOf(context).height;
          final targetX = width * 0.50;
          final targetY = height * 0.56;
          final x = lerpDouble(width * 0.22, targetX, t)!;
          final y = lerpDouble(height * 0.12, targetY, t)! - sin(t * pi) * 72;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.glow
                        .withValues(alpha: 0.24 * glow + 0.08 * flash),
                  ),
                ),
              ),
              Positioned(
                left: targetX - 150,
                top: targetY - 150,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent
                            .withValues(alpha: 0.42 * glow + 0.18 * flash),
                        blurRadius: 90 * glow + 24 * flash,
                        spreadRadius: 32 * glow + 10 * flash,
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
