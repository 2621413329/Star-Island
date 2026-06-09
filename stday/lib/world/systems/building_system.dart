import 'dart:ui';

import '../engine/growth_event.dart';
import '../engine/world_state.dart';

class BuildingDefinition {
  const BuildingDefinition({
    required this.id,
    required this.label,
    required this.anchor,
  });

  final String id;
  final String label;
  final Offset anchor;
}

/// 岛内心情配饰（Phase 2 将由 [BuildingResolver] 替代）。
@Deprecated('Phase 2: use BuildingResolver with building_config.dart')
class BuildingSystem {
  static const _moodProps = <String, BuildingDefinition>{
    'happy': BuildingDefinition(
      id: 'prop_sun_beach',
      label: '阳光沙滩',
      anchor: Offset(0.5, 0.5),
    ),
    'calm': BuildingDefinition(
      id: 'prop_green_rest',
      label: '绿茵小憩',
      anchor: Offset(0.48, 0.52),
    ),
    'thinking': BuildingDefinition(
      id: 'prop_zen_stones',
      label: '静心石庭',
      anchor: Offset(0.5, 0.51),
    ),
    'sad': BuildingDefinition(
      id: 'prop_warm_lamp',
      label: '暖光灯塔',
      anchor: Offset(0.52, 0.53),
    ),
    'angry': BuildingDefinition(
      id: 'prop_lava_vent',
      label: '火山气孔',
      anchor: Offset(0.5, 0.5),
    ),
  };

  static const _growthTree = BuildingDefinition(
    id: 'growth_tree',
    label: '成长树',
    anchor: Offset(0.5, 0.43),
  );

  List<BuildingSnapshot> resolveForIsland({
    required String moodId,
    required int storyCount,
  }) {
    final prop = _moodProps[moodId] ?? _moodProps['calm']!;
    final out = <BuildingSnapshot>[
      BuildingSnapshot(
        definitionId: prop.id,
        level: 1,
        anchor: prop.anchor,
      ),
    ];
    if (storyCount >= 4) {
      out.add(BuildingSnapshot(
        definitionId: _growthTree.id,
        level: (storyCount ~/ 3).clamp(1, 3),
        anchor: _growthTree.anchor,
      ));
    }
    return out;
  }

  /// 兼容旧调用：按岛屿心情生成配饰，不再固定摆四个抽象建筑。
  List<BuildingSnapshot> resolve(
    UserGrowthProfile profile, {
    String moodId = 'calm',
  }) {
    final count = profile.cumulativeCounts.values.fold<int>(0, (a, b) => a + b);
    return resolveForIsland(moodId: moodId, storyCount: count);
  }

  BuildingDefinition? find(String id) {
    for (final d in _moodProps.values) {
      if (d.id == id) return d;
    }
    if (id == _growthTree.id) return _growthTree;
    return null;
  }
}
