import 'dart:math' as math;
import 'dart:ui';

import '../building/building_footprint.dart';
import '../config/growth_island_config_models.dart';
import 'island_placement.dart';
import 'main_island_placement_zones.dart';
import '../../world/engine/world_state.dart';

/// 成长岛建筑落点：关键建筑固定区域 + 其余稳定随机 + 防重叠。
class IslandBuildingLayout {
  const IslandBuildingLayout._();

  /// 左前岸，避开加宽后的小人禁区（按满半径设计，放置时再按 islandRadius 收缩）。
  static const starterStoneAnchor = Offset(0.22, 0.58);

  static const _fixedAnchorIds = {
    'starter_stone',
    'growth_academy',
    'harbor_pier',
  };

  static const _fixedSemanticAnchors = <String, Offset>{};

  /// 建筑间最小留白（归一化），用于放大后视觉碰撞检测。
  static const overlapPadding = 0.004;

  static Offset preferredAnchor(
    BuildingConfig config, {
    required double islandRadius,
  }) {
    if (config.id == 'harbor_pier') {
      // 前缘正中岛缘：锚点=图片中心，随岛屿半径外扩（见 harborPierAnchor）。
      return IslandPlacement.harborPierAnchor(islandRadius: islandRadius);
    }
    if (config.id == 'starter_stone') {
      return IslandPlacement.clampToGrowthIsland(
        IslandPlacement.scaleAnchorToRadius(
          starterStoneAnchor,
          islandRadius: islandRadius,
        ),
        inset: 0.86,
        islandRadius: islandRadius,
      );
    }
    if (usesFixedAnchor(config.id)) {
      return IslandPlacement.clampToGrowthIsland(
        IslandPlacement.scaleAnchorToRadius(
          _fixedSemanticAnchors[config.id] ?? config.position,
          islandRadius: islandRadius,
        ),
        inset: 0.86,
        islandRadius: islandRadius,
      );
    }
    final raw = _randomIslandAnchor(config);
    if (IslandPlacement.isOnGrowthIsland(
      raw,
      inset: 0.86,
      islandRadius: islandRadius,
    )) {
      return raw;
    }
    return IslandPlacement.clampToGrowthIsland(
      raw,
      inset: 0.86,
      islandRadius: islandRadius,
    );
  }

  static bool usesFixedAnchor(String buildingId) {
    return _fixedAnchorIds.contains(buildingId);
  }

  static bool isZoneValidForBuilding({
    required BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    Offset? academyAnchor,
  }) {
    return _isZoneValidCandidate(
      config: config,
      anchor: anchor,
      footprint: footprint,
      academyAnchor: academyAnchor,
    );
  }

  static Offset resolveAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    final resolved = _resolveAnchorCandidate(
      config: config,
      preferred: preferred,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    );
    if (_isValidCandidate(
      config: config,
      anchor: resolved,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return resolved;
    }
    final zoneFallback = _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
      placed: placed,
    );
    if (zoneFallback != null) return zoneFallback;

    for (var y = 0.24; y <= 0.70; y += 0.012) {
      for (var x = 0.22; x <= 0.78; x += 0.012) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.86);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    return _findZoneValidAnchor(
          config: config,
          preferred: preferred,
          footprint: footprint,
          academyAnchor: academyAnchor,
          placed: placed,
        ) ??
        _safeFallbackAnchor(config);
  }

  static Offset _resolveAnchorCandidate({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (_isValidCandidate(
      config: config,
      anchor: preferred,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return preferred;
    }

    const attempts = <Offset>[
      Offset(0, 0),
      Offset(0.03, 0),
      Offset(-0.03, 0),
      Offset(0, 0.03),
      Offset(0, -0.03),
      Offset(0.04, 0.02),
      Offset(-0.04, 0.02),
      Offset(0.04, -0.02),
      Offset(-0.04, -0.02),
      Offset(0.06, 0),
      Offset(-0.06, 0),
      Offset(0, 0.06),
      Offset(0, -0.06),
    ];

    for (final delta in attempts) {
      final candidate = IslandPlacement.clampToGrowthIsland(
        preferred + delta,
        inset: 0.86,
      );
      if (_isValidCandidate(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    if (preferred.dy < 0.40) {
      final upperBand = _findZoneValidAnchor(
        config: config,
        preferred: preferred,
        footprint: footprint,
        academyAnchor: academyAnchor,
        placed: placed,
      );
      if (upperBand != null &&
          !_overlapsAny(
            upperBand,
            footprint,
            placed,
            buildingId: config.id,
          )) {
        return upperBand;
      }
    }

    for (var ring = 1; ring <= 12; ring++) {
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        final dist = 0.045 * ring;
        final candidate = IslandPlacement.clampToGrowthIsland(
          preferred + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
          inset: 0.86,
        );
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    for (var ring = 1; ring <= 36; ring++) {
      for (var i = 0; i < 24; i++) {
        final angle = i * math.pi / 12;
        final dist = 0.028 * ring;
        final candidate = IslandPlacement.clampToGrowthIsland(
          preferred + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
          inset: 0.86,
        );
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    for (var y = 0.36; y <= 0.70; y += 0.018) {
      for (var x = 0.22; x <= 0.78; x += 0.018) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.86);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    for (var y = 0.24; y <= 0.42; y += 0.014) {
      for (var x = 0.24; x <= 0.76; x += 0.014) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.82);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    final configFallback =
        IslandPlacement.clampToGrowthIsland(config.position, inset: 0.86);
    if (_isValidCandidate(
      config: config,
      anchor: configFallback,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return configFallback;
    }

    final zoneOnly = _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
      placed: placed,
    );
    if (zoneOnly != null) return zoneOnly;

    for (var y = 0.24; y <= 0.70; y += 0.010) {
      for (var x = 0.22; x <= 0.78; x += 0.010) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    return zoneOnly ?? _safeFallbackAnchor(config);
  }

  static Offset? findNearestZoneValidAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    Offset? academyAnchor,
    List<PlacedFootprint> placed = const [],
  }) {
    return _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
      placed: placed,
    );
  }

  static Offset? _findZoneValidAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    Offset? academyAnchor,
    List<PlacedFootprint> placed = const [],
  }) {
    final bandTop = preferred.dy < 0.40 ? 0.22 : 0.36;
    final bandBottom = preferred.dy < 0.40 ? 0.42 : 0.70;
    Offset? best;
    var bestDistance = double.infinity;
    for (var y = bandTop; y <= bandBottom; y += 0.015) {
      for (var x = 0.22; x <= 0.78; x += 0.015) {
        final candidate = Offset(x, y);
        if (!IslandPlacement.isOnGrowthIsland(candidate, inset: 0.78)) {
          continue;
        }
        if (!_isZoneValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          academyAnchor: academyAnchor,
        )) {
          continue;
        }
        if (!BuildingFootprint.isVisuallyOnGrowthIsland(
          candidate,
          footprint,
          buildingId: config.id,
        )) {
          continue;
        }
        if (_overlapsAny(
          candidate,
          footprint,
          placed,
          buildingId: config.id,
        )) {
          continue;
        }
        final dist = (candidate - preferred).distanceSquared;
        if (dist < bestDistance) {
          bestDistance = dist;
          best = candidate;
        }
      }
    }
    return best;
  }

  static bool _isFrontHalfBuilding(BuildingConfig config) {
    return switch (config.type) {
      'house' ||
      'shed' ||
      'tent' ||
      'fountain' ||
      'flowerbed' ||
      'windchime' ||
      'mailbox' ||
      'library' ||
      'gallery' =>
        true,
      _ => config.id == 'memory_mailbox' ||
          config.id == 'record_shed' ||
          config.id == 'quiet_tent' ||
          config.id == 'memory_fountain' ||
          config.id == 'habit_flowerbed' ||
          config.id == 'emotion_windchime' ||
          config.id == 'library_seed' ||
          config.id == 'memory_gallery' ||
          config.id == 'growth_house' ||
          config.id == 'growth_house_lv2',
    };
  }

  static Offset _randomIslandAnchor(BuildingConfig config) {
    final rng = math.Random(_seed(config.id));
    final upperLandmark = config.type == 'observatory' ||
        config.type == 'clocktower' ||
        config.id == 'lighthouse';
    final frontHalf = _isFrontHalfBuilding(config);
    final academyY = MainIslandPlacementZones.academyDefaultAnchor.dy;
    for (var i = 0; i < 96; i++) {
      final dx = switch (config.id) {
        // 三座高塔分列：钟楼偏左、天文台右中、灯塔更靠右岸。
        'growth_clocktower' => 0.20 + rng.nextDouble() * 0.08,
        'dream_observatory' => 0.66 + rng.nextDouble() * 0.06,
        'lighthouse' => 0.78 + rng.nextDouble() * 0.05,
        // 前半侧建筑分列左右岸，范围收紧以减少分散。
        _ when frontHalf => rng.nextBool()
            ? 0.18 + rng.nextDouble() * 0.10
            : 0.72 + rng.nextDouble() * 0.10,
        _ => 0.28 + rng.nextDouble() * 0.44,
      };
      final dy = switch (config.id) {
        // 地标落在学院侧前方，拉开与放大后学院主体的间距。
        'dream_observatory' ||
        'growth_clocktower' =>
          academyY + 0.10 + rng.nextDouble() * 0.06,
        'lighthouse' => academyY + 0.10 + rng.nextDouble() * 0.08,
        _ when upperLandmark => academyY + 0.10 + rng.nextDouble() * 0.08,
        // 帐篷/风铃/喷泉等靠前侧（岛面前缘）。
        'quiet_tent' ||
        'emotion_windchime' ||
        'memory_fountain' =>
          0.62 + rng.nextDouble() * 0.06,
        _ when frontHalf => 0.56 + rng.nextDouble() * 0.08,
        _ => academyY + 0.06 + rng.nextDouble() * 0.12,
      };
      final candidate = Offset(dx, dy);
      if (candidate.dy < academyY + 0.01) continue;
      if (!IslandPlacement.isOnGrowthIsland(candidate, inset: 0.82)) {
        continue;
      }
      if (MainIslandPlacementZones.protagonistExclusion.contains(candidate)) {
        continue;
      }
      return candidate;
    }
    return _safeFallbackAnchor(config);
  }

  static Offset safeFallbackAnchor(
    BuildingConfig config, {
    double islandRadius = 1.0,
  }) {
    return _safeFallbackAnchor(config, islandRadius: islandRadius);
  }

  static Offset _safeFallbackAnchor(
    BuildingConfig config, {
    double islandRadius = 1.0,
  }) {
    final anchor = switch (config.id) {
      'dream_observatory' => const Offset(0.72, 0.50),
      'lighthouse' => const Offset(0.80, 0.48),
      'growth_clocktower' => const Offset(0.24, 0.50),
      'memory_gallery' => const Offset(0.74, 0.54),
      'library_seed' => const Offset(0.26, 0.54),
      'growth_house' || 'growth_house_lv2' => const Offset(0.24, 0.54),
      'emotion_windchime' => const Offset(0.24, 0.64),
      'quiet_tent' => const Offset(0.76, 0.66),
      'record_shed' => const Offset(0.76, 0.52),
      'habit_flowerbed' => const Offset(0.70, 0.62),
      'memory_fountain' => const Offset(0.30, 0.64),
      'memory_mailbox' => const Offset(0.76, 0.54),
      _ => _nudgedConfigPosition(config),
    };
    if (config.id == 'harbor_pier' || config.id == 'starter_stone') {
      return anchor;
    }
    return MainIslandPlacementZones.clampBuildingAnchor(
      anchor,
      const Offset(0.20, 0.18),
      islandRadius: islandRadius,
    );
  }

  static Offset _nudgedConfigPosition(BuildingConfig config) {
    var pos = config.position;
    final frontHalf = _isFrontHalfBuilding(config);
    if (MainIslandPlacementZones.protagonistExclusion.contains(pos) ||
        (pos.dx - 0.5).abs() < 0.10) {
      pos = Offset(
        pos.dx < 0.5 ? 0.24 : 0.76,
        frontHalf ? 0.58 : (pos.dy > 0.48 ? 0.40 : pos.dy),
      );
    } else if (frontHalf && pos.dy < 0.52) {
      // 小/中建筑不要被挤回后景导致“消失感”。
      pos = Offset(pos.dx, 0.58);
    }
    final nudged = Offset(
      (pos.dx - 0.5).abs() < 0.10 ? (pos.dx < 0.5 ? 0.24 : 0.76) : pos.dx,
      pos.dy,
    );
    return MainIslandPlacementZones.clampBuildingAnchor(
      nudged,
      const Offset(0.20, 0.18),
      islandRadius: 1.0,
    );
  }

  static int placementPriority(BuildingConfig config) {
    return switch (config.id) {
      'starter_stone' => 1000,
      'growth_academy' => 990,
      'harbor_pier' => 900,
      // 地标先占外层岸位；观测台优先，保证学院侧前方合法带。
      'dream_observatory' => 880,
      'lighthouse' || 'lighthouse_base' || 'growth_clocktower' => 860,
      _ => 100 + (config.size.dx * config.size.dy * 400).round(),
    };
  }

  static bool overlapsBuilding(
    Offset point,
    BuildingSnapshot building, {
    double margin = 0,
  }) {
    return occupancyRect(building.anchor, building.size, margin: margin)
        .contains(point);
  }

  static bool overlapsAnyBuilding(
    Offset point,
    Iterable<BuildingSnapshot> buildings, {
    double margin = 0,
  }) {
    for (final building in buildings) {
      if (overlapsBuilding(point, building, margin: margin)) {
        return true;
      }
    }
    return false;
  }

  static bool collisionOverlapsPlaced(
    Offset anchor,
    Offset footprint,
    List<PlacedFootprint> placed, {
    String? buildingId,
  }) {
    return _overlapsAny(
      anchor,
      footprint,
      placed,
      buildingId: buildingId,
    );
  }

  /// 放大后视觉半径（归一化）：锚点间距下限，配合更小显示体量减少立面重合。
  static double visualSeparationRadius(String? buildingId, Offset footprint) {
    if (buildingId == 'growth_academy') {
      return 0.058;
    }
    if (buildingId == 'harbor_pier') {
      return 0.062;
    }
    if (_isSlenderLandmarkId(buildingId)) {
      return 0.036;
    }
    return 0.034;
  }

  static bool _overlapsAny(
    Offset anchor,
    Offset footprint,
    List<PlacedFootprint> placed, {
    String? buildingId,
  }) {
    final radius = visualSeparationRadius(buildingId, footprint);
    for (final other in placed) {
      if (_skipVisualCollisionPair(buildingId, other.buildingId)) {
        continue;
      }
      final minDist = radius +
          visualSeparationRadius(other.buildingId, other.footprint) +
          overlapPadding;
      if ((anchor - other.anchor).distance < minDist) {
        return true;
      }
    }
    return false;
  }

  /// 栈桥在河岸外缘，与岛面建筑不做视觉盒互斥；起点石与学院/邻岸小品可共存。
  static bool skipsVisualCollision(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == 'harbor_pier' || b == 'harbor_pier') return true;
    if ((a == 'starter_stone' || b == 'starter_stone') &&
        (a == 'growth_academy' ||
            b == 'growth_academy' ||
            a == 'emotion_windchime' ||
            b == 'emotion_windchime' ||
            a == 'memory_mailbox' ||
            b == 'memory_mailbox' ||
            a == 'habit_flowerbed' ||
            b == 'habit_flowerbed')) {
      return true;
    }
    const special = {'growth_academy', 'starter_stone'};
    return special.contains(a) && special.contains(b) && a != b;
  }

  static bool _skipVisualCollisionPair(String? a, String b) {
    return skipsVisualCollision(a, b);
  }

  static bool _isValidCandidate({
    required BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (!BuildingFootprint.isVisuallyOnGrowthIsland(
      anchor,
      footprint,
      buildingId: config.id,
    )) {
      return false;
    }
    if (!_isZoneValidCandidate(
      config: config,
      anchor: anchor,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }
    if (_overlapsProtagonistZone(config, anchor, footprint)) {
      return false;
    }
    return !_overlapsAny(
      anchor,
      footprint,
      placed,
      buildingId: config.id,
    );
  }

  static bool _overlapsProtagonistZone(
    BuildingConfig config,
    Offset anchor,
    Offset footprint,
  ) {
    if (config.id == 'harbor_pier' || config.id == 'starter_stone') {
      return false;
    }
    // 只用脚点附近占地判断，避免高大建筑上半身视觉框误伤左右岸合法落点。
    return footPadRect(anchor, footprint)
        .overlaps(MainIslandPlacementZones.protagonistExclusion);
  }

  /// 建筑贴地脚垫：用于小人禁区判定。
  static Rect footPadRect(Offset anchor, Offset footprint) {
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy + footprint.dy * 0.015),
      width: footprint.dx * 0.28,
      height: math.max(0.03, footprint.dy * 0.14),
    );
  }

  static bool _isZoneValidCandidate({
    required BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    Offset? academyAnchor,
  }) {
    if (_violatesLandmarkBand(config, anchor)) {
      return false;
    }
    if (academyAnchor != null &&
        config.id != 'growth_academy' &&
        config.id != 'harbor_pier' &&
        config.id != 'starter_stone' &&
        (anchor - academyAnchor).distance < _academyVisualClearance(config)) {
      return false;
    }
    final rect = occupancyRect(
      anchor,
      footprint,
      buildingId: config.id,
    );
    return !MainIslandPlacementZones.overlapsForbiddenGroundForBuilding(
      rect,
      config.id,
      academyAnchor: academyAnchor,
      anchor: anchor,
      footprint: footprint,
    );
  }

  /// 放大后的学院需要更大的锚点间距，避免视觉体重叠。
  static double _academyVisualClearance(BuildingConfig config) {
    return switch (config.type) {
      'observatory' || 'clocktower' || 'lighthouse' || 'lighthouse_base' => 0.24,
      'house' || 'library' || 'gallery' || 'shed' || 'tent' => 0.15,
      _ => 0.13,
    };
  }

  /// 高塔/天文台等地标：学院侧前方，禁止学院后方与主角前带。
  static bool _violatesLandmarkBand(BuildingConfig config, Offset anchor) {
    final upperLandmark = config.type == 'observatory' ||
        config.type == 'clocktower' ||
        config.type == 'lighthouse' ||
        config.type == 'lighthouse_base';
    if (!upperLandmark) return false;
    final academyY = MainIslandPlacementZones.academyDefaultAnchor.dy;
    if (anchor.dy < academyY + 0.01) return true;
    if (anchor.dy > 0.56) return true;
    if (config.type == 'observatory' && anchor.dx > 0.84) return true;
    return false;
  }

  static Rect occupancyRect(
    Offset anchor,
    Offset footprint, {
    double margin = 0,
    String? buildingId,
  }) {
    final visual = buildingId == null
        ? footprint
        : BuildingFootprint.visualCollisionFootprint(buildingId, footprint);
    final w = visual.dx * 0.90 + margin;
    final h = visual.dy * 0.68 + margin;
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy - visual.dy * 0.34),
      width: w,
      height: h,
    );
  }

  /// 建筑间碰撞盒：按放大后视觉主体计算，避免渲染后互相重叠。
  static Rect collisionRect(
    Offset anchor,
    Offset footprint, {
    double margin = 0,
    String? buildingId,
  }) {
    final visual = buildingId == null
        ? footprint
        : BuildingFootprint.visualCollisionFootprint(buildingId, footprint);
    if (buildingId == 'growth_academy') {
      // 学院主体立柱：几乎全部往天上长，脚点以下留给中前岸建筑。
      return Rect.fromCenter(
        center: Offset(anchor.dx, anchor.dy - visual.dy * 0.66),
        width: visual.dx * 0.82 + margin,
        height: visual.dy * 0.55 + margin,
      );
    }
    if (buildingId == 'harbor_pier') {
      // 栈桥贴水短盒，主要占前缘，不向上吞岛。
      return Rect.fromCenter(
        center: Offset(anchor.dx, anchor.dy + visual.dy * 0.08),
        width: visual.dx * 0.95 + margin,
        height: visual.dy * 0.70 + margin,
      );
    }
    if (_isSlenderLandmarkId(buildingId)) {
      // 高塔：瘦高视觉盒，主要防塔身重叠。
      return Rect.fromCenter(
        center: Offset(anchor.dx, anchor.dy - visual.dy * 0.36),
        width: visual.dx * 0.48 + margin,
        height: visual.dy * 0.58 + margin,
      );
    }
    // 常规建筑：贴地主体，略含立面，避免过高 AABB 误伤邻楼。
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy - visual.dy * 0.12),
      width: visual.dx * 0.62 + margin,
      height: visual.dy * 0.34 + margin,
    );
  }

  static bool _isSlenderLandmarkId(String? buildingId) {
    return buildingId == 'growth_clocktower' ||
        buildingId == 'lighthouse' ||
        buildingId == 'lighthouse_base' ||
        buildingId == 'dream_observatory';
  }

  /// 建筑脚点禁草区：避免小草/草裙画在建筑底部（含视觉放大）。
  static Rect buildingFootGrassExclusion(BuildingSnapshot building) {
    final footprint = BuildingFootprint.visualCollisionFootprint(
      building.definitionId,
      building.size,
    );
    return Rect.fromCenter(
      center: Offset(
        building.anchor.dx,
        building.anchor.dy + footprint.dy * 0.06,
      ),
      width: footprint.dx * 1.22,
      height: footprint.dy * 0.42,
    );
  }

  static List<Rect> buildingFootGrassExclusions(
    Iterable<BuildingSnapshot> buildings,
  ) {
    return [
      for (final building in buildings)
        buildingFootGrassExclusion(building).inflate(0.012),
    ];
  }

  static int _seed(String id) {
    var h = 0;
    for (final c in id.codeUnits) {
      h = 0x1fffffff & (h + c);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= (h >> 6);
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= (h >> 11);
    return 0x1fffffff & (h + ((0x00003fff & h) << 15));
  }
}

class PlacedFootprint {
  PlacedFootprint({
    required this.anchor,
    required this.footprint,
    required this.buildingId,
  })  : rect = IslandBuildingLayout.occupancyRect(
          anchor,
          footprint,
          buildingId: buildingId,
        ),
        collisionRect = IslandBuildingLayout.collisionRect(
          anchor,
          footprint,
          buildingId: buildingId,
        );

  final Offset anchor;
  final Offset footprint;
  final String buildingId;
  final Rect rect;
  final Rect collisionRect;
}
