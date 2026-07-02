import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../design_system/home_theme.dart';
import '../providers/home_island_slots_provider.dart';
import 'world_preview.dart';

class WorldSection extends StatelessWidget {
  const WorldSection({
    super.key,
    required this.enginePaused,
    required this.onIslandSlotTap,
    this.onMainIslandTap,
    this.onAllIslandsTap,
  });

  final bool enginePaused;
  final void Function(HomeIslandSlot slot) onIslandSlotTap;
  final VoidCallback? onMainIslandTap;
  final VoidCallback? onAllIslandsTap;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final previewHeight = (screenH * 0.56).clamp(380.0, 520.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的世界',
                style: appTextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '记录故事 · 建设人生岛屿',
                style: appTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: HomeTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: previewHeight,
          width: double.infinity,
          child: WorldPreview(
            enginePaused: enginePaused,
            onIslandSlotTap: onIslandSlotTap,
            onMainIslandTap: onMainIslandTap,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 2),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAllIslandsTap,
              style: TextButton.styleFrom(
                foregroundColor: HomeTheme.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '全部岛屿 >',
                style: appTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
