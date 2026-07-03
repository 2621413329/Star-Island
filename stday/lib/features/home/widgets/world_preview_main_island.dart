import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/growth/growth_system.dart';
import '../../../core/growth/today_mood_display.dart';
import '../../../island/providers/growth_summary_provider.dart';
import '../../../island/viewport/growth_world_viewport.dart';
import '../../../providers/app_providers.dart';
import '../../../world/preview/world_preview_camera.dart';
import '../../../world/preview/world_preview_performance.dart';

/// 中央主岛视口（38° 俯视）：Lv3 及以下装饰 + 角色，不展示建筑。
class WorldPreviewMainIsland extends ConsumerWidget {
  const WorldPreviewMainIsland({
    super.key,
    required this.width,
    required this.height,
    required this.enginePaused,
    required this.quality,
  });

  final double width;
  final double height;
  final bool enginePaused;
  final WorldPreviewQuality quality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final moodId = resolveTodayLandingMoodId(profile: profile);
    final summary =
        ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Transform(
          alignment: Alignment.center,
          transform: WorldPreviewCamera.islandTransform(),
          child: GrowthWorldViewport(
            summary: summary,
            moodId: moodId,
            compact: true,
            interactive: false,
            enginePaused: enginePaused,
            previewZoom:
                WorldPreviewPerformance.mainIslandPreviewZoom(quality) * 0.94,
            islandOnly: true,
            enableDecor:
                WorldPreviewPerformance.enableMainIslandDecor(quality),
            decorMaxUnlockLevel: 3,
            showBuildings: false,
            showCharacters: true,
            clipCompactPreview: true,
          ),
        ),
      ),
    );
  }
}
