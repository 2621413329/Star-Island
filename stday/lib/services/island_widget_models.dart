import '../data/models/story_island_models.dart';
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
          .map((e) => IslandWidgetTaskItem.fromJson(Map<String, dynamic>.from(e)))
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
      buildingThumbPath:
          resetBuildingThumbPath ? null : buildingThumbPath ?? this.buildingThumbPath,
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
}) {
  final tasks = island.todayTasks
      .where((task) => task.islandId == island.id)
      .toList();
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
  final previewLevel = isMain
      ? 0
      : StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(island);

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
  );
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
