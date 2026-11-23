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
    final previewHeight =
        WorldPreview.previewHeightFor(MediaQuery.sizeOf(context).height);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2A7EAFD4),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: SizedBox(
            height: previewHeight,
            width: double.infinity,
            child: WorldPreview(
              enginePaused: enginePaused,
              onIslandSlotTap: onIslandSlotTap,
              onMainIslandTap: onMainIslandTap,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '点一座岛，回去看看',
                style: appTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5E7C96),
                ),
              ),
            ),
            TextButton(
              onPressed: onAllIslandsTap,
              style: TextButton.styleFrom(
                foregroundColor: HomeTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '全部岛屿',
                style: appTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
