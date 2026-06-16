class GrowthTagModel {
  const GrowthTagModel({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String categoryId;
  final String label;
  final int sortOrder;
  final bool isActive;

  factory GrowthTagModel.fromJson(Map<String, dynamic> json) {
    return GrowthTagModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      label: json['label'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class GrowthTagCategoryModel {
  const GrowthTagCategoryModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.isActive,
    required this.tags,
  });

  final String id;
  final String label;
  final String icon;
  final String color;
  final int sortOrder;
  final bool isActive;
  final List<GrowthTagModel> tags;

  factory GrowthTagCategoryModel.fromJson(Map<String, dynamic> json) {
    return GrowthTagCategoryModel(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String? ?? 'label',
      color: json['color'] as String? ?? '#78909C',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => GrowthTagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
