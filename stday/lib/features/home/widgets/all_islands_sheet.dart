import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../data/models/story_island_models.dart';
import '../../../design_system/home_theme.dart';

Future<void> showAllIslandsSheet(
  BuildContext context, {
  required List<StoryIslandCategoryModel> groups,
  required ValueChanged<StoryIslandModel> onIslandSelected,
  Future<void> Function(StoryIslandCategoryModel category)? onCreateIsland,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HomeTheme.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HomeTheme.textSecondary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '全部岛屿',
                  style: appTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HomeTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '按主题整理你的日常小岛，点击卡片可快速进入。',
                  style: appTextStyle(
                    fontSize: 12,
                    color: HomeTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final group in groups)
                        _IslandCategoryCard(
                          group: group,
                          onIslandSelected: (island) {
                            Navigator.of(context).pop();
                            onIslandSelected(island);
                          },
                          onCreate: onCreateIsland == null
                              ? null
                              : () async {
                                  Navigator.of(context).pop();
                                  await onCreateIsland(group);
                                },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _IslandCategoryCard extends StatelessWidget {
  const _IslandCategoryCard({
    required this.group,
    required this.onIslandSelected,
    this.onCreate,
  });

  final StoryIslandCategoryModel group;
  final ValueChanged<StoryIslandModel> onIslandSelected;
  final Future<void> Function()? onCreate;

  @override
  Widget build(BuildContext context) {
    final activeIslands =
        group.islands.where((island) => !island.isArchived).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HomeTheme.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HomeTheme.primary.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.label,
                      style: appTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: HomeTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${activeIslands.length} 个岛屿',
                      style: appTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.primary,
                      ),
                    ),
                  ),
                  if (onCreate != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onCreate,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: HomeTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded, size: 19),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (activeIslands.isEmpty)
                _EmptyCategoryHint(label: group.label, onCreate: onCreate)
              else
                for (final island in activeIslands)
                  _IslandListCard(
                    island: island,
                    onTap: () => onIslandSelected(island),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IslandListCard extends StatelessWidget {
  const _IslandListCard({
    required this.island,
    required this.onTap,
  });

  final StoryIslandModel island;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HomeTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.${island.currentLevel}',
                    style: appTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: HomeTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        island.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${island.storyCount} 条记录 · ${island.activeDays} 天活跃',
                        style: appTextStyle(
                          fontSize: 11,
                          color: HomeTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: HomeTheme.textSecondary.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCategoryHint extends StatelessWidget {
  const _EmptyCategoryHint({
    required this.label,
    this.onCreate,
  });

  final String label;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: HomeTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onCreate,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: HomeTheme.primary.withValues(alpha: 0.85),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '还没有$label岛屿',
                        style: appTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                      if (onCreate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '点击创建你的第一座$label岛',
                          style: appTextStyle(
                            fontSize: 12,
                            color: HomeTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onCreate != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: HomeTheme.textSecondary.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
