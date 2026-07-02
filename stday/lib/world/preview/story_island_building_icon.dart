import '../../../data/models/story_island_models.dart';

/// 故事岛预览图标：取当前分类已解锁的最高等级建筑，否则用该分类默认岛体。
abstract final class StoryIslandBuildingIcon {
  StoryIslandBuildingIcon._();

  /// 最高已解锁建筑资源；无解锁建筑时返回 null。
  static String? highestUnlockedAsset(StoryIslandModel? island) {
    if (island == null) return null;
    StoryIslandProgressLevelModel? best;
    for (final level in island.progressionPlan) {
      if (!level.unlocked) continue;
      if (best == null || level.level > best.level) {
        best = level;
      }
    }
    if (best == null) return null;
    final lv = best.level.clamp(1, 10);
    return 'assets/images/islands/${island.categoryId}/buildings/'
        'lv${lv.toString().padLeft(2, '0')}.png';
  }

  /// 分类默认岛体（lv01 建筑图代表该分类岛屿外观）。
  static String categoryDefaultAsset(String categoryId) =>
      'assets/images/islands/$categoryId/buildings/lv01.png';

  /// 世界地图分岛预览图：已解锁最高建筑，否则分类默认岛体。
  static String previewAsset({
    required String categoryId,
    StoryIslandModel? island,
  }) =>
      highestUnlockedAsset(island) ?? categoryDefaultAsset(categoryId);

  static bool hasUnlockedBuilding(StoryIslandModel? island) =>
      highestUnlockedAsset(island) != null;
}
