import '../../data/models/growth_tag_models.dart';
import '../../data/models/profile_models.dart';
import 'moment_tags.dart';

class TagStatItem {
  const TagStatItem({
    required this.label,
    required this.count,
    this.category,
  });

  final String label;
  final int count;
  final GrowthTagCategoryModel? category;
}

/// 一级标签是否在标签库中。
bool isKnownPrimaryTag(
  String label,
  List<GrowthTagCategoryModel> catalog,
) {
  return catalog.any((c) => c.isActive && c.label == label);
}

/// 二级标签是否属于指定一级（或任意一级）标签库。
bool isKnownSecondaryTag(
  String label,
  List<GrowthTagCategoryModel> catalog, {
  String? primaryLabel,
}) {
  if (primaryLabel != null) {
    final category = findCategoryByLabel(catalog, primaryLabel);
    if (category == null) return false;
    return category.tags.any((t) => t.isActive && t.label == label);
  }
  for (final category in catalog) {
    if (!category.isActive) continue;
    if (category.tags.any((t) => t.isActive && t.label == label)) {
      return true;
    }
  }
  return false;
}

/// 日常中已通过标签库校验的二级标签。
List<String> momentCatalogSecondaryTags(
  DailyMomentModel moment,
  List<GrowthTagCategoryModel> catalog,
) {
  final primary = momentPrimaryCategory(moment);
  return momentSecondaryTags(moment)
      .where(
        (tag) => isKnownSecondaryTag(
          tag,
          catalog,
          primaryLabel: primary,
        ),
      )
      .toList();
}

/// 日常中已通过标签库校验的一级标签。
String? momentCatalogPrimaryTag(
  DailyMomentModel moment,
  List<GrowthTagCategoryModel> catalog,
) {
  final primary = momentPrimaryCategory(moment);
  if (primary == null) return null;
  return isKnownPrimaryTag(primary, catalog) ? primary : null;
}

/// 统计一级标签触发次数（仅计标签库内标签）。
List<TagStatItem> primaryTagStatsForMoments(
  List<DailyMomentModel> moments,
  List<GrowthTagCategoryModel> catalog,
) {
  final tallies = <String, int>{};
  for (final moment in moments) {
    final primary = momentCatalogPrimaryTag(moment, catalog);
    if (primary == null) continue;
    tallies[primary] = (tallies[primary] ?? 0) + 1;
  }

  final items = catalog
      .where((c) => c.isActive)
      .map(
        (category) => TagStatItem(
          label: category.label,
          count: tallies[category.label] ?? 0,
          category: category,
        ),
      )
      .toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return (a.category?.sortOrder ?? 0).compareTo(b.category?.sortOrder ?? 0);
    });
  return items;
}

/// 统计某一级下的二级标签触发次数（仅计标签库内标签）。
List<TagStatItem> secondaryTagStatsForMoments(
  List<DailyMomentModel> moments,
  GrowthTagCategoryModel category,
  List<GrowthTagCategoryModel> catalog,
) {
  final tallies = <String, int>{};
  for (final moment in moments) {
    for (final tag in momentCatalogSecondaryTags(moment, catalog)) {
      if (!category.tags.any((t) => t.isActive && t.label == tag)) continue;
      tallies[tag] = (tallies[tag] ?? 0) + 1;
    }
  }

  final items = category.tags
      .where((t) => t.isActive)
      .map(
        (tag) => TagStatItem(
          label: tag.label,
          count: tallies[tag.label] ?? 0,
          category: category,
        ),
      )
      .toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.label.compareTo(b.label);
    });
  return items;
}

int tagStatsTotalTriggers(List<TagStatItem> items) {
  return items.fold<int>(0, (sum, item) => sum + item.count);
}

int tagStatsActiveKindCount(List<TagStatItem> items) {
  return items.where((item) => item.count > 0).length;
}
