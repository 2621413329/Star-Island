class StoryIslandModel {
  const StoryIslandModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.sortOrder = 0,
    this.targetCompletionDays = 90,
    this.completionTargetDate,
    this.sizeKind = 'small',
    this.growthValue = 0,
    this.growthTarget = 1000,
    this.coverImageKey,
    this.backgroundConfig = const {},
    this.storyCount = 0,
    this.dominantMood,
    this.activeDays = 0,
    this.currentLevel = 0,
    this.progressionPlan = const [],
    this.unlockedDecorIds = const [],
    this.todayTasks = const [],
    this.isArchived = false,
  });

  final String id;
  final String categoryId;
  final String name;
  final int sortOrder;
  final int targetCompletionDays;
  final DateTime? completionTargetDate;
  final String sizeKind;
  final int growthValue;
  final int growthTarget;
  final String? coverImageKey;
  final Map<String, dynamic> backgroundConfig;
  final int storyCount;
  final String? dominantMood;
  final int activeDays;
  final int currentLevel;
  final List<StoryIslandProgressLevelModel> progressionPlan;
  final List<String> unlockedDecorIds;
  final List<StoryIslandTaskModel> todayTasks;
  final bool isArchived;

  factory StoryIslandModel.fromJson(Map<String, dynamic> json) {
    return StoryIslandModel(
      id: '${json['id']}',
      categoryId: '${json['category_id']}',
      name: json['name'] as String? ?? '未命名岛屿',
      sortOrder: json['sort_order'] as int? ?? 0,
      targetCompletionDays: json['target_completion_days'] as int? ?? 90,
      completionTargetDate: _parseOptionalDate(json['completion_target_date']),
      sizeKind: json['size_kind'] as String? ?? 'small',
      growthValue: json['growth_value'] as int? ?? 0,
      growthTarget: json['growth_target'] as int? ?? 1000,
      coverImageKey: json['cover_image_key'] as String?,
      backgroundConfig:
          json['background_config'] as Map<String, dynamic>? ?? const {},
      storyCount: json['story_count'] as int? ?? 0,
      dominantMood: json['dominant_mood'] as String?,
      activeDays: json['active_days'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 0,
      progressionPlan: (json['progression_plan'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => StoryIslandProgressLevelModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      unlockedDecorIds:
          (json['unlocked_decor_ids'] as List<dynamic>? ?? const [])
              .map((e) => '$e')
              .toList(),
      todayTasks: (json['today_tasks'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => StoryIslandTaskModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  static DateTime? _parseOptionalDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse('$raw');
  }
}

class StoryIslandTaskModel {
  const StoryIslandTaskModel({
    required this.id,
    required this.islandId,
    required this.title,
    this.isDaily = false,
    this.sortOrder = 0,
    this.completedToday = false,
    this.completedOn,
    this.growthDelta = 5,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String islandId;
  final String title;
  final bool isDaily;
  final int sortOrder;
  final bool completedToday;
  final DateTime? completedOn;
  final int growthDelta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StoryIslandTaskModel.fromJson(Map<String, dynamic> json) {
    return StoryIslandTaskModel(
      id: '${json['id']}',
      islandId: '${json['island_id']}',
      title: json['title'] as String? ?? '',
      isDaily: json['is_daily'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      completedToday: json['completed_today'] as bool? ?? false,
      completedOn: StoryIslandModel._parseOptionalDate(json['completed_on']),
      growthDelta: json['growth_delta'] as int? ?? 5,
      createdAt: StoryIslandModel._parseOptionalDate(json['created_at']),
      updatedAt: StoryIslandModel._parseOptionalDate(json['updated_at']),
    );
  }
}

class StoryIslandProgressLevelModel {
  const StoryIslandProgressLevelModel({
    required this.level,
    required this.thresholdDay,
    required this.buildingType,
    required this.ring,
    this.placement,
    this.unlockedAt,
    this.visualDescription,
  });

  final int level;
  final int thresholdDay;
  final String buildingType;
  final String ring;
  final String? placement;
  final DateTime? unlockedAt;
  final String? visualDescription;

  bool get unlocked => unlockedAt != null;

  factory StoryIslandProgressLevelModel.fromJson(Map<String, dynamic> json) {
    return StoryIslandProgressLevelModel(
      level: json['level'] as int? ?? 0,
      thresholdDay: json['threshold_day'] as int? ?? 0,
      buildingType: json['building_type'] as String? ?? '成长建筑',
      ring: json['ring'] as String? ?? 'outer',
      placement: json['placement'] as String?,
      unlockedAt: json['unlocked_at'] == null
          ? null
          : DateTime.tryParse('${json['unlocked_at']}'),
      visualDescription: json['visual_description'] as String?,
    );
  }
}

class StoryIslandCategoryModel {
  const StoryIslandCategoryModel({
    required this.id,
    required this.label,
    this.icon = 'label',
    this.color = '#78909C',
    this.sortOrder = 0,
    this.islands = const [],
  });

  final String id;
  final String label;
  final String icon;
  final String color;
  final int sortOrder;
  final List<StoryIslandModel> islands;

  factory StoryIslandCategoryModel.fromJson(Map<String, dynamic> json) {
    return StoryIslandCategoryModel(
      id: '${json['id']}',
      label: json['label'] as String? ?? '${json['id']}',
      icon: json['icon'] as String? ?? 'label',
      color: json['color'] as String? ?? '#78909C',
      sortOrder: json['sort_order'] as int? ?? 0,
      islands: (json['islands'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => StoryIslandModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
