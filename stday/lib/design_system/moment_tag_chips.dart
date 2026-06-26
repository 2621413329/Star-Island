import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import '../core/theme/mood_theme.dart';
import '../core/utils/moment_tags.dart';
import '../core/utils/tag_stats.dart';
import '../providers/growth_tag_provider.dart';

/// 日常卡片上的标签：一级单独一行，二级标签换行展示。
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

    final category = findCategoryByLabel(catalog, primary);
    final primaryColor = category == null
        ? palette.accent
        : parseHexColor(category.color, fallback: palette.accent);
    final secondaryColor = category == null
        ? const Color(0xFF3D5266)
        : parseHexColor(category.color, fallback: const Color(0xFF3D5266));

    final secondaryLine = [
      for (final tag in secondary)
        MomentTagChip(
          label: tag,
          color: secondaryColor,
          compact: compact,
        ),
      for (final point in growth)
        MomentTagChip(
          label: point,
          color: palette.glow,
          compact: compact,
          outlined: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary != null)
          Wrap(
            spacing: compact ? 4 : 6,
            runSpacing: compact ? 4 : 6,
            children: [
              MomentTagChip(
                label: primary,
                color: primaryColor,
                compact: compact,
                emphasized: true,
              ),
            ],
          ),
        if (secondaryLine.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: primary != null ? (compact ? 4 : 6) : 0),
            child: Wrap(
              spacing: compact ? 4 : 6,
              runSpacing: compact ? 4 : 6,
              children: secondaryLine,
            ),
          ),
      ],
    );
  }
}

/// 可复用标签 chip，用于卡片展示与标签编辑页。
class MomentTagChip extends StatelessWidget {
  const MomentTagChip({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
    this.emphasized = false,
    this.outlined = false,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool compact;
  final bool emphasized;
  final bool outlined;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = emphasized || selected
        ? _darken(color)
        : const Color(0xFF3D5266);
    final borderColor = selected || emphasized
        ? color.withValues(alpha: 0.78)
        : color.withValues(alpha: 0.42);
    final fillColor = selected
        ? color.withValues(alpha: 0.24)
        : outlined
            ? color.withValues(alpha: 0.14)
            : emphasized
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.13);

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(
          color: borderColor,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: emphasized || selected ? FontWeight.w700 : FontWeight.w600,
          color: textColor,
        ),
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: chip,
      ),
    );
  }

  static Color _darken(Color color) {
    return Color.lerp(color, const Color(0xFF1A2332), 0.35) ?? color;
  }
}
