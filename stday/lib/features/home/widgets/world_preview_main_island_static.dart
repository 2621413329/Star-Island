import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_companion.dart';
import '../../../design_system/user_companion_view.dart';
import '../../../island/building/plaza_terrace_renderer.dart';
import '../../../island/config/growth_island_config_models.dart';
import '../../../island/config/growth_island_configs.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../island/decor/decor_config.dart';
import '../../../island/decor/decor_scale_resolver.dart';
import '../../../providers/app_providers.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_renderer.dart';
import '../../../world/island/island_visual_config.dart';
import '../../../world/preview/world_preview_camera.dart';

/// 首页主岛纯 Canvas 静态预览（无 Flame），优先流畅。
class WorldPreviewMainIslandStatic extends ConsumerWidget {
  const WorldPreviewMainIslandStatic({
    super.key,
    required this.width,
    required this.height,
    this.growthLevel = 3,
  });

  final double width;
  final double height;
  final int growthLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(islandWorldPreviewProvider);
    final character = base.characters.isNotEmpty ? base.characters.first : null;
    final companion = ref.watch(userCompanionProvider);
    final visualLevel = _previewLevelFor(base);
    final previewIsland = _previewIslandFor(base.island, visualLevel);
    final landmark = _highestLandmarkBuilding(growthLevel);
    final decor = _previewDecorFor(base, clearCenter: landmark != null);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Transform(
          alignment: Alignment.center,
          transform: WorldPreviewCamera.islandTransform(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _MainIslandPreviewPainter(
                  island: previewIsland,
                  environment: base.environment,
                ),
              ),
              // 先铺周边装饰，再叠中心地标，避免建筑被树草盖住或反过来吞掉中心装饰。
              for (final item in decor)
                _MainIslandPreviewDecor(
                  config: item,
                  userLevel: visualLevel,
                  viewportSize: Size(width, height),
                ),
              if (landmark != null)
                _MainIslandPreviewLandmark(
                  config: landmark,
                  viewportSize: Size(width, height),
                ),
              if (character != null)
                _MainIslandPreviewCompanion(
                  character: character,
                  viewportSize: Size(width, height),
                  companion: companion,
                ),
            ],
          ),
        ),
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

/// 首页静态预览只用低档装饰，避免历史高等级树草全部绘制。
int _previewLevelFor(WorldState state) => 2;

IslandState _previewIslandFor(IslandState island, int visualLevel) {
  return IslandState(
    shapeKey: island.shapeKey,
    style: island.style,
    elevation: island.elevation,
    prosperityTier: _previewProsperityTierFor(visualLevel),
    radius: IslandVisualConfig.previewDisplayRadius,
  );
}

int _previewProsperityTierFor(int visualLevel) {
  return switch (visualLevel.clamp(1, 3)) {
    1 => 0,
    2 => 1,
    _ => 2,
  };
}

List<DecorConfig> _previewDecorFor(
  WorldState state, {
  bool clearCenter = false,
}) {
  final cappedLevel = _previewLevelFor(state);
  final all = DecorConfigs.unlockedMainIslandAt(cappedLevel)
      .where(DecorConfigs.isMainIslandGroundDecor)
      // 首页预览跳过树/灌木，减少重叠与绘制开销。
      .where((d) =>
          d.category != DecorCategory.tree &&
          d.category != DecorCategory.bush);
  if (!clearCenter) return all.toList(growable: false);
  // 给中心地标留出岛心空位，避免草树与建筑抢同一落点。
  return all.where((decor) {
    final dx = decor.x - 0.50;
    final dy = decor.y - 0.54;
    return dx * dx + dy * dy > 0.030;
  }).toList(growable: false);
}

class _MainIslandPreviewPainter extends CustomPainter {
  _MainIslandPreviewPainter({
    required this.island,
    required this.environment,
  });

  final IslandState island;
  final MoodEnvironmentState environment;

  static final _renderer = IslandRenderer(compact: true);

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.render(canvas, size, island, environment);
  }

  @override
  bool shouldRepaint(covariant _MainIslandPreviewPainter oldDelegate) {
    return oldDelegate.island.radius != island.radius ||
        oldDelegate.island.prosperityTier != island.prosperityTier;
  }
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
    final w = (viewportSize.width * 0.26 * typeScale)
        .clamp(36.0, viewportSize.width * 0.30)
        .toDouble();
    final h = (viewportSize.height * 0.30 * typeScale)
        .clamp(40.0, viewportSize.height * 0.34)
        .toDouble();
    // 脚点略靠岛心后侧，给前方小人留出站位，避免建筑盖住角色。
    final footY = viewportSize.height * 0.54;
    final left = viewportSize.width * 0.50 - w / 2;
    final top = (footY - h).clamp(viewportSize.height * 0.16, footY);
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

class _MainIslandPreviewDecor extends StatelessWidget {
  const _MainIslandPreviewDecor({
    required this.config,
    required this.userLevel,
    required this.viewportSize,
  });

  final DecorConfig config;
  final int userLevel;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final size = _decorSize(config, userLevel, viewportSize);
    final left = config.x * viewportSize.width - size.width / 2;
    final top = config.y * viewportSize.height - size.height;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (size.width * dpr).round().clamp(24, 160);

    return Positioned(
      left: left,
      top: top,
      width: size.width,
      height: size.height,
      child: Image.asset(
        'assets/images/${config.assetPath}',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.low,
        cacheWidth: cacheW,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Size _decorSize(DecorConfig config, int userLevel, Size viewportSize) {
    final resolver = const DecorScaleResolver();
    final baseHeight = DecorScaleResolver.baseHeightFor(config.category);
    final scale = resolver.finalScale(config, userLevel);
    final depth = 0.82 + (config.y - 0.44).clamp(0.0, 0.28) * 0.9;
    final height = (baseHeight * scale * depth * 0.82)
        .clamp(8.0, viewportSize.height * 0.11)
        .toDouble();
    return Size(height, height);
  }
}

class _MainIslandPreviewCompanion extends StatelessWidget {
  const _MainIslandPreviewCompanion({
    required this.character,
    required this.viewportSize,
    required this.companion,
  });

  final CharacterSnapshot character;
  final Size viewportSize;
  final UserCompanion companion;

  @override
  Widget build(BuildContext context) {
    final size = (viewportSize.width * 0.20).clamp(38.0, 64.0).toDouble();
    final boxH = size * 1.15;
    final left = character.normalizedPos.dx * viewportSize.width - size / 2;
    final top = character.normalizedPos.dy * viewportSize.height - boxH * 0.82;
    // 抵消父级 rotateX 俯视对竖直方向的压扁，保持小人等比。
    final yRestore =
        1.0 / math.cos(WorldPreviewCamera.topDownPitchRadians);

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: boxH,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(1.0, yRestore, 1.0),
        child: UserCompanionView(
          companion: companion,
          size: size,
          showAura: false,
        ),
      ),
    );
  }
}
