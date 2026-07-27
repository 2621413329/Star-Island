import '../data/models/story_island_models.dart';
import '../data/models/profile_models.dart';
import '../core/utils/moment_tags.dart';
import '../world/preview/story_island_building_icon.dart';

/// App Group / SharedPreferences 共享给桌面小组件的快照（当前岛屿上下文）。
class IslandWidgetPayload {
  const IslandWidgetPayload({
    required this.currentIslandId,
    required this.islandName,
    required this.islandStatus,
    required this.todayDate,
    required this.completed,
    required this.total,
    required this.todayTasks,
    this.islandIndex = 0,
    this.islandTotal = 1,
    this.orderedIslandIds = const [],
    this.isGrowthMain = false,
    this.displayLevel = 0,
    this.categoryId = '',
    this.buildingPreviewLevel = 0,
    this.buildingThumbPath,
    this.reviewTitle = '',
    this.reviewBody = '',
    this.focusLabel = '',
    this.todayMomentCount = 0,
  });

  final String currentIslandId;
  final String islandName;
  final String islandStatus;
  final String todayDate;
  final int completed;
  final int total;
  final List<IslandWidgetTaskItem> todayTasks;
  final int islandIndex;
  final int islandTotal;
  final List<String> orderedIslandIds;
  final bool isGrowthMain;
  final int displayLevel;
  final String categoryId;
  final int buildingPreviewLevel;
  final String? buildingThumbPath;
  final String reviewTitle;
  final String reviewBody;
  final String focusLabel;
  final int todayMomentCount;

  bool get canGoPrev => islandTotal > 1;
  bool get canGoNext => islandTotal > 1;
  bool get showBuildingThumb => !isGrowthMain && buildingPreviewLevel > 0;

  String get levelBadgeLabel => 'Lv.$displayLevel';

  Map<String, dynamic> toJson() => {
        'currentIslandId': currentIslandId,
        'islandName': islandName,
        'islandStatus': islandStatus,
        'todayDate': todayDate,
        'completed': completed,
        'total': total,
        'todayTasks': todayTasks.map((t) => t.toJson()).toList(),
        'islandIndex': islandIndex,
        'islandTotal': islandTotal,
        'orderedIslandIds': orderedIslandIds,
        'isGrowthMain': isGrowthMain,
        'displayLevel': displayLevel,
        'categoryId': categoryId,
        'buildingPreviewLevel': buildingPreviewLevel,
        if (buildingThumbPath != null) 'buildingThumbPath': buildingThumbPath,
        'reviewTitle': reviewTitle,
        'reviewBody': reviewBody,
        'focusLabel': focusLabel,
        'todayMomentCount': todayMomentCount,
      };

  factory IslandWidgetPayload.fromJson(Map<String, dynamic> json) {
    return IslandWidgetPayload(
      currentIslandId: '${json['currentIslandId']}',
      islandName: json['islandName'] as String? ?? '岛屿',
      islandStatus: json['islandStatus'] as String? ?? '平静',
      todayDate: json['todayDate'] as String? ?? '',
      completed: json['completed'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      todayTasks: (json['todayTasks'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) =>
              IslandWidgetTaskItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      islandIndex: json['islandIndex'] as int? ?? 0,
      islandTotal: json['islandTotal'] as int? ?? 1,
      orderedIslandIds: (json['orderedIslandIds'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
      isGrowthMain: json['isGrowthMain'] as bool? ?? false,
      displayLevel: json['displayLevel'] as int? ?? 0,
      categoryId: json['categoryId'] as String? ?? '',
      buildingPreviewLevel: json['buildingPreviewLevel'] as int? ?? 0,
      buildingThumbPath: json['buildingThumbPath'] as String?,
      reviewTitle: json['reviewTitle'] as String? ?? '',
      reviewBody: json['reviewBody'] as String? ?? '',
      focusLabel: json['focusLabel'] as String? ?? '',
      todayMomentCount: json['todayMomentCount'] as int? ?? 0,
    );
  }

  IslandWidgetPayload copyWith({
    String? buildingThumbPath,
    bool resetBuildingThumbPath = false,
  }) {
    return IslandWidgetPayload(
      currentIslandId: currentIslandId,
      islandName: islandName,
      islandStatus: islandStatus,
      todayDate: todayDate,
      completed: completed,
      total: total,
      todayTasks: todayTasks,
      islandIndex: islandIndex,
      islandTotal: islandTotal,
      orderedIslandIds: orderedIslandIds,
      isGrowthMain: isGrowthMain,
      displayLevel: displayLevel,
      categoryId: categoryId,
      buildingPreviewLevel: buildingPreviewLevel,
      buildingThumbPath: resetBuildingThumbPath
          ? null
          : buildingThumbPath ?? this.buildingThumbPath,
      reviewTitle: reviewTitle,
      reviewBody: reviewBody,
      focusLabel: focusLabel,
      todayMomentCount: todayMomentCount,
    );
  }
}

class IslandWidgetTaskItem {
  const IslandWidgetTaskItem({
    required this.id,
    required this.islandId,
    required this.title,
    required this.date,
    required this.status,
  });

  final String id;
  final String islandId;
  final String title;
  final String date;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'islandId': islandId,
        'title': title,
        'date': date,
        'status': status,
      };

  factory IslandWidgetTaskItem.fromJson(Map<String, dynamic> json) {
    return IslandWidgetTaskItem(
      id: '${json['id']}',
      islandId: '${json['islandId']}',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'todo',
    );
  }
}

String islandWidgetStatusLabel(StoryIslandModel island) {
  if (island.growthTarget > 0 &&
      island.growthValue / island.growthTarget >= 0.72) {
    return '成长中';
  }
  final tasks = island.todayTasks;
  if (tasks.isEmpty) return '平静';
  final done = tasks.where((t) => t.completedToday).length;
  if (done == 0) return '平静';
  if (done >= tasks.length) return '活跃';
  return '活跃';
}

IslandWidgetPayload buildIslandWidgetPayload({
  required StoryIslandModel island,
  required String todayDate,
  int islandIndex = 0,
  int islandTotal = 1,
  List<String> orderedIslandIds = const [],
  int? mainIslandUserLevel,
  List<DailyMomentModel> todayMoments = const [],
  List<DailyMomentModel> recentMoments = const [],
  List<StoryIslandCategoryModel> groups = const [],
}) {
  final tasks =
      island.todayTasks.where((task) => task.islandId == island.id).toList();
  final completed = tasks.where((t) => t.completedToday).length;
  final visibleTasks = tasks.take(3).map((task) {
    return IslandWidgetTaskItem(
      id: task.id,
      islandId: island.id,
      title: task.title,
      date: todayDate,
      status: task.completedToday ? 'done' : 'todo',
    );
  }).toList();

  final isMain = island.isGrowthMainIsland;
  final displayLevel = isMain
      ? (mainIslandUserLevel ?? island.currentLevel).clamp(0, 999)
      : island.currentLevel;
  final previewLevel =
      isMain ? 0 : StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(island);
  final review = _buildIslandWidgetReview(
    island: island,
    todayMoments: todayMoments,
    recentMoments: recentMoments,
    groups: groups,
  );

  return IslandWidgetPayload(
    currentIslandId: island.id,
    islandName: island.name,
    islandStatus: islandWidgetStatusLabel(island),
    todayDate: todayDate,
    completed: completed,
    total: tasks.length,
    todayTasks: visibleTasks,
    islandIndex: islandIndex,
    islandTotal: islandTotal,
    orderedIslandIds: orderedIslandIds,
    isGrowthMain: isMain,
    displayLevel: displayLevel,
    categoryId: island.categoryId,
    buildingPreviewLevel: previewLevel,
    reviewTitle: review.title,
    reviewBody: review.body,
    focusLabel: review.focusLabel,
    todayMomentCount: review.todayCount,
  );
}

class _IslandWidgetReview {
  const _IslandWidgetReview({
    required this.title,
    required this.body,
    required this.focusLabel,
    required this.todayCount,
  });

  final String title;
  final String body;
  final String focusLabel;
  final int todayCount;
}

_IslandWidgetReview _buildIslandWidgetReview({
  required StoryIslandModel island,
  required List<DailyMomentModel> todayMoments,
  required List<DailyMomentModel> recentMoments,
  required List<StoryIslandCategoryModel> groups,
}) {
  final todayForIsland = island.isGrowthMainIsland
      ? todayMoments
      : todayMoments
          .where((moment) => _momentBelongsToIsland(moment, island))
          .toList(growable: false);
  final focusLabel = _focusLabelForIsland(island, todayMoments, groups);
  if (todayForIsland.isNotEmpty) {
    final tags = _topTagLabels(todayForIsland).take(2).toList();
    final mood = momentMoodDisplayLabel(todayForIsland.last);
    final tagText = tags.isEmpty ? '今天的经历' : '「${tags.join('、')}」';
    return _IslandWidgetReview(
      title: island.isGrowthMainIsland ? '星屿今日回顾' : '${island.name}今日回顾',
      body:
          '今天记录了 ${todayForIsland.length} 篇，主要围绕$tagText，感受偏向$mood。小岛正在把这些片段整理成成长轨迹。',
      focusLabel: focusLabel,
      todayCount: todayForIsland.length,
    );
  }

  // 跨日后即使还有「最近日常」，小组件也必须显示「今日」空态，避免昨日内容残留。
  return _IslandWidgetReview(
    title: island.isGrowthMainIsland ? '今日还没有记录' : '${island.name}等待新记录',
    body: '写下今天的一件小事，小岛会把它放进合适的成长方向，并生成你的日常回顾。',
    focusLabel: focusLabel,
    todayCount: 0,
  );
}

bool _momentBelongsToIsland(DailyMomentModel moment, StoryIslandModel island) {
  if (moment.storyIslandId == island.id) return true;
  return moment.visualPayload['story_island_id'] == island.id;
}

List<String> _topTagLabels(List<DailyMomentModel> moments) {
  final counts = <String, int>{};
  for (final moment in moments) {
    final primary = momentPrimaryCategory(moment);
    if (primary == null || primary.trim().isEmpty) continue;
    counts[primary] = (counts[primary] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((entry) => entry.key).toList();
}

String _focusLabelForIsland(
  StoryIslandModel island,
  List<DailyMomentModel> todayMoments,
  List<StoryIslandCategoryModel> groups,
) {
  if (!island.isGrowthMainIsland) {
    final todayCount = todayMoments
        .where((moment) => _momentBelongsToIsland(moment, island))
        .length;
    final countText =
        todayCount > 0 ? '今日 $todayCount 条' : '${island.storyCount} 条记录';
    final levelText = !island.isOpened
        ? '待开启'
        : island.currentLevel <= 0
            ? 'Lv.0'
            : 'Lv.${island.currentLevel}';
    return '${island.name} · $countText · $levelText';
  }

  final counts = <String, int>{};
  for (final moment in todayMoments) {
    final islandId = moment.storyIslandId ??
        moment.visualPayload['story_island_id'] as String?;
    if (islandId == null || islandId.isEmpty) continue;
    counts[islandId] = (counts[islandId] ?? 0) + 1;
  }
  if (counts.isNotEmpty) {
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final target = _findStoryIslandById(groups, top.first.key);
    if (target != null) {
      return '当前关注：${target.name} · 今日 ${top.first.value} 条';
    }
  }
  return '主岛总览 · 所有日常都会汇入这里';
}

StoryIslandModel? _findStoryIslandById(
  List<StoryIslandCategoryModel> groups,
  String islandId,
) {
  for (final group in groups) {
    for (final island in group.islands) {
      if (island.id == islandId) return island;
    }
  }
  return null;
}

String _clipText(String value, int maxChars) {
  final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.length <= maxChars) return trimmed;
  return '${trimmed.substring(0, maxChars)}…';
}

/// 小组件 / 首页轮播顺序：主岛优先，其余按等级降序。
List<StoryIslandModel> orderedWidgetIslands({
  required StoryIslandModel? growthMainIsland,
  required List<StoryIslandCategoryModel> groups,
}) {
  final result = <StoryIslandModel>[];
  if (growthMainIsland != null) {
    result.add(growthMainIsland);
  }
  final stories = <StoryIslandModel>[];
  for (final group in groups) {
    stories.addAll(group.islands);
  }
  stories.sort((a, b) {
    final byLevel = b.currentLevel.compareTo(a.currentLevel);
    if (byLevel != 0) return byLevel;
    return a.name.compareTo(b.name);
  });
  for (final island in stories) {
    if (growthMainIsland != null && island.id == growthMainIsland.id) {
      continue;
    }
    result.add(island);
  }
  return result;
}

String islandWidgetTodayDateIso(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

const islandWidgetCatalogKey = 'island_widget_catalog';
