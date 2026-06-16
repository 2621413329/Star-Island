import 'package:flutter/material.dart';

import '../../data/models/profile_models.dart';
import '../core/theme/mood_theme.dart';
import '../core/utils/moment_tags.dart';

/// 故事卡片上的 AI 标签：一级 + 二级 + 成长关键词。
class MomentTagChipRow extends StatelessWidget {
  const MomentTagChipRow({
    super.key,
    required this.moment,
    required this.palette,
    this.maxSecondary = 2,
    this.showGrowthPoints = true,
    this.compact = false,
  });

  final DailyMomentModel moment;
  final MoodPalette palette;
  final int maxSecondary;
  final bool showGrowthPoints;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = momentPrimaryCategory(moment);
    final secondary = momentSecondaryTags(moment).take(maxSecondary).toList();
    final growth = showGrowthPoints
        ? momentGrowthPoints(moment).take(2).toList()
        : const <String>[];

    if (primary == null && secondary.isEmpty && growth.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: compact ? 4 : 6,
      children: [
        if (primary != null)
          _TagChip(
            label: primary,
            color: palette.accent,
            compact: compact,
            emphasized: true,
          ),
        for (final tag in secondary)
          _TagChip(
            label: tag,
            color: palette.primary,
            compact: compact,
          ),
        for (final point in growth)
          _TagChip(
            label: point,
            color: palette.glow,
            compact: compact,
            outlined: true,
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
    this.compact = false,
    this.emphasized = false,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool compact;
  final bool emphasized;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: outlined
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: emphasized ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(
          color: color.withValues(alpha: emphasized ? 0.45 : 0.28),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          color: color.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
