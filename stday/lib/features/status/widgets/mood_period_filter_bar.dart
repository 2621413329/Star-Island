import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_period.dart';
import '../../../design_system/pressable_feedback.dart';

/// 成长轨迹页：今天 / 本周 / 本月 / 本年度快捷筛选。
class MoodPeriodFilterBar extends StatelessWidget {
  const MoodPeriodFilterBar({
    super.key,
    required this.palette,
    required this.selected,
    required this.onSelected,
  });

  final MoodPalette palette;
  final MoodStatusPeriod selected;
  final ValueChanged<MoodStatusPeriod> onSelected;

  static const _periods = MoodStatusPeriod.values;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          for (var i = 0; i < _periods.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _MoodPeriodChip(
              period: _periods[i],
              selected: selected == _periods[i],
              palette: palette,
              onTap: () => onSelected(_periods[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodPeriodChip extends StatelessWidget {
  const _MoodPeriodChip({
    required this.period,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final MoodStatusPeriod period;
  final bool selected;
  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableFeedback(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? palette.accent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? palette.accent
                : palette.accent.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          period.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? palette.accent : const Color(0xFF5C4A3A),
          ),
        ),
      ),
    );
  }
}
