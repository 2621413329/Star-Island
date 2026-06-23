import 'package:flutter/material.dart';

import '../../core/growth/growth_system.dart';
import '../../core/theme/app_fonts.dart';

class LandingGrowthHeader extends StatelessWidget {
  const LandingGrowthHeader({super.key, required this.summary});

  final GrowthSummary summary;

  @override
  Widget build(BuildContext context) {
    final streakLabel = summary.isGuest
        ? '🔥 — 天'
        : '🔥 ${summary.streakDays} 天';
    final levelLabel = summary.isGuest
        ? '—'
        : GrowthSystem.levelTitleOnly(summary);
    final xpLabel = summary.isGuest ? '✦ —' : '✦ ${summary.growthValue}';

    return Row(
      children: [
        Expanded(child: _Metric(label: streakLabel)),
        const SizedBox(width: 4),
        Expanded(child: _Metric(label: levelLabel, align: TextAlign.center)),
        const SizedBox(width: 4),
        Expanded(child: _Metric(label: xpLabel, align: TextAlign.end)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, this.align = TextAlign.start});

  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      textAlign: align,
      style: appTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF5D4E44),
      ),
    );
  }
}
