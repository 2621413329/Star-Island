import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';

/// 成长轨迹等列表底部分页，风格与岛屿玻璃卡片一致。
class IslandPaginationBar extends StatelessWidget {
  const IslandPaginationBar({
    super.key,
    required this.palette,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.onPageSelected,
  });

  final MoodPalette palette;
  final int page;
  final int totalPages;
  final int totalItems;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavButton(
            palette: palette,
            icon: Icons.chevron_left_rounded,
            enabled: page > 1,
            onTap: () => onPageSelected(page - 1),
          ),
          Expanded(
            child: Text(
              '第 $page / $totalPages 页 · 共 $totalItems 条',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.primary.withValues(alpha: 0.78),
              ),
            ),
          ),
          _NavButton(
            palette: palette,
            icon: Icons.chevron_right_rounded,
            enabled: page < totalPages,
            onTap: () => onPageSelected(page + 1),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.palette,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final MoodPalette palette;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? palette.accent
        : palette.primary.withValues(alpha: 0.28);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}
