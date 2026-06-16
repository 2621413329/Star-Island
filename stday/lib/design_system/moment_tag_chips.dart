import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import '../core/theme/mood_theme.dart';
import '../core/utils/moment_tags.dart';
import '../core/utils/tag_stats.dart';
import '../providers/growth_tag_provider.dart';

/// 故事卡片上的标签：一级 + 二级（仅展示标签库内维护项）。
class MomentTagChipRow extends ConsumerWidget {
  const MomentTagChipRow({
    super.key,
    required this.moment,
    required this.palette,
    this.maxSecondary = 2,
    this.showGrowthPoints = false,
    this.compact = false,
  });

  final DailyMomentModel moment;
  final MoodPalette palette;
  final int maxSecondary;
  final bool showGrowthPoints;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(growthTagCatalogProvider).valueOrNull ?? const [];
    final primary = catalog.isEmpty
        ? momentPrimaryCategory(moment)
        : momentCatalogPrimaryTag(moment, catalog);
    final secondary = catalog.isEmpty
        ? momentSecondaryTags(moment).take(maxSecondary).toList()
        : momentCatalogSecondaryTags(moment, catalog)
            .take(maxSecondary)
            .toList();
    final growth = showGrowthPoints && catalog.isNotEmpty
        ? momentGrowthPoints(moment)
            .where((point) => isKnownSecondaryTag(point, catalog))
            .take(2)
            .toList()
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
