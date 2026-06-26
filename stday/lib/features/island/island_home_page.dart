import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/daily_level_unlock_prompt.dart';
import '../../core/growth/growth_system.dart';
import '../../core/weather/weather_display.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/companion_loading.dart';
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
    final buildingUnlocks = ref.watch(buildingUnlocksProvider).valueOrNull ?? const {};
    final summary = growthAsync.valueOrNull ?? GrowthSummary.guest();

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
              final selected = _selectedBuilding;
              final anchor = _selectedBuildingAnchor;
              final unlockDate = selected == null
                  ? null
                  : buildingUnlocks[selected.definitionId] ?? selected.unlockedAt;

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
}
