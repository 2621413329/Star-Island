import 'package:flutter/material.dart';

import '../../../core/growth/island_unlock_catalog.dart';
import '../../../core/growth/level_title_assets.dart';
import '../../../data/models/polaroid_models.dart';
import '../../../world/preview/story_island_building_icon.dart';

class PolaroidSkin {
  const PolaroidSkin({
    required this.id,
    required this.paper,
    required this.ink,
    required this.edge,
  });

  final String id;
  final Color paper;
  final Color ink;
  final Color edge;

  static const plain = PolaroidSkin(
    id: 'plain',
    paper: Color(0xFFF7F1E6),
    ink: Color(0xFF5C4A3A),
    edge: Color(0xFFE7DCCB),
  );

  static const catalog = <String, PolaroidSkin>{
    'plain': plain,
  };

  static PolaroidSkin resolve(String? id) => catalog[id] ?? plain;
}

String? polaroidImageAsset(String assetKey) {
  if (assetKey.startsWith('story:')) {
    final parts = assetKey.split(':');
    if (parts.length >= 3) {
      final level = int.tryParse(parts[2]) ?? 1;
      return StoryIslandBuildingIcon.buildingAssetForLevel(parts[1], level);
    }
  }
  if (assetKey.startsWith('building:')) {
    final id = assetKey.substring('building:'.length);
    if (id.isEmpty) return null;
    return 'assets/images/buildings/$id.png';
  }
  if (assetKey.startsWith('title:')) {
    final level = int.tryParse(assetKey.substring('title:'.length)) ?? 1;
    return LevelTitleAssets.assetPathForLevel(level);
  }
  return null;
}

/// 主岛正面写这一级真正解锁的建筑或植物，和岛上能看见的是同一批。
String polaroidFrontLine(PolaroidCardModel card) {
  if (card.isMain) {
    final items = IslandUnlockCatalog.itemsAtLevel(card.level);
    final buildings = [
      for (final item in items)
        if (item.kind == IslandUnlockKind.building) item,
    ];
    final focus = buildings.isNotEmpty ? buildings : items;
    if (focus.isNotEmpty) {
      final names = focus.take(2).map((item) => item.name).join('、');
      final more = focus.length > 2 ? '等' : '';
      return '今天，多了$names$more';
    }
  }
  final caption = card.frontCaption.trim();
  return caption.isEmpty ? '今天，多了新的一角' : caption;
}

String polaroidDateLine(String islandName, DateTime takenAt) {
  final name = islandName.trim().isEmpty ? '这座岛' : islandName.trim();
  return '$name · ${takenAt.month}月${takenAt.day}日';
}

/// 正面和背面共用这一比例，翻面时外框不变。
const polaroidCardAspect = 0.76;

/// 打开相册时铺上的当前主题天空。颜色来自岛上正在用的氛围。
class PolaroidScene {
  const PolaroidScene({
    required this.skyTop,
    required this.skyBottom,
    required this.sea,
    required this.grass,
    required this.sand,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sea;
  final Color grass;
  final Color sand;

  static const fallback = PolaroidScene(
    skyTop: Color(0xFFE8F6FA),
    skyBottom: Color(0xFFD4EFF5),
    sea: Color(0xFF5BB5D5),
    grass: Color(0xFF74D680),
    sand: Color(0xFFFFF0D0),
  );

  Color get ink => ThemeData.estimateBrightnessForColor(skyTop) == Brightness.dark
      ? const Color(0xFFF7F1E6)
      : const Color(0xFF3D3229);
}

class PolaroidThemeWall extends StatelessWidget {
  const PolaroidThemeWall({
    super.key,
    required this.scene,
    required this.child,
  });

  final PolaroidScene scene;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('polaroid-theme-wall'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(scene.skyTop, Colors.white, 0.12)!,
            scene.skyBottom,
            Color.lerp(scene.skyBottom, scene.sea, 0.55)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// 背面正文。模型还没写好时，用这几天日记里的原句拼一句具体的。
String polaroidBackBody(PolaroidCardModel card) {
  if (card.isDeveloping) return '正在显影';
  final summary = card.backSummary?.trim() ?? '';
  if (summary.isNotEmpty) return summary;
  return polaroidLocalSummary(card);
}

String polaroidLocalSummary(PolaroidCardModel card) {
  final bits = <String>[];
  for (final moment in card.sourceMoments) {
    final excerpt = moment.excerpt.trim();
    if (excerpt.isEmpty) continue;
    bits.add(
      '${moment.momentDate.month}月${moment.momentDate.day}日写到$excerpt',
    );
    if (bits.length >= 4) break;
  }
  if (bits.isEmpty) return '';
  final name = card.buildingName.trim().isEmpty ? '新的一角' : card.buildingName.trim();
  return '这段日子岛上多了$name。${bits.join('；')}。';
}
