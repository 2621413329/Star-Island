import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/growth/growth_system.dart';
import '../../../data/models/story_island_models.dart';
import '../../../island/providers/growth_summary_provider.dart';
import '../../../providers/app_providers.dart';
import '../../../world/preview/world_island_layout.dart';

class HomeIslandSlot {
  const HomeIslandSlot({
    required this.slotId,
    required this.displayName,
    required this.level,
    this.island,
    this.categoryId,
    this.hasStories = false,
    this.isOpened = false,
  });

  final String slotId;
  final String displayName;
  final int level;
  final StoryIslandModel? island;
  final String? categoryId;
  final bool hasStories;

  /// 副岛已开启（成长值 > 0 或有记录）；主岛恒为 true。
  final bool isOpened;

  bool get isMain => slotId == WorldIslandLayout.mainSlotId;
  bool get isStorySlot => !isMain;

  @override
  bool operator ==(Object other) {
    if (other is! HomeIslandSlot) return false;
    return slotId == other.slotId &&
        displayName == other.displayName &&
        level == other.level &&
        categoryId == other.categoryId &&
        hasStories == other.hasStories &&
        isOpened == other.isOpened &&
        _sameStoryIsland(island, other.island);
  }

  @override
  int get hashCode => Object.hash(
        slotId,
        displayName,
        level,
        categoryId,
        hasStories,
        isOpened,
        island?.id,
        island?.currentLevel,
        island?.growthValue,
        island?.storyCount,
      );
}

bool _sameStoryIsland(StoryIslandModel? a, StoryIslandModel? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return a.id == b.id &&
      a.categoryId == b.categoryId &&
      a.name == b.name &&
      a.currentLevel == b.currentLevel &&
      a.growthValue == b.growthValue &&
      a.storyCount == b.storyCount &&
      a.sizeKind == b.sizeKind;
}

/// 按等级降序取前 [limit] 个事件岛。
List<StoryIslandModel> topStoryIslandsByLevel(
  List<StoryIslandCategoryModel> groups, {
  int limit = 5,
}) {
  final all = <StoryIslandModel>[];
  for (final group in groups) {
    all.addAll(group.islands);
  }
  all.sort((a, b) {
    final byLevel = b.currentLevel.compareTo(a.currentLevel);
    if (byLevel != 0) return byLevel;
    final byGrowth = b.growthValue.compareTo(a.growthValue);
    if (byGrowth != 0) return byGrowth;
    return a.name.compareTo(b.name);
  });
  if (all.length <= limit) return all;
  return all.sublist(0, limit);
}

final homeIslandSlotsProvider = Provider<List<HomeIslandSlot>>((ref) {
  final groups = ref.watch(storyIslandGroupsProvider).valueOrNull ?? const [];
  final summary =
      ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();
  final moments = ref.watch(todayMomentsProvider).valueOrNull ?? const [];

  final topIslands = topStoryIslandsByLevel(groups);

  final slots = <HomeIslandSlot>[
    HomeIslandSlot(
      slotId: WorldIslandLayout.mainSlotId,
      displayName: '主岛',
      level: summary.level,
      hasStories: moments.isNotEmpty,
      isOpened: true,
    ),
  ];

  for (var i = 0; i < WorldIslandLayout.storyRankSlotIds.length; i++) {
    final slotId = WorldIslandLayout.storyRankSlotIds[i];
    if (i >= topIslands.length) continue;

    final island = topIslands[i];
    final hasStories = moments.any(
      (m) =>
          m.storyIslandId == island.id ||
          m.visualPayload['story_island_id'] == island.id,
    );

    slots.add(
      HomeIslandSlot(
        slotId: slotId,
        displayName: island.name,
        level: island.currentLevel,
        island: island,
        categoryId: island.categoryId,
        hasStories: hasStories,
        isOpened: island.isOpened,
      ),
    );
  }

  return slots;
});

/// 单个槽位。其他槽位变化但本槽外观不变时，不通知这座岛。
final homeIslandSlotByIdProvider = Provider.family<HomeIslandSlot?, String>((
  ref,
  slotId,
) {
  final slots = ref.watch(homeIslandSlotsProvider);
  for (final slot in slots) {
    if (slot.slotId == slotId) return slot;
  }
  return null;
});

/// 背景只关心有哪些槽位，不关心等级和成长值。
final homeIslandActiveSlotIdsProvider = Provider<Set<String>>((ref) {
  final slots = ref.watch(homeIslandSlotsProvider);
  return {for (final slot in slots) slot.slotId};
});

final homeWorldHasStoryIslandProvider = Provider<bool>((ref) {
  final slots = ref.watch(homeIslandSlotsProvider);
  return slots.any((slot) => slot.isStorySlot && slot.island != null);
});
