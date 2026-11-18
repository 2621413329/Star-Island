import 'package:flutter/widgets.dart';

import '../../data/models/story_island_models.dart';
import '../../island/providers/island_preview_body.dart';
import '../../world/engine/world_state.dart';
import '../../world/island/island_body_image_cache.dart';
import '../../world/island/island_visual_config.dart';
import '../../world/preview/story_island_building_icon.dart';
import '../../world/preview/world_island_layout.dart';
import 'providers/home_island_slots_provider.dart';
import 'widgets/world_preview.dart';
import 'widgets/world_preview_backdrop.dart';

/// 在进入「我的岛屿」之前，按真实槽位尺寸把岛体位图准备好。
void prewarmHomeIslandBodies({
  required IslandPreviewStyle style,
  required int prosperity,
  required List<HomeIslandSlot> slots,
  required Size screen,
  required double devicePixelRatio,
  BuildContext? context,
}) {
  if (screen.width < 1 || screen.height < 1 || devicePixelRatio <= 0) return;
  final canvas = WorldPreview.canvasForScreen(screen);
  final slotById = {for (final slot in slots) slot.slotId: slot};
  _precacheSky(context, canvas, devicePixelRatio);

  _request(
    style: style,
    size: WorldPreview.mainIslandViewportSize(canvas),
    prosperityTier: IslandVisualConfig.homePreviewProsperityTier,
    radius: IslandVisualConfig.previewDisplayRadius,
    devicePixelRatio: devicePixelRatio,
  );

  for (final layout in WorldIslandLayout.sortedByDepth()) {
    if (layout.slotId == WorldIslandLayout.mainSlotId) continue;
    final slot = slotById[layout.slotId];
    final island = slot?.island;
    if (slot == null || island == null) continue;
    _precacheBuilding(context, island, devicePixelRatio, canvas, layout);
    _request(
      style: style,
      size: WorldPreview.subIslandViewportSize(
        canvas,
        layout,
        categoryId: slot.categoryId,
      ),
      prosperityTier: prosperity,
      radius: IslandVisualConfig.homeStoryPreviewRadius,
      devicePixelRatio: devicePixelRatio,
    );
  }
}

void _request({
  required IslandPreviewStyle style,
  required Size size,
  required int prosperityTier,
  required double radius,
  required double devicePixelRatio,
}) {
  if (size.width < 1 || size.height < 1) return;
  IslandBodyImageCache.request(
    IslandBodyImageRequest(
      island: IslandState(
        shapeKey: style.shapeKey,
        style: style.style,
        elevation: style.elevation,
        prosperityTier: prosperityTier,
        radius: radius,
      ),
      environment: style.environment,
      logicalSize: size,
      devicePixelRatio: devicePixelRatio,
    ),
    (_) {},
  );
}

void _precacheSky(BuildContext? context, Size canvas, double devicePixelRatio) {
  if (context == null || !context.mounted) return;
  final cacheWidth = (canvas.width * devicePixelRatio).round().clamp(360, 1280);
  precacheImage(
    ResizeImage.resizeIfNeeded(
      cacheWidth,
      null,
      const AssetImage(WorldPreviewBackdrop.healingSkyAsset),
    ),
    context,
  );
}

void _precacheBuilding(
  BuildContext? context,
  StoryIslandModel island,
  double devicePixelRatio,
  Size canvas,
  WorldIslandSlotLayout layout,
) {
  if (context == null || !context.mounted) return;
  final viewport = WorldPreview.subIslandViewportSize(
    canvas,
    layout,
    categoryId: island.categoryId,
  );
  final cacheWidth =
      (viewport.width * devicePixelRatio).round().clamp(64, 512);
  precacheImage(
    ResizeImage.resizeIfNeeded(
      cacheWidth,
      null,
      AssetImage(
        StoryIslandBuildingIcon.worldMapPreviewAsset(
          categoryId: island.categoryId,
          island: island,
        ),
      ),
    ),
    context,
  );
}
