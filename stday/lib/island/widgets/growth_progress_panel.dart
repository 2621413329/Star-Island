import 'package:flutter/material.dart';

import '../../core/growth/growth_system.dart';
import '../../core/theme/app_fonts.dart';
import '../../features/landing/landing_growth_header.dart';
import '../../features/landing/landing_island_progress.dart';

/// 岛屿首页下方的成长进度区（合并 header + progress）。
class GrowthProgressPanel extends StatelessWidget {
  const GrowthProgressPanel({
    super.key,
    required this.summary,
    this.progressBarHeight = 6,
  });

  final GrowthSummary summary;
  final double progressBarHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LandingGrowthHeader(summary: summary),
          const SizedBox(height: 10),
          LandingIslandProgress(
            summary: summary,
            progressBarHeight: progressBarHeight,
          ),
        ],
      ),
    );
  }
}

/// 岛屿首页「记录今天」快捷入口。
class IslandRecordCTA extends StatelessWidget {
  const IslandRecordCTA({
    super.key,
    required this.onPressed,
    this.label = '记录今天的日常',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: const Color(0xFFE8A87C).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF5D4E44)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: appTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D4E44),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
