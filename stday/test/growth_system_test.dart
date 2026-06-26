import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';

void main() {
  group('GrowthSystem 20-level curve', () {
    test('level cumulative thresholds match design', () {
      expect(GrowthSystem.levelCumulativeXp, [
        0, 91, 199, 313, 433, 556, 681, 810, 941, 1073,
        1208, 1344, 1482, 1621, 1761, 1903, 2045, 2189, 2334, 2480, 2700,
      ]);
      expect(GrowthSystem.levelXpRequirements.length, 20);
      expect(GrowthSystem.levelXpRequirements.fold<int>(0, (a, b) => a + b), 2480);
    });

    test('resolveLevel at key milestones', () {
      expect(GrowthSystem.resolveLevel(0), 1);
      expect(GrowthSystem.resolveLevel(90), 1);
      expect(GrowthSystem.resolveLevel(91), 2);
      expect(GrowthSystem.resolveLevel(433), 5);
      expect(GrowthSystem.resolveLevel(1073), 10);
      expect(GrowthSystem.resolveLevel(1344), 12);
      expect(GrowthSystem.resolveLevel(1761), 15);
      expect(GrowthSystem.resolveLevel(2480), 20);
      expect(GrowthSystem.resolveLevel(999999), 20);
    });

    test('level titles cover Lv1-Lv20', () {
      expect(GrowthSystem.levelTitle(1), '初心者');
      expect(GrowthSystem.levelTitle(12), '创造者');
      expect(GrowthSystem.levelTitle(20), '岛屿传说');
    });

    test('next level progress for Lv12 example', () {
      const growthValue = 1360;
      const level = 12;
      final progress = GrowthSystem.nextLevelProgress(growthValue, level);
      expect(progress.$1, 13);
      expect(progress.$2, '坚持者');
      expect(progress.$3, 16);
      expect(progress.$4, 138);

      final summary = GrowthSystem.enrich(
        GrowthSummary(
          growthValue: growthValue,
          level: level,
          levelTitle: '创造者',
          streakDays: 1,
          maxStreakDays: 1,
          xpIntoLevel: 16,
          xpForNextLevel: 138,
          islandStage: level,
          unlockLabel: '',
          todayWeatherLabel: '☀ 平静',
          isGuest: false,
        ),
      );
      expect(summary.levelProgressPercent, 12);
      expect(summary.xpRemainingToNextLevel, 122);
      expect(
        GrowthSystem.nextLevelDistanceLabel(summary),
        '距离 Lv.13 坚持者\n还需 122 成长值',
      );
    });

    test('max level has full progress and no next level', () {
      final summary = GrowthSystem.enrich(
        GrowthSummary(
          growthValue: 2700,
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
