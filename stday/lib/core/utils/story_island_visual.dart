import 'package:flutter/material.dart';

import '../../data/models/profile_models.dart';
import '../../data/models/story_island_models.dart';
import 'moment_tags.dart';

/// 日常是否归属指定故事岛。
bool momentBelongsToStoryIsland(DailyMomentModel moment, String islandId) {
  final id = moment.storyIslandId ??
      moment.visualPayload['story_island_id'] as String?;
  return id == islandId;
}

/// 根据日常归属解析故事岛分类元数据。
StoryIslandCategoryModel? storyIslandCategoryForMoment(
  DailyMomentModel moment, {
  Iterable<StoryIslandCategoryModel> groups = const [],
}) {
  final islandId = moment.storyIslandId ??
      moment.visualPayload['story_island_id'] as String?;
  String? categoryId;

  if (islandId != null) {
    for (final group in groups) {
      for (final island in group.islands) {
        if (island.id == islandId) {
          categoryId = island.categoryId;
          break;
        }
      }
      if (categoryId != null) break;
    }
  }

  categoryId ??= moment.visualPayload['story_island_category_id'] as String?;

  if (categoryId == null) return null;
  for (final group in groups) {
    if (group.id == categoryId) return group;
  }
  return null;
}

IconData storyIslandCategoryIcon(String categoryId, {String? fallbackIcon}) {
  return switch (categoryId) {
    'work' => Icons.work_outline_rounded,
    'study' => Icons.menu_book_outlined,
    'health' => Icons.fitness_center_outlined,
    'social' => Icons.groups_outlined,
    'life' => Icons.home_outlined,
    'finance' || 'wealth' => Icons.account_balance_wallet_outlined,
    'milestone' => Icons.emoji_events_outlined,
    'emotion' => Icons.sentiment_satisfied_alt_outlined,
    'creation' => Icons.palette_outlined,
    'achievement' => Icons.celebration_outlined,
    _ => fallbackIcon == null
        ? Icons.landscape_outlined
        : growthTagIcon(fallbackIcon),
  };
}

Color storyIslandCategoryColor(
  StoryIslandCategoryModel? category, {
  Color fallback = const Color(0xFF5EA9FF),
}) {
  if (category == null) return fallback;
  return parseHexColor(category.color, fallback: fallback);
}
