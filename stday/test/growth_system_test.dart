import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';

void main() {
  group('GrowthSystem 20-level curve', () {
    test('level cumulative thresholds match design', () {
      expect(GrowthSystem.levelCumulativeXp, [
        0, 100, 250, 450, 700, 1100, 1600, 2300, 3200, 4500,
        6200, 8500, 11500, 15500, 20500, 24500, 29000, 32000, 34000, 36000,
      ]);
      expect(GrowthSystem.levelXpRequirements.length, 19);
      expect(GrowthSystem.levelXpRequirements.fold<int>(0, (a, b) => a + b), 36000);
    });

    test('resolveLevel at key milestones', () {
      expect(GrowthSystem.resolveLevel(0), 1);
      expect(GrowthSystem.resolveLevel(99), 1);
      expect(GrowthSystem.resolveLevel(100), 2);
      expect(GrowthSystem.resolveLevel(700), 5);
      expect(GrowthSystem.resolveLevel(4500), 10);
      expect(GrowthSystem.resolveLevel(8500), 12);
      expect(GrowthSystem.resolveLevel(20500), 15);
      expect(GrowthSystem.resolveLevel(36000), 20);
      expect(GrowthSystem.resolveLevel(999999), 20);
    });

    test('level titles cover Lv1-Lv20', () {
      expect(GrowthSystem.levelTitle(1), '初心者');
      expect(GrowthSystem.levelTitle(12), '创造者');
      expect(GrowthSystem.levelTitle(20), '岛屿传说');
    });

    test('next level progress for Lv12 example', () {
      const growthValue = 8521;
      const level = 12;
      final progress = GrowthSystem.nextLevelProgress(growthValue, level);
      expect(progress.$1, 13);
      expect(progress.$2, '坚持者');
      expect(progress.$3, 21);
      expect(progress.$4, 3000);

      final summary = GrowthSystem.enrich(
        GrowthSummary(
          growthValue: growthValue,
          level: level,
          levelTitle: '创造者',
          streakDays: 1,
          maxStreakDays: 1,
          xpIntoLevel: 21,
          xpForNextLevel: 3000,
          islandStage: level,
          unlockLabel: '',
          todayWeatherLabel: '☀ 平静',
          isGuest: false,
        ),
      );
      expect(summary.levelProgressPercent, 1);
      expect(summary.xpRemainingToNextLevel, 2979);
      expect(
        GrowthSystem.nextLevelDistanceLabel(summary),
        '距离 Lv.13 坚持者\n还需 2979 成长值',
      );
    });

    test('max level has full progress and no next level', () {
      final summary = GrowthSystem.enrich(
        GrowthSummary(
          growthValue: 36000,
          level: 20,
          levelTitle: '岛屿传说',
          streakDays: 10,
          maxStreakDays: 10,
          xpIntoLevel: 0,
          xpForNextLevel: null,
          islandStage: 20,
          unlockLabel: '',
          todayWeatherLabel: '☀ 平静',
          isGuest: false,
        ),
      );
      expect(summary.nextLevel, isNull);
      expect(summary.levelProgressRatio, 1);
    });
  });
}
