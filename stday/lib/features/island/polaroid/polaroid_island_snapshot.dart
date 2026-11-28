import 'package:flutter/material.dart';

import '../../../core/growth/level_title_assets.dart';
import '../../../data/models/polaroid_models.dart';
import '../../../island/building/building_sprite_metrics.dart';
import '../../../island/config/growth_island_configs.dart';
import '../../../island/decor/decor_config.dart';
import '../../../world/island/detail_building_spread.dart';
import '../../../world/island/painted_island_asset.dart';
import '../../../world/island/painted_island_pits.dart';
import '../../../world/preview/story_island_building_icon.dart';
import 'polaroid_skin.dart';

class PolaroidPlacement {
  const PolaroidPlacement({
    required this.asset,
    required this.plate,
    required this.heightFactor,
    this.aspect = 0.92,
    this.baseline = 0,
  });

  final String asset;
  final Offset plate;
  final double heightFactor;
  final double aspect;
  final double baseline;
}

/// 照片区是这座岛当时的样子：天空、岛坯、主题小物和已经出现的建筑。
class PolaroidIslandSnapshot extends StatelessWidget {
  const PolaroidIslandSnapshot({
    super.key,
    required this.card,
    required this.scene,
  });

  final PolaroidCardModel card;
  final PolaroidScene scene;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 180,
          constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : 180,
        );
        final plate = PaintedIslandAsset.layoutRect(size);
        final placements = polaroidPlacements(card);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            CustomPaint(painter: _PolaroidSkyPainter(scene: scene, plate: plate)),
            Positioned.fromRect(
              rect: plate,
              child: Image.asset(
                polaroidLandAsset(card),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            if (!card.isMain && card.categoryId.isNotEmpty)
              _StoryThemeProps(categoryId: card.categoryId, viewportSize: size),
            for (final placement in placements)
              _placed(size, placement),
            if (card.isMain)
              Positioned(
                key: const Key('polaroid-main-level-badge'),
                left: size.width * 0.04,
                top: size.height * 0.04,
                child: LevelTitleBadgeImage(
                  level: card.level.clamp(1, 20),
                  size: size.shortestSide * 0.2,
                  borderRadius: 8,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _placed(Size size, PolaroidPlacement placement) {
    final plate = PaintedIslandAsset.layoutRect(size);
    final foot = PaintedIslandAsset.plateToCanvas(placement.plate, size);
    final height = plate.height * placement.heightFactor;
    final width = height * placement.aspect;
    final sink = height * placement.baseline;
    return Positioned(
      left: foot.dx - width / 2,
      top: foot.dy - height + sink,
      width: width,
      height: height,
      child: Image.asset(
        placement.asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _StoryThemeProps extends StatelessWidget {
  const _StoryThemeProps({
    required this.categoryId,
    required this.viewportSize,
  });

  final String categoryId;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final props = PaintedIslandPits.themeProps(categoryId);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final prop in props)
          _prop(prop),
      ],
    );
  }

  Widget _prop(StoryIslandThemeProp prop) {
    final foot = PaintedIslandAsset.plateToCanvas(prop.plate, viewportSize);
    final height = viewportSize.shortestSide * 0.12;
    return Positioned(
      left: foot.dx - height / 2,
      top: foot.dy - height,
      width: height,
      height: height,
      child: Image.asset(
        'assets/images/${prop.asset}',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PolaroidSkyPainter extends CustomPainter {
  const _PolaroidSkyPainter({required this.scene, required this.plate});

  final PolaroidScene scene;
  final Rect plate;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(scene.skyTop, Colors.white, 0.08)!,
            scene.skyBottom,
            scene.sea,
          ],
          stops: const [0.0, 0.46, 1.0],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(plate.center.dx, plate.center.dy + plate.height * 0.08),
        width: plate.width * 0.72,
        height: plate.height * 0.42,
      ),
      Paint()..color = scene.grass.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _PolaroidSkyPainter oldDelegate) {
    return oldDelegate.scene.skyTop != scene.skyTop ||
        oldDelegate.scene.skyBottom != scene.skyBottom ||
        oldDelegate.scene.sea != scene.sea ||
        oldDelegate.scene.grass != scene.grass ||
        oldDelegate.plate != plate;
  }
}

String polaroidLandAsset(PolaroidCardModel card) {
  final category = _storyCategory(card);
  if (category != null) return 'assets/images/islands/$category/land.png';
  return 'assets/images/islands/main_island_blank.png';
}

List<String> polaroidSnapshotAssetPaths(PolaroidCardModel card) {
  return [
    polaroidLandAsset(card),
    for (final placement in polaroidPlacements(card)) placement.asset,
    if (card.isMain) LevelTitleAssets.assetPathForLevel(card.level.clamp(1, 20)),
    if (!card.isMain && card.categoryId.isNotEmpty)
      for (final prop in PaintedIslandPits.themeProps(card.categoryId))
        'assets/images/${prop.asset}',
  ];
}

List<PolaroidPlacement> polaroidPlacements(PolaroidCardModel card) {
  final story = _storyLevel(card);
  if (story != null) {
    final category = story.$1;
    final level = story.$2;
    final start = level <= 2 ? 1 : level - 2;
    return [
      for (var current = start; current <= level; current++)
        PolaroidPlacement(
          asset: StoryIslandBuildingIcon.buildingAssetForLevel(category, current),
          plate: PaintedIslandPits.storyBuilding(current),
          heightFactor: current == level ? 0.32 : 0.22,
        ),
    ];
  }
  if (card.isMain) return mainIslandPolaroidPlacements(card.level);
  final asset = polaroidImageAsset(card.assetKey);
  return [
    PolaroidPlacement(
      asset: 'assets/images/${PaintedIslandPits.treeSprite(card.level)}',
      plate: PaintedIslandPits.tree,
      heightFactor: 0.28,
    ),
    if (asset != null)
      PolaroidPlacement(
        asset: asset,
        plate: const Offset(0.62, 0.48),
        heightFactor: 0.22,
      ),
  ];
}

/// 主岛这一级当时已经长出来的树和建筑。升级替换的旧样子不再叠在同一坑位上。
List<PolaroidPlacement> mainIslandPolaroidPlacements(int level) {
  final unlocked = const GrowthIslandConfigRepository()
      .resolveLevel(level.clamp(1, 20))
      .unlockBuildings
      .toList();
  if (unlocked.contains('growth_house_lv2')) unlocked.remove('growth_house');
  if (unlocked.contains('lighthouse')) unlocked.remove('lighthouse_base');
  final treePath = PaintedIslandPits.treeSprite(level);
  final treeId = treePath.split('/').last.replaceAll('.png', '');
  final placements = <PolaroidPlacement>[
    PolaroidPlacement(
      asset: 'assets/images/$treePath',
      plate: PaintedIslandPits.tree,
      heightFactor: (DetailBuildingSpread.treeHeightFactor(treeId) * 2).clamp(0.14, 0.26),
      aspect: 0.86,
      baseline: 0.06,
    ),
  ];
  for (final id in unlocked) {
    final plate = PaintedIslandPits.building(id);
    if (plate == null) continue;
    placements.add(
      PolaroidPlacement(
        asset: 'assets/images/buildings/$id.png',
        plate: plate,
        heightFactor: (DetailBuildingSpread.roleFor(id) * 1.7).clamp(0.12, 0.38),
        aspect: BuildingSpriteMetrics.canvasAspect(id),
        baseline: BuildingSpriteMetrics.baselineInset(id),
      ),
    );
  }
  for (final config in DecorConfigs.unlockedMainIslandAt(level)) {
    final plate = _polaroidDecorPlate(config);
    if (plate == null) continue;
    final tree = config.category == DecorCategory.tree;
    placements.add(
      PolaroidPlacement(
        asset: 'assets/images/${config.assetPath}',
        plate: plate,
        heightFactor: tree
            ? (DetailBuildingSpread.treeHeightFactor(config.id) * 2).clamp(0.12, 0.24)
            : 0.11,
        aspect: 0.9,
      ),
    );
  }
  placements.sort((a, b) => a.plate.dy.compareTo(b.plate.dy));
  return placements;
}

Offset? _polaroidDecorPlate(DecorConfig config) {
  final placed = PaintedIslandPits.placedDecor(config.id);
  if (placed != null) return placed;
  if (!DecorConfigs.isMainIslandSkyDecor(config)) return null;
  return Offset(config.x.clamp(0.12, 0.88), 0.16);
}

String? _storyCategory(PolaroidCardModel card) {
  if (card.isMain) return null;
  final fromKey = _storyLevel(card)?.$1;
  if (fromKey != null && fromKey.isNotEmpty) return fromKey;
  final category = card.categoryId.trim();
  if (category.isEmpty) return null;
  return category;
}

(String, int)? _storyLevel(PolaroidCardModel card) {
  if (!card.assetKey.startsWith('story:')) return null;
  final parts = card.assetKey.split(':');
  if (parts.length < 3) return null;
  final category = parts[1].trim().isEmpty ? card.categoryId.trim() : parts[1].trim();
  if (category.isEmpty) return null;
  final level = int.tryParse(parts[2]) ?? card.level;
  return (category, level.clamp(1, 10));
}
