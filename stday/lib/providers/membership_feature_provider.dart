import '../core/utils/moment_date_groups.dart';
import '../data/models/profile_models.dart';
import '../data/models/story_island_models.dart';

/// 非 VIP 仅可对当日首个日常（按创建时间最早）使用小人对话。
bool isFirstMomentOfDay(
  DailyMomentModel moment,
  List<DailyMomentModel> pool,
) {
  final day = momentCalendarDate(moment);
  final sameDay =
      pool.where((m) => momentCalendarDate(m) == day).toList(growable: false);
  if (sameDay.isEmpty) return true;
  sameDay.sort((a, b) {
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  });
  return sameDay.first.id == moment.id;
}

bool canUseFreeCompanionDialogue({
  required DailyMomentModel moment,
  required List<DailyMomentModel> recentMoments,
}) {
  return isFirstMomentOfDay(moment, recentMoments);
}

/// 非 VIP 用户最多创建的副岛数量。
const nonVipStoryIslandLimit = 3;

int countActiveStoryIslands(List<StoryIslandCategoryModel> groups) {
  var total = 0;
  for (final group in groups) {
    for (final island in group.islands) {
      if (!island.isArchived) total++;
    }
  }
  return total;
}
