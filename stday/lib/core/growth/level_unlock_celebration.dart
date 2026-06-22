import 'growth_system.dart';
import 'island_unlock_catalog.dart';

/// 收集 (fromLevel, currentLevel] 区间内新解锁的内容。
List<IslandUnlockItem> collectNewUnlockItems({
  required int fromLevel,
  required int toLevel,
}) {
  if (toLevel <= fromLevel) return const [];
  final items = <IslandUnlockItem>[];
  for (var level = fromLevel + 1; level <= toLevel; level++) {
    items.addAll(IslandUnlockCatalog.itemsAtLevel(level));
  }
  return items;
}

String levelUnlockCelebrationSubline(GrowthSummary summary) {
  final items = IslandUnlockCatalog.itemsAtLevel(summary.level);
  if (items.isEmpty) {
    return '小岛正在悄悄长大';
  }
  if (items.length == 1) {
    return '解锁 ${items.first.name}';
  }
  return '解锁 ${items.map((item) => item.name).join('、')}';
}

String levelUnlockRangeSummary({
  required int fromLevel,
  required int toLevel,
}) {
  final items = collectNewUnlockItems(fromLevel: fromLevel, toLevel: toLevel);
  if (items.isEmpty) return '小岛正在悄悄长大';
  if (items.length <= 3) {
    return '解锁 ${items.map((item) => item.name).join('、')}';
  }
  return '解锁 ${items.take(3).map((item) => item.name).join('、')} 等 ${items.length} 项';
}
