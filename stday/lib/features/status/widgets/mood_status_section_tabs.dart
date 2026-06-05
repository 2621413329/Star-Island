import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';

/// 心情状态页底部区块 Tab 定义（新增 Tab 时在此追加 [all]）。
class MoodStatusSectionTabDef {
  const MoodStatusSectionTabDef({
    required this.id,
    required this.label,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
}

abstract final class MoodStatusSectionTabs {
  static const overview = MoodStatusSectionTabDef(
    id: 'overview',
    label: '心情概览',
    icon: Icons.auto_stories_outlined,
  );

  static const stats = MoodStatusSectionTabDef(
    id: 'stats',
    label: '心情统计',
    icon: Icons.insights_outlined,
  );

  static const List<MoodStatusSectionTabDef> all = [overview, stats];

  static int indexOf(String id) {
    final i = all.indexWhere((t) => t.id == id);
    return i < 0 ? 0 : i;
  }
}

/// 可横向扩展的分段 Tab 栏，选中项带 Island 主题高亮。
class MoodStatusSectionTabBar extends StatelessWidget {
  const MoodStatusSectionTabBar({
    super.key,
    required this.palette,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final MoodPalette palette;
  final List<MoodStatusSectionTabDef> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = index == selectedIndex;
          return _SectionTabPill(
            palette: palette,
            label: tab.label,
            icon: tab.icon,
            selected: selected,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _SectionTabPill extends StatelessWidget {
  const _SectionTabPill({
    required this.palette,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  final MoodPalette palette;
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? palette.primaryContainer
                : palette.card.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? palette.accent
                  : palette.primary.withValues(alpha: 0.12),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? palette.accent : const Color(0xFF8C7B6B),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? palette.accent : const Color(0xFF6B5E54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
