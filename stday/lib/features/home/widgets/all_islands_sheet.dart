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
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final group in groups) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.label,
                                  style: appTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: HomeTheme.textSecondary,
                                  ),
                                ),
                              ),
                              if (onCreateIsland != null)
                                TextButton.icon(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await onCreateIsland(group);
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('创建岛屿'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeTheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (group.islands.isEmpty)
                          _EmptyCategoryHint(
                            label: group.label,
                            onCreate: onCreateIsland == null
                                ? null
                                : () async {
                                    Navigator.of(context).pop();
                                    await onCreateIsland(group);
                                  },
                          )
                        else
                          for (final island in group.islands)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(island.name),
                              subtitle: Text('Lv.${island.currentLevel}'),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.of(context).pop();
                                onIslandSelected(island);
                              },
                            ),
                      ],
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
                        '还没有${label}岛屿',
                        style: appTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                      if (onCreate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '点击创建你的第一座${label}岛',
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
