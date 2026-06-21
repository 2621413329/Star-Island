import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/growth_system.dart';
import '../../core/weather/weather_display.dart';
import '../../design_system/companion_loading.dart';
import '../../island/providers/building_unlocks_provider.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/building_info_bubble.dart';
import '../../island/service/building_display_names.dart';
import '../../island/widgets/island_hud_overlay.dart';
import '../../providers/app_providers.dart';
import '../../providers/island_weather_provider.dart';
import '../../providers/story_day_provider.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../world/engine/world_state.dart';
import 'widgets/island_companion_speech_overlay.dart';
import '../today/add_moment_flow.dart';

/// Growth Island 2.0：全屏成长世界 + HUD 叠层。
class IslandHomePage extends ConsumerStatefulWidget {
  const IslandHomePage({super.key});

  @override
  ConsumerState<IslandHomePage> createState() => _IslandHomePageState();
}

class _IslandHomePageState extends ConsumerState<IslandHomePage> {
  BuildingSnapshot? _selectedBuilding;
  Offset? _selectedBuildingAnchor;
  Timer? _bubbleDismissTimer;
  Timer? _companionSpeechTimer;
  String? _companionSpeech;
  bool _companionSpeechEmptyDay = false;

  @override
  void initState() {
    super.initState();
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
    _bubbleDismissTimer?.cancel();
    _companionSpeechTimer?.cancel();
    super.dispose();
  }

  void _onCompanionTap() {
    final moments = ref.read(todayMomentsProvider).valueOrNull ?? const [];
    final lines = <String>[];
    final nickname = ref.read(profileProvider).valueOrNull?.nickname;
    for (final moment in moments) {
      lines.addAll(moment.storySummaryLinesFor(nickname));
      lines.addAll(moment.waitingLines);
    }
    final cleaned =
        lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    _companionSpeechTimer?.cancel();
    setState(() {
      _companionSpeechEmptyDay = cleaned.isEmpty;
      _companionSpeech = cleaned.isEmpty
          ? '今天还没有写下日常呢，快去写今天的日常哦～'
          : cleaned[Random().nextInt(cleaned.length)];
    });
    _companionSpeechTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _companionSpeech = null;
          _companionSpeechEmptyDay = false;
        });
      }
    });
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

  void _dismissCompanionSpeech() {
    _companionSpeechTimer?.cancel();
    setState(() {
      _companionSpeech = null;
      _companionSpeechEmptyDay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final growthAsync = ref.watch(growthSummaryProvider);
    final buildingUnlocks = ref.watch(buildingUnlocksProvider).valueOrNull ?? const {};
    final summary = growthAsync.valueOrNull ?? GrowthSummary.guest();
    final moments = ref.watch(todayMomentsProvider).valueOrNull ?? const [];
    final weatherAsync = ref.watch(islandWeatherProvider);
    final weather = weatherAsync.valueOrNull;
    final weatherKind = islandWeatherKind(weather);
    final weatherLabelText = weatherDisplayLabelFromSnapshot(weather);

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
                        'island_${summary.level}_${summary.growthValue}_${moments.length}',
                      ),
                      useIslandWorldProvider: true,
                      interactive: true,
                      scale: 1.06,
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
                      onRecordTap: () => context.go('/records'),
                      onLevelTap: () =>
                          context.push('/more/my-level?scrollTo=titles'),
                    ),
                  ),
                  if (_companionSpeech != null)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _dismissCompanionSpeech,
                      ),
                    ),
                  if (_companionSpeech != null)
                    IslandCompanionSpeechOverlay(
                      palette: palette,
                      text: _companionSpeech!,
                      viewportSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                      showWriteStoryAction: _companionSpeechEmptyDay,
                      onWriteStory: () {
                        setState(() {
                          _companionSpeech = null;
                          _companionSpeechEmptyDay = false;
                        });
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
        ),
      ),
    );
  }
}
