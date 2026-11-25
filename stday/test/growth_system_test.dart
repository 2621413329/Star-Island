import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/data/models/profile_models.dart';
import 'package:stday/island/config/growth_island_configs.dart';

DailyMomentModel _moment({
  required DateTime momentDate,
  required DateTime createdAt,
  required String note,
}) {
  return DailyMomentModel(
    id: 'm-${momentDate.toIso8601String()}',
    eventTags: const ['学习'],
    emotionTag: 'calm',
    note: note,
    companionScene: 'idle',
    companionPose: 'breathing',
    momentDate: momentDate,
    createdAt: createdAt,
  );
}

void main() {
  group('GrowthSystem 20-level curve', () {
    test('level cumulative thresholds match design', () {
      expect(GrowthSystem.levelCumulativeXp, [
        0,
        70,
        150,
        244,
        356,
        490,
        650,
        840,
        1064,
        1326,
        1630,
        1980,
        2380,
        2834,
        3346,
        3920,
        4560,
        5270,
        6054,
        6916,
      ]);
      expect(GrowthSystem.levelXpRequirements.length, 19);
      expect(
          GrowthSystem.levelXpRequirements.fold<int>(0, (a, b) => a + b), 6916);
      for (var level = 1; level < GrowthSystem.maxLevel; level++) {
        final gap = 70 + 8 * (level - 1) + 2 * (level - 1) * (level - 1);
        expect(GrowthSystem.levelXpRequirements[level - 1], gap);
        if (level > 1) {
          expect(
            GrowthSystem.levelXpRequirements[level - 1],
            greaterThan(GrowthSystem.levelXpRequirements[level - 2]),
          );
        }
      }
    });

    test('island unlock scores follow the same curve', () {
      expect(
        GrowthIslandConfigs.levels
            .map((level) => level.requiredGrowthScore)
            .toList(),
        GrowthSystem.levelCumulativeXp,
      );
    });

    test('resolveLevel at key milestones', () {
      expect(GrowthSystem.resolveLevel(0), 1);
      expect(GrowthSystem.resolveLevel(69), 1);
      expect(GrowthSystem.resolveLevel(70), 2);
      expect(GrowthSystem.resolveLevel(356), 5);
      expect(GrowthSystem.resolveLevel(1326), 10);
      expect(GrowthSystem.resolveLevel(1980), 12);
      expect(GrowthSystem.resolveLevel(3346), 15);
      expect(GrowthSystem.resolveLevel(6916), 20);
      expect(GrowthSystem.resolveLevel(999999), 20);
    });

    test('level titles cover Lv1-Lv20', () {
      expect(GrowthSystem.levelTitle(1), '初心者');
      expect(GrowthSystem.levelTitle(12), '创造者');
      expect(GrowthSystem.levelTitle(20), '岛屿传说');
    });

    test('next level progress for Lv12 example', () {
      const growthValue = 2180;
      const level = 12;
      final progress = GrowthSystem.nextLevelProgress(growthValue, level);
      expect(progress.$1, 13);
      expect(progress.$2, '坚持者');
      expect(progress.$3, 200);
      expect(progress.$4, 400);

      final summary = GrowthSystem.enrich(
        const GrowthSummary(
          growthValue: growthValue,
          level: level,
          levelTitle: '创造者',
          streakDays: 1,
          maxStreakDays: 1,
          xpIntoLevel: 200,
          xpForNextLevel: 400,
          islandStage: level,
          unlockLabel: '',
          todayWeatherLabel: '☀ 平静',
          isGuest: false,
        ),
      );
      expect(summary.level, 12);
      expect(summary.levelProgressPercent, 50);
      expect(summary.xpRemainingToNextLevel, 200);
      expect(
        GrowthSystem.nextLevelDistanceLabel(summary),
        '距离 Lv.13 坚持者\n还需 200 经验值',
      );
    });

    test('backfilled diary does not increase growth', () {
      final today = DateTime(2026, 6, 12);
      final yesterday = DateTime(2026, 6, 11);
      const note = '今天发生了让我开心的事情';
      final todayMoment = _moment(
        momentDate: today,
        createdAt: DateTime(2026, 6, 12, 12),
        note: note,
      );
      final backfill = _moment(
        momentDate: yesterday,
        createdAt: DateTime(2026, 6, 12, 12),
        note: '补上昨天没写完的一段日常记录',
      );
      final before = GrowthSystem.compute(moments: [todayMoment]);
      final after = GrowthSystem.compute(moments: [todayMoment, backfill]);
      expect(after.growthValue, before.growthValue);
      expect(after.streakDays, before.streakDays);
    });

    test('diary written on its own day still counts', () {
      final summary = GrowthSystem.compute(
        moments: [
          _moment(
            momentDate: DateTime(2026, 6, 11),
            createdAt: DateTime(2026, 6, 11, 12),
            note: '当天写下的一段值得记住的日常',
          ),
        ],
      );
      expect(summary.growthValue, greaterThan(0));
    });

    test('max level has full progress and no next level', () {
      final summary = GrowthSystem.enrich(
        const GrowthSummary(
          growthValue: 6916,
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
