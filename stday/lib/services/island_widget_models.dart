import '../data/models/story_island_models.dart';

/// App Group 共享给 iOS Widget 的快照，仅包含当前岛屿上下文。
class IslandWidgetPayload {
  const IslandWidgetPayload({
    required this.currentIslandId,
    required this.islandName,
    required this.islandStatus,
    required this.todayDate,
    required this.completed,
    required this.total,
    required this.todayTasks,
  });

  final String currentIslandId;
  final String islandName;
  final String islandStatus;
  final String todayDate;
  final int completed;
  final int total;
  final List<IslandWidgetTaskItem> todayTasks;

  Map<String, dynamic> toJson() => {
        'currentIslandId': currentIslandId,
        'islandName': islandName,
        'islandStatus': islandStatus,
        'todayDate': todayDate,
        'completed': completed,
        'total': total,
        'todayTasks': todayTasks.map((t) => t.toJson()).toList(),
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

  return IslandWidgetPayload(
    currentIslandId: island.id,
    islandName: island.name,
    islandStatus: islandWidgetStatusLabel(island),
    todayDate: todayDate,
    completed: completed,
    total: tasks.length,
    todayTasks: visibleTasks,
  );
}

String islandWidgetTodayDateIso(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
