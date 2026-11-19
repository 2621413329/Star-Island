import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_companion.dart';
import '../../../design_system/user_companion_view.dart';
import '../../../island/building/plaza_terrace_renderer.dart';
import '../../../island/config/growth_island_config_models.dart';
import '../../../island/config/growth_island_configs.dart';
import '../../../island/providers/island_preview_body.dart';
import '../../../providers/app_providers.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_body_image_cache.dart';
import '../../../world/island/island_visual_config.dart';
import '../../../world/island/painted_island_asset.dart';
import '../../../world/island/painted_island_pits.dart';
import 'main_island_decor_composite.dart';

/// 首页主岛纯 Canvas 静态预览（无 Flame），优先流畅。
class WorldPreviewMainIslandStatic extends ConsumerWidget {
  const WorldPreviewMainIslandStatic({
    super.key,
    required this.width,
    required this.height,
    this.growthLevel = 3,
    this.enginePaused = false,
  });

  final double width;
  final double height;
  final int growthLevel;
  final bool enginePaused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(islandPreviewStyleProvider);
    final characterOffset = ref.watch(islandPreviewCharacterOffsetProvider);
    final companion = ref.watch(userCompanionProvider);
    final previewIsland = IslandState(
      shapeKey: style.shapeKey,
      style: style.style,
      elevation: style.elevation,
      prosperityTier: IslandVisualConfig.homePreviewProsperityTier,
      radius: IslandVisualConfig.previewDisplayRadius,
    );
    final landmark = _highestLandmarkBuilding(growthLevel);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          IslandBodyView(
            island: previewIsland,
            environment: style.environment,
            width: width,
            height: height,
          ),
          MainIslandDecorComposite(
            viewportSize: Size(width, height),
            userLevel: growthLevel,
            clearCenter: landmark != null,
          ),
          if (landmark != null)
            _MainIslandPreviewLandmark(
              config: landmark,
              viewportSize: Size(width, height),
            ),
          if (characterOffset != null)
            _MainIslandPreviewCompanion(
              normalizedPos: characterOffset,
              viewportSize: Size(width, height),
              companion: companion,
              enginePaused: enginePaused,
            ),
        ],
      ),
    );
  }
}

/// 当前成长等级下最高解锁地标（学院优先于栈桥/广场/起点石）。
BuildingConfig? _highestLandmarkBuilding(int growthLevel) {
  BuildingConfig? best;
  for (final config in GrowthIslandConfigs.buildings) {
    if (config.unlockLevel > growthLevel) continue;
    if (PlazaTerraceRenderer.isPlazaBuilding(config.id)) continue;
    if (config.id == 'harbor_pier' || config.id == 'starter_stone') continue;
    if (best == null || config.unlockLevel > best.unlockLevel) {
      best = config;
    }
  }
  return best;
}

class _MainIslandPreviewLandmark extends StatelessWidget {
  const _MainIslandPreviewLandmark({
    required this.config,
    required this.viewportSize,
  });

  final BuildingConfig config;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    // compact 岛面可视宽度约 0.55～0.62 视口；建筑控制在岛面内，脚点落岛心。
    final typeScale = switch (config.type) {
      'academy' => 0.78,
      'lighthouse' || 'clocktower' || 'observatory' => 0.92,
      'house' || 'gallery' || 'library' => 0.88,
      _ => 0.85,
    };
    final plate = PaintedIslandAsset.layoutRect(viewportSize);
    final h = (plate.height * 0.28 * typeScale)
        .clamp(28.0, plate.height * 0.36)
        .toDouble();
    final w = (h * 0.86).clamp(24.0, plate.width * 0.28).toDouble();
    final pit =
        PaintedIslandPits.building(config.id) ?? const Offset(0.50, 0.52);
    final foot = PaintedIslandAsset.plateToCanvas(pit, viewportSize);
    final left = foot.dx - w / 2;
    final top = foot.dy - h;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (w * dpr).round().clamp(48, 256);
    final asset = 'assets/images/${config.sprite}';

    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        cacheWidth: cacheW,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _MainIslandPreviewCompanion extends StatelessWidget {
  const _MainIslandPreviewCompanion({
    required this.normalizedPos,
    required this.viewportSize,
    required this.companion,
    required this.enginePaused,
  });

  final Offset normalizedPos;
  final Size viewportSize;
  final UserCompanion companion;
  final bool enginePaused;

  @override
  Widget build(BuildContext context) {
    final size = (viewportSize.width * 0.20).clamp(38.0, 64.0).toDouble();
    final boxH = size * 1.15;
    final foot = PaintedIslandAsset.plateToCanvas(normalizedPos, viewportSize);
    final left = foot.dx - size / 2;
    final top = foot.dy - boxH * 0.82;

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: boxH,
      child: RepaintBoundary(
        child: TickerMode(
          enabled: !enginePaused,
          child: UserCompanionView(
            companion: companion,
            size: size,
            showAura: false,
            animateIdle: false,
          ),
        ),
      ),
    );
  }
}
