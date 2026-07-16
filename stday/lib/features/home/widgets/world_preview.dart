import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'world_preview_main_island_static.dart';
import 'world_preview_story_island_static.dart';

/// 沉浸式世界预览：海面 + 中心主岛 Flame + 四周副岛静态图（无底部卡片）。
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

  static double islandRimTopFactor({double islandRadius = 1.0}) {
    const cy = 0.54;
    const ryBase = 0.118 * 1.48 * 1.22;
    return (cy - ryBase * islandRadius).clamp(0.20, 0.38);
  }

  static Size mainIslandViewportSize(Size canvas, {int level = 1}) {
    final baseW = canvas.width * _baselineSubWidthFactor;
    final baseH = canvas.height * _baselineSubHeightFactor;
    // 我的世界主岛统一按 Lv3 视觉尺寸展示。
    const levelScale = 1.0;
    return Size(
      baseW * WorldIslandVisualProfile.mainScale * levelScale,
      baseH * WorldIslandVisualProfile.mainScale * levelScale,
    );
  }

  static Size subIslandViewportSize(
    Size canvas,
    WorldIslandSlotLayout layout, {
    String? categoryId,
  }) {
    final baseW = canvas.width * _baselineSubWidthFactor;
    final baseH = canvas.height * _baselineSubHeightFactor;
    final scale = layout.depthScale *
        WorldIslandVisualProfile.homeMapSubScale *
        WorldIslandVisualProfile.categoryScale(categoryId);
    return Size(baseW * scale, baseH * scale);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(homeIslandSlotsProvider);
    final slotById = {for (final slot in slots) slot.slotId: slot};
    final hasAnyStory =
        slots.any((slot) => slot.isStorySlot && slot.island != null);
    final mainSlot = slots.firstWhere(
      (s) => s.isMain,
      orElse: () => slots.first,
    );
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
                paused: enginePaused || quality == WorldPreviewQuality.low,
                builder: (context, phase) {
                  return WorldPreviewBackdrop(
                    phase: phase,
                    size: size,
                    quality: quality,
                    activeSlotIds: activeSlotIds,
                  );
                },
              ),
              for (final layout in WorldIslandLayout.sortedByDepth())
                if (layout.slotId != WorldIslandLayout.mainSlotId)
                  _SubIslandNode(
                    size: size,
                    layout: layout,
                    slot: slotById[layout.slotId],
                    quality: quality,
                    onTap: onIslandSlotTap,
                  ),
              _MainIslandNode(
                size: size,
                slot: mainSlot,
                quality: quality,
                enginePaused: enginePaused,
                onTap: onMainIslandTap,
              ),
              if (!hasAnyStory) const _EmptyWorldHint(),
            ],
          ),
        );
      },
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
    final viewport = WorldPreview.mainIslandViewportSize(
      size,
      level: slot.level,
    );
    final w = viewport.width;
    final h = viewport.height;
    const labelW = 132.0;
    final rotation = WorldIslandVisualProfile.combinedRotation(
      layoutRotation: layout.rotationRadians,
      categoryId: null,
    );
    final floatEnabled = false;
    final rimTop = WorldPreview.islandRimTopFactor();

    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h,
      child: RepaintBoundary(
        child: _MainIslandHitRegion(
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
                    child: WorldPreviewMainIslandStatic(
                      width: w,
                      height: h,
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
      ),
    );
  }
}

class _MainIslandHitRegion extends SingleChildRenderObjectWidget {
  const _MainIslandHitRegion({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMainIslandHitRegion();
  }
}

class _RenderMainIslandHitRegion extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_containsMainIsland(position)) return false;
    return super.hitTest(result, position: position);
  }

  bool _containsMainIsland(Offset position) {
    if (size.isEmpty) return false;
    final dx = (position.dx / size.width - 0.5) / 0.47;
    final dy = (position.dy / size.height - 0.55) / 0.28;
    return dx * dx + dy * dy <= 1;
  }
}

class _SubIslandNode extends StatelessWidget {
  const _SubIslandNode({
    required this.size,
    required this.layout,
    required this.slot,
    required this.quality,
    this.onTap,
  });

  final Size size;
  final WorldIslandSlotLayout layout;
  final HomeIslandSlot? slot;
  final WorldPreviewQuality quality;
  final void Function(HomeIslandSlot slot)? onTap;

  @override
  Widget build(BuildContext context) {
    final island = slot?.island;
    if (slot == null || island == null) return const SizedBox.shrink();

    final center = worldSlotPixel(layout, size);
    final viewport = WorldPreview.subIslandViewportSize(
      size,
      layout,
      categoryId: slot!.categoryId,
    );
    final w = viewport.width;
    final h = viewport.height;
    const labelW = 96.0;
    final rotation = WorldIslandVisualProfile.combinedRotation(
      layoutRotation: layout.rotationRadians,
      categoryId: slot!.categoryId,
    );
    final rimTop = WorldPreview.islandRimTopFactor(islandRadius: 0.78);

    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(slot!),
          child: maybeBlurDepth(
            blurSigma: layout.blurSigma,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: layout.opacity,
                  child: WorldPreviewIslandPedestal(
                    width: w,
                    rotationRadians: rotation,
                    child: WorldPreviewStoryIslandStatic(
                      island: island,
                      width: w,
                      height: h,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: (h * rimTop - WorldPreview._labelBlockHeight - 2)
                      .clamp(0.0, h * 0.38),
                  child: Center(
                    child: SizedBox(
                      width: labelW,
                      child: FloatingIslandLabel(
                        name: slot!.displayName,
                        level: slot!.level,
                        highlighted: slot!.hasStories,
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
