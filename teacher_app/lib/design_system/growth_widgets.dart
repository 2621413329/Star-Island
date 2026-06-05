import 'package:flutter/material.dart';

import '../core/constants/growth_labels.dart';
import '../core/theme/mood_theme.dart';
import '../data/models/growth_observation.dart';

class GrowthStatusChip extends StatelessWidget {
  const GrowthStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = growthStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        growthStatusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class FocusTagChips extends StatelessWidget {
  const FocusTagChips({super.key, required this.tags, required this.palette, this.label});

  final List<String> tags;
  final MoodPalette palette;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: palette.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
              ),
              child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class TrendIndicator extends StatelessWidget {
  const TrendIndicator({super.key, required this.trend});

  final String trend;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (trend) {
      case 'up':
        icon = Icons.trending_up_rounded;
        color = const Color(0xFF7CB342);
        break;
      case 'down':
        icon = Icons.trending_down_rounded;
        color = const Color(0xFFFF9800);
        break;
      default:
        icon = Icons.trending_flat_rounded;
        color = const Color(0xFF8C7B6B);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(trendLabel(trend), style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class RiskReminderStrip extends StatelessWidget {
  const RiskReminderStrip({super.key, required this.message, required this.palette});

  final String message;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded, color: Color(0xFFE65100), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }
}
