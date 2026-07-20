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
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的世界',
                style: appTextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2F5F8A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '记录故事 · 建设人生岛屿',
                style: appTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6A90B0),
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
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFD8EEFF).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.eco_rounded, size: 18, color: Color(0xFF5FAE72)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '每一个小小的记录，都是你人生岛屿的生长力量。',
                  style: appTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3F6F96),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 2),
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
