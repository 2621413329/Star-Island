import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../world/engine/world_state.dart';
import '../decor/decor_config.dart';
import '../decor/decor_placement_resolver.dart';
import '../placement/island_building_layout.dart';
import '../placement/main_island_placement_zones.dart';

/// 主岛程序化布局调试叠层：禁放区、建筑 footprint、装饰 occupancy。
class MainIslandDebugOverlay {
  MainIslandDebugOverlay._();

  static void draw(
    Canvas canvas,
    Size size, {
    required WorldState worldState,
    Map<String, Offset>? decorPositions,
    int userLevel = 1,
  }) {
    _drawZone(
      canvas,
      size,
      MainIslandPlacementZones.protagonistExclusion,
      color: const Color(0x66E53935),
      label: '主角',
    );
    _drawZone(
      canvas,
      size,
      MainIslandPlacementZones.centralVoid,
      color: const Color(0x66FDD835),
      label: '留白',
    );

    final academyAnchor = _academyAnchor(worldState.buildings);
    _drawZone(
      canvas,
      size,
      MainIslandPlacementZones.academyRearExclusion(
        academyAnchor: academyAnchor,
      ),
      color: const Color(0x66FB8C00),
      label: '学院后',
    );

    for (final plaza in MainIslandPlacementZones.plazaExclusions) {
      _drawZone(
        canvas,
        size,
        plaza,
        color: const Color(0x6642A5F5),
        label: '广场',
      );
    }

    for (final parcel in MainIslandPlacementZones.largeTreeShoreParcels) {
      _drawZone(
        canvas,
        size,
        parcel,
        color: const Color(0x662E7D32),
        label: '大树岸',
      );
    }

    for (final building in worldState.buildings) {
      final rect = IslandBuildingLayout.occupancyRect(
        building.anchor,
        building.size,
      );
      _drawZone(
        canvas,
        size,
        rect,
        color: const Color(0x661E88E5),
        stroke: 1.4,
        label: building.definitionId,
      );
    }

    final configs = DecorConfigs.unlockedMainIslandAt(userLevel);
    const resolver = DecorPlacementResolver();
    final positions = decorPositions ??
        resolver.resolve(configs, buildings: worldState.buildings);
    for (final config in configs) {
      if (resolver.isSkyDecor(config)) continue;
      final pos = positions[config.id];
      if (pos == null) continue;
      _drawZone(
        canvas,
        size,
        resolver.paddedOccupancyFor(config, pos),
        color: const Color(0x6643A047),
        stroke: 1.0,
      );
    }

    _drawPoint(
      canvas,
      size,
      MainIslandPlacementZones.protagonistFoot,
      const Color(0xFFE53935),
    );
  }

  static Offset _academyAnchor(Iterable<BuildingSnapshot> buildings) {
    for (final building in buildings) {
      if (building.definitionId == 'growth_academy') {
        return building.anchor;
      }
    }
    return MainIslandPlacementZones.academyDefaultAnchor;
  }

  static void _drawZone(
    Canvas canvas,
    Size size,
    Rect normalized, {
    required Color color,
    double stroke = 1.2,
    String? label,
  }) {
    final rect = _toCanvasRect(normalized, size);
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (label == null) return;
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: 0.95),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    text.paint(canvas, rect.topLeft + const Offset(2, 2));
  }

  static void _drawPoint(Canvas canvas, Size size, Offset normalized, Color color) {
    final point = Offset(normalized.dx * size.width, normalized.dy * size.height);
    canvas.drawCircle(point, 4, Paint()..color = color);
  }

  static Rect _toCanvasRect(Rect normalized, Size size) {
    return Rect.fromLTRB(
      normalized.left * size.width,
      normalized.top * size.height,
      normalized.right * size.width,
      normalized.bottom * size.height,
    );
  }
}
