import 'package:flutter/material.dart';

import '../../../core/growth/level_title_assets.dart';
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

String polaroidDateLine(String islandName, DateTime takenAt) {
  final name = islandName.trim().isEmpty ? '这座岛' : islandName.trim();
  return '$name · ${takenAt.month}月${takenAt.day}日';
}
