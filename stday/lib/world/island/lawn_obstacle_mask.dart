import 'dart:ui';

import '../../island/decor/decor_config.dart';
import '../../island/decor/decor_placement_resolver.dart';
import '../../island/decor/decor_scale_resolver.dart';
import '../engine/world_state.dart';

/// 草坪生成需避开的障碍区域（建筑、装饰、主角站位）。
class LawnObstacleMask {
  const LawnObstacleMask({
    required this.obstacles,
    required this.protagonistFoot,
  });

  final List<LawnObstacleRegion> obstacles;
  final Offset protagonistFoot;

  static LawnObstacleMask fromWorldState(
    WorldState state, {
    required double sceneHeight,
    Map<String, Offset>? decorPositionOverrides,
  }) {
    final level = state.characters.isEmpty ? 1 : state.characters.first.level;
    final protagonist = _resolveProtagonistFoot(state);
    final regions = <LawnObstacleRegion>[];

    for (final building in state.buildings) {
      regions.add(LawnObstacleRegion(
        id: building.definitionId,
        rect: _buildingRect(building),
      ));
    }

    for (final decor in DecorConfigs.unlockedAt(level)) {
      if (_isSkyDecor(decor)) continue;
      final pos = decorPositionOverrides?[decor.id] ?? Offset(decor.x, decor.y);
      regions.add(LawnObstacleRegion(
        id: decor.id,
        rect: _decorRect(decor, level, sceneHeight, pos),
      ));
    }

    regions.add(LawnObstacleRegion(
      id: 'protagonist',
      rect: Rect.fromCenter(
        center: protagonist,
        width: 0.14,
        height: 0.10,
      ),
    ));

    return LawnObstacleMask(
      obstacles: regions,
      protagonistFoot: protagonist,
    );
  }

  static Offset _resolveProtagonistFoot(WorldState state) {
    for (final character in state.characters) {
      if (character.id == 'protagonist') {
        return character.normalizedPos;
      }
    }
    return DecorPlacementResolver.protagonistFoot;
  }

  static bool _isSkyDecor(DecorConfig decor) {
    return decor.category == DecorCategory.cloud ||
        decor.category == DecorCategory.bird ||
        decor.category == DecorCategory.butterfly ||
        decor.category == DecorCategory.firefly;
  }

  static Rect _buildingRect(BuildingSnapshot building) {
    final w = building.size.dx.clamp(0.08, 0.22);
    final h = (building.size.dy * 0.52).clamp(0.06, 0.18);
    return Rect.fromCenter(
      center: Offset(building.anchor.dx, building.anchor.dy - h * 0.22),
      width: w,
      height: h,
    );
  }

  static Rect _decorRect(
    DecorConfig decor,
    int level,
    double sceneHeight,
    Offset position,
  ) {
    const resolver = DecorScaleResolver();
    final baseH = DecorScaleResolver.baseHeightFor(decor.category) *
        resolver.finalScale(decor, level);
    final normH = (baseH / sceneHeight).clamp(0.03, 0.22);
    final aspect = 0.85;
    final normW = normH * aspect;
    return Rect.fromCenter(
      center: Offset(position.dx, position.dy - normH * 0.42),
      width: normW,
      height: normH,
    ).inflate(0.012);
  }

  bool blocksTuftBase(Offset normalizedPoint, {double padding = 0.008}) {
    for (final obstacle in obstacles) {
      if (obstacle.rect.inflate(padding).contains(normalizedPoint)) {
        return true;
      }
    }
    return false;
  }

  /// 该点是否在障碍「靠观众一侧」，可长前景草部分遮挡。
  bool isInFrontOfObstacle(Offset normalizedPoint, LawnObstacleRegion obstacle) {
    if (!obstacle.rect.inflate(0.02).contains(normalizedPoint)) return false;
    return normalizedPoint.dy >= obstacle.rect.center.dy - 0.01;
  }

  List<LawnObstacleRegion> foregroundObstaclesFor(Offset normalizedPoint) {
    return obstacles
        .where((o) => isInFrontOfObstacle(normalizedPoint, o))
        .toList();
  }
}

class LawnObstacleRegion {
  const LawnObstacleRegion({required this.id, required this.rect});

  final String id;
  final Rect rect;
}

enum LawnRenderPass { background, foreground }
