import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../design_system/home_theme.dart';
import '../../island/story_island_progress.dart';
import '../providers/home_island_slots_provider.dart';
import '../../../world/preview/story_island_building_icon.dart';

/// 首页「我的世界」副岛轻量卡片（无 Flame）。
class WorldPreviewStoryCard extends StatelessWidget {
  const WorldPreviewStoryCard({
    super.key,
    required this.slot,
    required this.onTap,
  });

  final HomeIslandSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final island = slot.island;
    if (island == null) return const SizedBox.shrink();

    final asset = StoryIslandBuildingIcon.previewAsset(
      categoryId: island.categoryId,
      island: island,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final iconCacheW = (52 * dpr).round().clamp(48, 128);

    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                  cacheWidth: iconCacheW,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.landscape_outlined,
                    color: HomeTheme.primary.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${storyIslandLevelLabel(island)} · ${island.storyCount}条',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: HomeTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 副岛卡片横向列表。
class WorldPreviewStoryCardStrip extends StatelessWidget {
  const WorldPreviewStoryCardStrip({
    super.key,
    required this.slots,
    required this.onSlotTap,
  });

  final List<HomeIslandSlot> slots;
  final void Function(HomeIslandSlot slot) onSlotTap;

  @override
  Widget build(BuildContext context) {
    final storySlots =
        slots.where((s) => s.isStorySlot && s.island != null).toList();
    if (storySlots.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        itemCount: storySlots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slot = storySlots[index];
          return WorldPreviewStoryCard(
            slot: slot,
            onTap: () => onSlotTap(slot),
          );
        },
      ),
    );
  }
}
