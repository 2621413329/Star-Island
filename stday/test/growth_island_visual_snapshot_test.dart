import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/models/character_mood.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/generator/island_generator.dart';
import 'package:stday/island/service/island_style_resolver.dart';
import 'package:stday/world/engine/growth_world_input.dart';
import 'package:stday/world/engine/world_state.dart';

void main() {
  test('Growth Island Lv1-Lv20 visual snapshots progress coherently', () {
    const levels = [1, 5, 10, 15, 20];
    final states = {
      for (final level in levels) level: _buildState(level),
    };

    for (final entry in states.entries) {
      final level = entry.key;
      final state = entry.value;
      // ignore: avoid_print
      print(
        'Lv$level '
        'radius=${state.island.radius.toStringAsFixed(2)} '
        'tier=${state.island.prosperityTier} '
        'zones=${state.zones.length} '
        'buildings=${state.buildings.length} '
        'decor=${DecorConfigs.unlockedAt(level).length} '
        'paths=${state.paths.length} '
        'anchors=${state.anchors.length}',
      );
    }

    expect(states[1]!.buildings.length, 0);
    expect(states[3]!.buildings.length, greaterThan(0));
    expect(states[5]!.buildings.length, greaterThan(states[3]!.buildings.length));
    expect(states[5]!.buildings.length, lessThan(states[10]!.buildings.length));
    expect(
        states[10]!.buildings.length, lessThan(states[15]!.buildings.length));
    expect(
        states[15]!.buildings.length, lessThan(states[20]!.buildings.length));

    expect(DecorConfigs.unlockedAt(1).length, 3);
    expect(DecorConfigs.unlockedAt(5).length, greaterThan(DecorConfigs.unlockedAt(1).length));
    expect(DecorConfigs.unlockedAt(20).length, DecorConfigs.all.length);
    expect(states[1]!.paths, isEmpty);
    expect(states[20]!.paths, isEmpty);
    expect(states[1]!.island.radius, lessThan(states[20]!.island.radius));

    for (final state in states.values) {
      expect(state.anchors.where((anchor) => anchor.cameraFocus), isNotEmpty);
      expect(
          state.buildings.every((building) => building.sprite != null), isTrue);
      expect(state.decorations, isEmpty);
    }
  });

  test('DecorConfigs covers LV1-LV20 unlock plan', () {
    expect(DecorConfigs.all.length, 32);
    for (var level = 1; level <= 20; level++) {
      final unlocked = DecorConfigs.unlockedAt(level);
      final atLevel = DecorConfigs.all.where((d) => d.unlockLevel == level);
      for (final decor in atLevel) {
        expect(unlocked.any((d) => d.id == decor.id), isTrue);
      }
    }
    expect(
      DecorConfigs.all.every((d) => d.image.endsWith('.png')),
      isTrue,
    );
  });
}

WorldState _buildState(int level) {
  const generator = IslandGenerator();
  final style = const IslandStyleResolver().resolve(moodId: 'calm');
  return generator.generate(
    GrowthWorldInput(
      mood: CharacterMood.calm,
      events: const [],
      islandStyle: style,
      summary: _summary(level),
      companionStyle: 'cozy',
      companionGender: 'female',
    ),
  );
}

GrowthSummary _summary(int level) {
  return GrowthSummary(
    growthValue: level * 100,
    level: level,
    levelTitle: 'Lv$level',
    streakDays: level,
    maxStreakDays: level,
    nextLevel: level < 20 ? level + 1 : null,
    nextLevelTitle: level < 20 ? 'Lv${level + 1}' : null,
    xpIntoLevel: 0,
    xpForNextLevel: level < 20 ? 100 : null,
    islandStage: level,
    unlockLabel: 'Visual Lv$level',
    todayMood: 'calm',
    todayWeatherLabel: GrowthSystem.moodWeatherLabel('calm'),
    isGuest: true,
  );
}
