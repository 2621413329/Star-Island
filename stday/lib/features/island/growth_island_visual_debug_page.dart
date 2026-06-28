import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/growth/growth_system.dart';
import '../../world/systems/config/day_phase_lighting_config.dart';
import '../../island/decor/decor_config.dart';
import '../../island/providers/island_world_provider.dart';
import '../../island/service/island_style_resolver.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../providers/world_state_provider.dart';
import '../../world/engine/world_state.dart';

class GrowthIslandVisualDebugPage extends ConsumerStatefulWidget {
  const GrowthIslandVisualDebugPage({super.key});

  @override
  ConsumerState<GrowthIslandVisualDebugPage> createState() =>
      _GrowthIslandVisualDebugPageState();
}

class _GrowthIslandVisualDebugPageState
    extends ConsumerState<GrowthIslandVisualDebugPage> {
  static const _levels = [1, 5, 10, 15, 20];
  int _selectedLevel = 1;
  String _moodId = 'calm';
  DayPhase _dayPhase = resolveDayPhase();

  @override
  Widget build(BuildContext context) {
    final state = _buildWorldState(_selectedLevel, _moodId, _dayPhase);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GrowthWorldViewport(
            worldState: state,
            force2D: true,
            interactive: false,
            enginePaused: true,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _DebugToolbar(
                  selectedLevel: _selectedLevel,
                  levels: _levels,
                  moodId: _moodId,
                  dayPhase: _dayPhase,
                  worldState: state,
                  onLevelChanged: (level) =>
                      setState(() => _selectedLevel = level),
                  onMoodChanged: (mood) => setState(() => _moodId = mood),
                  onDayPhaseChanged: (phase) =>
                      setState(() => _dayPhase = phase),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  WorldState _buildWorldState(int level, String moodId, DayPhase dayPhase) {
    final style = const IslandStyleResolver().resolve(moodId: moodId);
    final built = ref.read(islandBuildServiceProvider).build(
          engine: ref.read(growthWorldEngineProvider),
          summary: _summaryForLevel(level, moodId),
          todayMood: moodId,
          moments: const [],
          islandStyle: style,
          companionStyle: 'cozy',
          companionGender: 'female',
          compact: false,
        );
    final lighting =
        DayPhaseLightingPreset.forPhase(dayPhase).blendWithAtmosphere(
      moodSkyTop: built.environment.skyTop,
      moodSkyBottom: built.environment.skyBottom,
      moodSunIntensity: built.environment.sunIntensity,
    );
    return WorldState(
      island: built.island,
      characters: built.characters,
      buildings: built.buildings,
      flora: built.flora,
      environment: built.environment.copyWith(
        dayPhase: dayPhase,
        skyTop: lighting.skyTop,
        skyBottom: lighting.skyBottom,
        sunIntensity: lighting.sunIntensity,
        sunX: lighting.sunX,
        sunY: lighting.sunY,
        shadowDx: lighting.shadowDx,
        shadowDy: lighting.shadowDy,
        shadowStretch: lighting.shadowStretch,
        shadowAlpha: lighting.shadowAlpha,
        lightWarmth: lighting.lightWarmth,
        ambientShadeStrength: lighting.ambientShadeStrength,
      ),
      zones: built.zones,
      decorations: built.decorations,
      paths: built.paths,
      effects: built.effects,
      anchors: built.anchors,
      companionGender: built.companionGender,
      schemaVersion: built.schemaVersion,
    );
  }

  GrowthSummary _summaryForLevel(int level, String moodId) {
    return GrowthSummary(
      growthValue: level * 100,
      level: level,
      levelTitle: 'Lv$level visual check',
      streakDays: level,
      maxStreakDays: level,
      nextLevel: level < 20 ? level + 1 : null,
      nextLevelTitle: level < 20 ? 'Lv${level + 1}' : null,
      xpIntoLevel: 0,
      xpForNextLevel: level < 20 ? 100 : null,
      islandStage: level,
      unlockLabel: 'Visual Lv$level',
      todayMood: moodId,
      todayWeatherLabel: GrowthSystem.moodWeatherLabel(moodId),
      isGuest: true,
    );
  }
}

class _DebugToolbar extends StatelessWidget {
  const _DebugToolbar({
    required this.selectedLevel,
    required this.levels,
    required this.moodId,
    required this.dayPhase,
    required this.worldState,
    required this.onLevelChanged,
    required this.onMoodChanged,
    required this.onDayPhaseChanged,
  });

  final int selectedLevel;
  final List<int> levels;
  final String moodId;
  final DayPhase dayPhase;
  final WorldState worldState;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<DayPhase> onDayPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Growth Island Visual Check',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final level in levels)
              ChoiceChip(
                label: Text('Lv$level'),
                selected: selectedLevel == level,
                onSelected: (_) => onLevelChanged(level),
              ),
            DropdownButton<String>(
              value: moodId,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'calm', child: Text('calm')),
                DropdownMenuItem(value: 'happy', child: Text('happy')),
                DropdownMenuItem(value: 'thinking', child: Text('thinking')),
                DropdownMenuItem(value: 'sad', child: Text('sad')),
              ],
              onChanged: (value) {
                if (value != null) onMoodChanged(value);
              },
            ),
            for (final phase in DayPhase.values)
              ChoiceChip(
                label: Text(phase.label),
                selected: dayPhase == phase,
                onSelected: (_) => onDayPhaseChanged(phase),
              ),
            Text(
              'R ${worldState.island.radius.toStringAsFixed(2)} / '
              'T${worldState.island.prosperityTier} / '
              '${worldState.environment.dayPhase.label} / '
              'B${worldState.buildings.length} / '
              'D${DecorConfigs.unlockedAt(worldState.characters.isEmpty ? 1 : worldState.characters.first.level).length} / '
              'P${worldState.paths.length} / '
              'A${worldState.anchors.length}',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.62),
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
