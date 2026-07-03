import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/device_profile.dart';
import '../../../design_system/home_theme.dart';
import '../../../world/preview/world_island_layout.dart';
import '../../../world/preview/world_island_visual.dart';
import '../../../world/preview/world_preview_performance.dart';
import '../providers/home_island_slots_provider.dart';
import 'floating_island_label.dart';
import 'world_preview_backdrop.dart';
import 'world_preview_float.dart';
import 'world_preview_island_pedestal.dart';
import 'world_preview_main_island.dart';
import 'world_preview_story_island.dart';
import 'world_preview_story_island_static.dart';

/// 沉浸式群岛 World：背景与 Flame 岛屿分层，不可拖动。
class WorldPreview extends ConsumerWidget {
  const WorldPreview({
    super.key,
    required this.enginePaused,
    this.onIslandSlotTap,
    this.onMainIslandTap,
  });

  final bool enginePaused;
  final void Function(HomeIslandSlot slot)? onIslandSlotTap;
  final VoidCallback? onMainIslandTap;

  static const _labelBlockHeight = 10.0;
  static const _baselineSubWidthFactor = 0.40;
  static const _baselineSubHeightFactor = 0.40;

  /// compact 成长岛顶缘在视口内的归一化 Y（与 [IslandShapeProfile] 一致）。
  static double islandRimTopFactor({double islandRadius = 1.0}) {
    const cy = 0.54;
    const ryBase = 0.118 * 1.48 * 1.22;
    return (cy - ryBase * islandRadius).clamp(0.20, 0.38);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(homeIslandSlotsProvider);
    final hasAnyStory =
        slots.any((slot) => slot.isStorySlot && slot.island != null);
    final slotById = {for (final s in slots) s.slotId: s};
    final layouts = WorldIslandLayout.sortedByDepth();
    final quality = WorldPreviewPerformance.qualityFor(
      DeviceProfile.fromContext(context),
    );
    final activeSlotIds = slots.map((s) => s.slotId).toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return ClipRRect(
          borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              WorldPreviewPhaseTicker(
                quality: quality,
                paused: enginePaused,
                builder: (context, phase) {
                  return WorldPreviewBackdrop(
                    phase: phase,
                    size: size,
                    quality: quality,
                    activeSlotIds: activeSlotIds,
                  );
                },
              ),
              _MainIslandNode(
                size: size,
                slot: slotById[WorldIslandLayout.mainSlotId]!,
                quality: quality,
                enginePaused: enginePaused,
                onTap: onMainIslandTap,
              ),
              for (final layout in layouts)
                if (layout.slotId != WorldIslandLayout.mainSlotId)
                  _StoryIslandNode(
                    layout: layout,
                    slot: slotById[layout.slotId],
                    size: size,
                    quality: quality,
                    enginePaused: enginePaused,
                    onTap: onIslandSlotTap,
                  ),
              if (!hasAnyStory) const _EmptyWorldHint(),
            ],
          ),
        );
      },
    );
  }

  static Size mainIslandViewportSize(Size canvas) {
    final baseW = canvas.width * _baselineSubWidthFactor;
    final baseH = canvas.height * _baselineSubHeightFactor;
    return Size(
      baseW * WorldIslandVisualProfile.mainScale,
      baseH * WorldIslandVisualProfile.mainScale,
    );
  }

  static Size subIslandViewportSize(
    Size canvas,
    WorldIslandSlotLayout layout,
    String? categoryId,
  ) {
    final scale = layout.depthScale *
        WorldIslandVisualProfile.categoryScale(categoryId) *
        WorldIslandVisualProfile.homeMapSubScale;
    return Size(
      canvas.width * _baselineSubWidthFactor * scale,
      canvas.height * _baselineSubHeightFactor * scale,
    );
  }
}

class _MainIslandNode extends StatelessWidget {
  const _MainIslandNode({
    required this.size,
    required this.slot,
    required this.quality,
    required this.enginePaused,
    this.onTap,
  });

  final Size size;
  final HomeIslandSlot slot;
  final WorldPreviewQuality quality;
  final bool enginePaused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final layout = WorldIslandLayout.forSlot(WorldIslandLayout.mainSlotId);
    final center = worldSlotPixel(layout, size);
    final viewport = WorldPreview.mainIslandViewportSize(size);
    final w = viewport.width;
    final h = viewport.height;
    const labelW = 132.0;
    final rotation = WorldIslandVisualProfile.combinedRotation(
      layoutRotation: layout.rotationRadians,
      categoryId: null,
    );
    final floatEnabled =
        !enginePaused && WorldPreviewPerformance.animateIslandFloat(quality);
    final rimTop = WorldPreview.islandRimTopFactor();

    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: WorldPreviewFloat(
            amplitude: layout.floatAmplitude(isMain: true),
            enabled: floatEnabled,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                WorldPreviewIslandPedestal(
                  width: w,
                  rotationRadians: rotation,
                  child: WorldPreviewMainIsland(
                    width: w,
                    height: h,
                    enginePaused: enginePaused,
                    quality: quality,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: (h * rimTop - WorldPreview._labelBlockHeight - 1)
                      .clamp(0.0, h * 0.42),
                  child: Center(
                    child: SizedBox(
                      width: labelW,
                      child: FloatingIslandLabel(
                        name: slot.displayName,
                        level: slot.level,
                        highlighted: slot.hasStories,
                      ),
                    ),
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

class _StoryIslandNode extends StatelessWidget {
  const _StoryIslandNode({
    required this.layout,
    required this.slot,
    required this.size,
    required this.quality,
    required this.enginePaused,
    this.onTap,
  });

  final WorldIslandSlotLayout layout;
  final HomeIslandSlot? slot;
  final Size size;
  final WorldPreviewQuality quality;
  final bool enginePaused;
  final void Function(HomeIslandSlot slot)? onTap;

  @override
  Widget build(BuildContext context) {
    final island = slot?.island;
    if (island == null || slot == null) return const SizedBox.shrink();

    final activeSlot = slot!;
    final categoryId = activeSlot.categoryId;
    final center = worldSlotPixel(layout, size);
    final viewport =
        WorldPreview.subIslandViewportSize(size, layout, categoryId);
    final viewportW = viewport.width;
    final viewportH = viewport.height;
    const labelW = 96.0;
    final rotation = WorldIslandVisualProfile.combinedRotation(
      layoutRotation: layout.rotationRadians,
      categoryId: categoryId,
    );
    final slotIndex = storySlotFlameIndex(layout.slotId);
    final useFlame = worldPreviewUseFlameForStorySlot(
      quality: quality,
      slotId: layout.slotId,
      slotIndexAmongActive: slotIndex,
    );
    final floatEnabled =
        !enginePaused && WorldPreviewPerformance.animateIslandFloat(quality);
    final rimTop = WorldPreview.islandRimTopFactor(islandRadius: 0.78);

    return Positioned(
      left: center.dx - viewportW / 2,
      top: center.dy - viewportH / 2,
      width: viewportW,
      height: viewportH,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(activeSlot),
          child: WorldPreviewFloat(
            amplitude: layout.floatAmplitude(categoryId: categoryId),
            phaseOffset: layout.slotId.hashCode % 100 / 100.0,
            enabled: floatEnabled,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                WorldPreviewIslandPedestal(
                  width: viewportW,
                  rotationRadians: rotation,
                  child: useFlame
                      ? WorldPreviewStoryIsland(
                          island: island,
                          width: viewportW,
                          height: viewportH,
                          enginePaused: enginePaused,
                          quality: quality,
                        )
                      : WorldPreviewStoryIslandStatic(
                          island: island,
                          width: viewportW,
                          height: viewportH,
                        ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: (viewportH * rimTop -
                          WorldPreview._labelBlockHeight -
                          1)
                      .clamp(0.0, viewportH * 0.42),
                  child: Center(
                    child: SizedBox(
                      width: labelW,
                      child: FloatingIslandLabel(
                        name: activeSlot.displayName,
                        level: activeSlot.level,
                        highlighted: activeSlot.hasStories,
                      ),
                    ),
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

class _EmptyWorldHint extends StatelessWidget {
  const _EmptyWorldHint();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '你的世界还在等第一个瞬间。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
