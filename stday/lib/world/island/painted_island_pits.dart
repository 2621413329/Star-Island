import 'dart:ui';

/// 手绘岛坯上的固定坑位。坐标相对岛图，左上为 0，右下为 1。
class PaintedIslandPits {
  PaintedIslandPits._();

  /// 主角左前方的草地。成长树固定在这里，等级只换树形，不挪坑。
  static const tree = Offset(0.40, 0.62);

  /// 前坪中央。四周是石碑、邮箱、喷泉和身前的广场。
  static const character = Offset(0.50, 0.66);

  static const _buildings = <String, Offset>{
    // 后坡主草地。崖顶那一小块太窄，高建筑都落在下面这层。
    // 15 级钟楼在左，19 级观测台居中，11/16 级灯塔在右。
    'growth_clocktower': Offset(0.32, 0.32),
    'dream_observatory': Offset(0.50, 0.30),
    'lighthouse_base': Offset(0.68, 0.34),
    'lighthouse': Offset(0.68, 0.34),
    // 18 级画廊在左，20 级学院在中，14 级图书在右。
    'memory_gallery': Offset(0.28, 0.46),
    'growth_academy': Offset(0.46, 0.46),
    'library_seed': Offset(0.62, 0.50),
    // 1 级就有的树和石碑靠近人。5 级木屋在左坪，9 级小屋在右坪。
    'record_shed': Offset(0.22, 0.56),
    'growth_tree': tree,
    'starter_stone': Offset(0.52, 0.58),
    'growth_house': Offset(0.74, 0.60),
    'growth_house_lv2': Offset(0.74, 0.60),
    // 7 级邮箱在左前，13 级喷泉和风铃分列人身侧，15 级花圃贴右岸。
    'memory_mailbox': Offset(0.30, 0.64),
    'memory_fountain': Offset(0.58, 0.62),
    'emotion_windchime': Offset(0.66, 0.66),
    'habit_flowerbed': Offset(0.82, 0.56),
    // 12 级广场在身前，17 级帐篷和伙伴广场在前右草地。
    'story_plaza': Offset(0.50, 0.72),
    'quiet_tent': Offset(0.56, 0.72),
    'companion_plaza': Offset(0.66, 0.70),
    // 岛坯左前的木码头，不占草地。
    'harbor_pier': Offset(0.22, 0.90),
  };

  static const _decor = <String, Offset>{
    'grass_01': Offset(0.20, 0.40),
    'grass_02': Offset(0.80, 0.40),
    'grass_03': Offset(0.25, 0.44),
    'grass_04': Offset(0.84, 0.48),
    'grass_05': Offset(0.40, 0.38),
    'grass_06': Offset(0.58, 0.36),
    'grass_07': Offset(0.70, 0.44),
    'grass_08': Offset(0.20, 0.66),
    'grass_09': Offset(0.46, 0.74),
    'flower_01': Offset(0.30, 0.47),
    'flower_02': Offset(0.56, 0.46),
    'flower_03': Offset(0.72, 0.46),
    'flower_04': Offset(0.26, 0.66),
    'flower_05': Offset(0.54, 0.62),
    // 落在左右前滩，离开木屋、花圃和大树的立面。
    'stone_01': Offset(0.12, 0.74),
    'stone_02': Offset(0.90, 0.70),
    'bush_01': Offset(0.32, 0.42),
    'bush_02': Offset(0.56, 0.52),
    'bush_03': Offset(0.80, 0.57),
    // 5、6 级小树先出现在左右岸和前滩。9、13 级大树补满两岸。
    'tree_small_01': Offset(0.25, 0.61),
    'tree_small_02': Offset(0.87, 0.54),
    'tree_small_03': Offset(0.60, 0.26),
    'tree_small_04': Offset(0.63, 0.74),
    'mushroom_01': Offset(0.42, 0.70),
    'wood_01': Offset(0.76, 0.68),
    'mushroom_02': Offset(0.22, 0.70),
    'fallen_leaf_01': Offset(0.58, 0.73),
    'tree_large_01': Offset(0.15, 0.42),
    'tree_large_01b': Offset(0.16, 0.55),
    'tree_large_01c': Offset(0.20, 0.29),
    'flower_field_01': Offset(0.48, 0.74),
    'tree_large_02': Offset(0.84, 0.43),
    'tree_large_02b': Offset(0.85, 0.31),
    'tree_large_02c': Offset(0.74, 0.72),
    'rare_flower_01': Offset(0.60, 0.70),
    // 20 级生命之树在后坡，站在观测台左后方。
    'life_tree_01': Offset(0.40, 0.25),
  };

  static Offset? building(String id) => _buildings[id];

  static Map<String, Offset> get buildings => _buildings;

  static Offset decor(String id) => _decor[id] ?? _scatter(id);

  /// 手绘坑位。没有单独落点的天空装饰返回 null，避免散落到草地中央。
  static Offset? placedDecor(String id) => _decor[id];

  /// 副岛当前建筑：1 级在草地前左，之后每级向中部空地收一步。
  ///
  /// 脚点始终落在草面（大约 y 0.48–0.62），不滑到沙滩或码头上。
  static Offset storyBuilding(int level) {
    final t = (level.clamp(1, 10) - 1) / 9;
    return Offset(0.32 + 0.16 * t, 0.62 - 0.14 * t);
  }

  static String treeSprite(int level) {
    if (level >= 20) return 'decor/life_tree_01.png';
    if (level >= 10) return 'decor/tree_large_01.png';
    if (level >= 3) return 'decor/tree_small_03.png';
    return 'decor/tree_small_01.png';
  }

  static List<StoryIslandThemeProp> themeProps(String? categoryId) {
    return switch (categoryId) {
      // 道具贴左右岸，避开建筑从 (0.32, 0.62) 走到 (0.48, 0.48) 的那条线。
      'work' || 'study' => const [
          StoryIslandThemeProp('decor/stone_01.png', Offset(0.12, 0.70)),
          StoryIslandThemeProp('decor/wood_01.png', Offset(0.88, 0.66)),
        ],
      'health' || 'life' || 'emotion' || 'social' => const [
          StoryIslandThemeProp('decor/flower_01.png', Offset(0.20, 0.60)),
          StoryIslandThemeProp('decor/flower_02.png', Offset(0.80, 0.58)),
          StoryIslandThemeProp('decor/bush_01.png', Offset(0.22, 0.46)),
        ],
      'finance' || 'wealth' => const [
          StoryIslandThemeProp('decor/wood_01.png', Offset(0.22, 0.60)),
          StoryIslandThemeProp('decor/stone_02.png', Offset(0.88, 0.66)),
        ],
      'inspiration' || 'creation' => const [
          StoryIslandThemeProp('decor/flower_field_01.png', Offset(0.22, 0.62)),
          StoryIslandThemeProp('decor/wood_01.png', Offset(0.78, 0.54)),
        ],
      'milestone' || 'achievement' => const [
          StoryIslandThemeProp('decor/stone_01.png', Offset(0.12, 0.70)),
          StoryIslandThemeProp('decor/flower_03.png', Offset(0.88, 0.66)),
        ],
      _ => const [
          StoryIslandThemeProp('decor/flower_01.png', Offset(0.20, 0.58)),
          StoryIslandThemeProp('decor/bush_02.png', Offset(0.78, 0.54)),
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
