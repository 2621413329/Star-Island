import 'dart:ui';

/// 手绘岛坯上的固定坑位。坐标相对岛图，左上为 0，右下为 1。
class PaintedIslandPits {
  PaintedIslandPits._();

  /// 左中草地，给前坪留出站人的空地。
  static const tree = Offset(0.36, 0.46);

  /// 前坪中央，四周是矮的石碑、广场和喷泉。
  static const character = Offset(0.50, 0.66);

  static const _buildings = <String, Offset>{
    // 后坡顶只有一小块平地，只放一座高建筑。
    'dream_observatory': Offset(0.52, 0.14),
    // 主草坪后沿：钟楼在左，学院在中，灯塔在右。
    'growth_clocktower': Offset(0.28, 0.34),
    'growth_academy': Offset(0.50, 0.38),
    'lighthouse_base': Offset(0.76, 0.32),
    'lighthouse': Offset(0.76, 0.32),
    // 左岸记忆区。
    'memory_gallery': Offset(0.18, 0.46),
    'record_shed': Offset(0.22, 0.56),
    'memory_mailbox': Offset(0.32, 0.56),
    // 中部生活区。树和石碑靠后，人站前坪。
    'growth_tree': tree,
    'starter_stone': Offset(0.52, 0.54),
    'story_plaza': Offset(0.36, 0.62),
    'memory_fountain': Offset(0.64, 0.64),
    'companion_plaza': Offset(0.56, 0.74),
    // 右岸：图书和小屋，情绪小物在屋前。
    'library_seed': Offset(0.64, 0.44),
    'growth_house': Offset(0.82, 0.50),
    'growth_house_lv2': Offset(0.82, 0.50),
    'emotion_windchime': Offset(0.74, 0.56),
    'habit_flowerbed': Offset(0.84, 0.60),
    'quiet_tent': Offset(0.72, 0.72),
    // 岛坯左前的木码头，不占草地。
    'harbor_pier': Offset(0.26, 0.88),
  };

  static const _decor = <String, Offset>{
    'grass_01': Offset(0.16, 0.38),
    'grass_02': Offset(0.86, 0.40),
    'grass_03': Offset(0.22, 0.40),
    'grass_04': Offset(0.86, 0.56),
    'grass_05': Offset(0.42, 0.34),
    'grass_06': Offset(0.60, 0.34),
    'grass_07': Offset(0.70, 0.40),
    'grass_08': Offset(0.16, 0.52),
    'grass_09': Offset(0.44, 0.70),
    'flower_01': Offset(0.44, 0.42),
    'flower_02': Offset(0.58, 0.42),
    'flower_03': Offset(0.70, 0.48),
    'flower_04': Offset(0.40, 0.58),
    'flower_05': Offset(0.58, 0.60),
    'stone_01': Offset(0.20, 0.40),
    'stone_02': Offset(0.84, 0.42),
    'bush_01': Offset(0.24, 0.48),
    'bush_02': Offset(0.58, 0.50),
    'bush_03': Offset(0.78, 0.44),
    'tree_small_01': Offset(0.12, 0.36),
    'tree_small_02': Offset(0.20, 0.24),
    'tree_small_03': Offset(0.80, 0.24),
    'tree_small_04': Offset(0.88, 0.36),
    'mushroom_01': Offset(0.42, 0.68),
    'wood_01': Offset(0.78, 0.66),
    'mushroom_02': Offset(0.26, 0.52),
    'fallen_leaf_01': Offset(0.60, 0.52),
    'tree_large_01': Offset(0.10, 0.50),
    'tree_large_01b': Offset(0.13, 0.32),
    'tree_large_01c': Offset(0.12, 0.68),
    'flower_field_01': Offset(0.46, 0.72),
    'tree_large_02': Offset(0.90, 0.50),
    'tree_large_02b': Offset(0.87, 0.30),
    'tree_large_02c': Offset(0.88, 0.68),
    'rare_flower_01': Offset(0.60, 0.72),
    'life_tree_01': Offset(0.16, 0.26),
  };

  static Offset? building(String id) => _buildings[id];

  static Map<String, Offset> get buildings => _buildings;

  static Offset decor(String id) => _decor[id] ?? _scatter(id);

  /// 副岛当前建筑：1 级在前缘，10 级收到草地中心。
  static Offset storyBuilding(int level) {
    final t = (level.clamp(1, 10) - 1) / 9;
    return Offset(0.30 + 0.20 * t, 0.64 - 0.18 * t);
  }

  static String treeSprite(int level) {
    if (level >= 20) return 'decor/life_tree_01.png';
    if (level >= 10) return 'decor/tree_large_01.png';
    if (level >= 3) return 'decor/tree_small_03.png';
    return 'decor/tree_small_01.png';
  }

  static List<StoryIslandThemeProp> themeProps(String? categoryId) {
    return switch (categoryId) {
      'work' || 'study' => const [
          StoryIslandThemeProp('decor/stone_01.png', Offset(0.30, 0.60)),
          StoryIslandThemeProp('decor/wood_01.png', Offset(0.68, 0.58)),
        ],
      'health' || 'life' || 'emotion' || 'social' => const [
          StoryIslandThemeProp('decor/flower_01.png', Offset(0.30, 0.62)),
          StoryIslandThemeProp('decor/flower_02.png', Offset(0.68, 0.60)),
          StoryIslandThemeProp('decor/bush_01.png', Offset(0.36, 0.46)),
        ],
      'finance' || 'wealth' => const [
          StoryIslandThemeProp('decor/wood_01.png', Offset(0.32, 0.62)),
          StoryIslandThemeProp('decor/stone_02.png', Offset(0.66, 0.58)),
        ],
      'inspiration' || 'creation' => const [
          StoryIslandThemeProp('decor/flower_field_01.png', Offset(0.34, 0.64)),
          StoryIslandThemeProp('decor/wood_01.png', Offset(0.68, 0.56)),
        ],
      'milestone' || 'achievement' => const [
          StoryIslandThemeProp('decor/stone_01.png', Offset(0.32, 0.60)),
          StoryIslandThemeProp('decor/flower_03.png', Offset(0.66, 0.58)),
        ],
      _ => const [
          StoryIslandThemeProp('decor/flower_01.png', Offset(0.34, 0.60)),
          StoryIslandThemeProp('decor/bush_02.png', Offset(0.66, 0.56)),
        ],
    };
  }

  static Offset _scatter(String id) {
    final hash = id.hashCode.abs();
    final x = 0.28 + (hash % 47) / 47 * 0.44;
    final y = 0.36 + ((hash ~/ 47) % 29) / 29 * 0.26;
    return Offset(x, y);
  }
}

class StoryIslandThemeProp {
  const StoryIslandThemeProp(this.asset, this.plate);

  /// 相对 `assets/images/` 的路径。
  final String asset;
  final Offset plate;
}
