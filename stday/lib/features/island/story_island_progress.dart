import '../../data/models/story_island_models.dart';

class StoryIslandLevelProgress {
  const StoryIslandLevelProgress({
    required this.progressToNext,
    required this.percentToNext,
    required this.currentBuildingName,
    required this.nextBuildingName,
    required this.remainToNext,
    required this.nextLevel,
    required this.isMaxLevel,
  });

  final double progressToNext;
  final int percentToNext;
  final String? currentBuildingName;
  final String? nextBuildingName;
  final int remainToNext;
  final int? nextLevel;
  final bool isMaxLevel;
}

StoryIslandLevelProgress storyIslandLevelProgress(StoryIslandModel island) {
  final plan = island.progressionPlan;
  if (plan.isEmpty) {
    return const StoryIslandLevelProgress(
      progressToNext: 0,
      percentToNext: 0,
      currentBuildingName: null,
      nextBuildingName: null,
      remainToNext: 0,
      nextLevel: null,
      isMaxLevel: true,
    );
  }

  final growth = island.growthValue;
  final currentLevel = island.currentLevel;
  final currentBuilding = currentLevel > 0 && currentLevel <= plan.length
      ? plan[currentLevel - 1].buildingType
      : null;

  StoryIslandProgressLevelModel? nextLocked;
  for (final level in plan) {
    if (!level.unlocked) {
      nextLocked = level;
      break;
    }
  }

  if (nextLocked == null) {
    return StoryIslandLevelProgress(
      progressToNext: 1,
      percentToNext: 100,
      currentBuildingName: currentBuilding ?? plan.last.buildingType,
      nextBuildingName: null,
      remainToNext: 0,
      nextLevel: null,
      isMaxLevel: true,
    );
  }

  final prevThreshold =
      currentLevel <= 0 ? 0 : plan[(currentLevel - 1).clamp(0, plan.length - 1)].thresholdDay;
  final nextThreshold = nextLocked.thresholdDay;
  final span = (nextThreshold - prevThreshold).clamp(1, 999999);
  final progress = ((growth - prevThreshold) / span).clamp(0.0, 1.0);

  return StoryIslandLevelProgress(
    progressToNext: progress,
    percentToNext: (progress * 100).round(),
    currentBuildingName: currentBuilding,
    nextBuildingName: nextLocked.buildingType,
    remainToNext: (nextThreshold - growth).clamp(0, 999999),
    nextLevel: nextLocked.level,
    isMaxLevel: false,
  );
}

String storyIslandNextLevelHint(StoryIslandLevelProgress progress) {
  if (progress.isMaxLevel) {
    return '全部 10 阶段建筑已解锁';
  }
  final nextBuilding = progress.nextBuildingName ?? '下一建筑';
  return '距离 Lv.${progress.nextLevel} $nextBuilding 还需 ${progress.remainToNext} 成长值';
}

String storyIslandLevelLabel(StoryIslandModel island) {
  final progress = storyIslandLevelProgress(island);
  final building = progress.currentBuildingName;
  if (island.currentLevel <= 0) {
    return 'Lv.0';
  }
  if (building == null || building.isEmpty) {
    return 'Lv.${island.currentLevel}';
  }
  return 'Lv.${island.currentLevel} $building';
}
