/// 岛屿装饰分类与配置。
///
/// 新增装饰时仅需：
/// 1. 在 [assets/images/decor/] 添加图片
/// 2. 在 [DecorConfigs.all] 追加一条 [DecorConfig]
enum DecorCategory {
  grass,
  flower,
  bush,
  tree,
  cloud,
  bird,
  butterfly,
  firefly,
  stone,
  pond,
  special;

  /// 成长缩放权重：影响 `1 + (levelScale - 1) × weight`。
  double get growthWeight => switch (this) {
        DecorCategory.grass => 0.3,
        DecorCategory.flower => 0.4,
        DecorCategory.stone => 0.2,
        DecorCategory.bush => 0.6,
        DecorCategory.tree => 1.0,
        DecorCategory.pond => 0.5,
        DecorCategory.cloud => 0.5,
        DecorCategory.bird => 0.3,
        DecorCategory.butterfly => 0.3,
        DecorCategory.firefly => 0.2,
        DecorCategory.special => 0.8,
      };

  /// 低等级时放大小草/花朵等配饰，避免小岛显得空旷。
  bool get receivesLowLevelFillBoost => switch (this) {
        DecorCategory.grass ||
        DecorCategory.flower ||
        DecorCategory.stone ||
        DecorCategory.bush ||
        DecorCategory.special =>
          true,
        _ => false,
      };

  /// 渲染层级（数值越大越靠上）。
  int get layerPriority => switch (this) {
        DecorCategory.grass => 100,
        DecorCategory.flower => 200,
        DecorCategory.stone => 300,
        DecorCategory.bush => 400,
        DecorCategory.tree => 500,
        DecorCategory.pond => 500,
        DecorCategory.special => 500,
        DecorCategory.bird => 700,
        DecorCategory.cloud => 800,
        DecorCategory.butterfly => 700,
        DecorCategory.firefly => 900,
      };
}

class DecorConfig {
  const DecorConfig({
    required this.id,
    required this.image,
    required this.category,
    required this.unlockLevel,
    required this.x,
    required this.y,

    /// 相对分类基准高度的目标视觉系数（配合 [DecorScaleResolver.spriteFillRatios] 补偿 800×800 留白）。
    this.scale = 1.0,
    this.randomScale = 1.0,
    this.animated = false,
    this.loop = false,
    this.animationType,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });

  final String id;
  final String image;
  final DecorCategory category;
  final int unlockLevel;
  final double x;
  final double y;
  final double scale;

  /// 首次实例化时写入的自然随机缩放（0.92–1.08）。
  final double randomScale;
  final bool animated;
  final bool loop;
  final String? animationType;
  final double rotation;
  final double opacity;

  String get assetPath => 'decor/$image';

  DecorConfig copyWith({
    double? randomScale,
  }) {
    return DecorConfig(
      id: id,
      image: image,
      category: category,
      unlockLevel: unlockLevel,
      x: x,
      y: y,
      scale: scale,
      randomScale: randomScale ?? this.randomScale,
      animated: animated,
      loop: loop,
      animationType: animationType,
      rotation: rotation,
      opacity: opacity,
    );
  }
}

/// 全部装饰配置（LV1–LV20）。
class DecorConfigs {
  DecorConfigs._();

  static const all = <DecorConfig>[
    // LV1 — 草地（随风摆动；默认落点避开小人脚边）
    DecorConfig(
      id: 'grass_01',
      image: 'grass_01.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.26,
      y: 0.56,
      scale: 0.90,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'grass_02',
      image: 'grass_02.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.74,
      y: 0.56,
      scale: 1.00,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'grass_03',
      image: 'grass_03.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.22,
      y: 0.52,
      scale: 0.85,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'grass_04',
      image: 'grass_04.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.78,
      y: 0.52,
      scale: 0.78,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'grass_05',
      image: 'grass_01.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.28,
      y: 0.50,
      scale: 0.72,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'grass_06',
      image: 'grass_02.png',
      category: DecorCategory.grass,
      unlockLevel: 1,
      x: 0.72,
      y: 0.50,
      scale: 0.82,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV2 — 花朵
    DecorConfig(
      id: 'flower_01',
      image: 'flower_01.png',
      category: DecorCategory.flower,
      unlockLevel: 2,
      x: 0.24,
      y: 0.54,
      scale: 0.95,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'flower_02',
      image: 'flower_02.png',
      category: DecorCategory.flower,
      unlockLevel: 2,
      x: 0.76,
      y: 0.54,
      scale: 1.00,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'flower_03',
      image: 'flower_03.png',
      category: DecorCategory.flower,
      unlockLevel: 2,
      x: 0.80,
      y: 0.50,
      scale: 0.90,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV3 — 更多小草
    DecorConfig(
      id: 'grass_07',
      image: 'grass_04.png',
      category: DecorCategory.grass,
      unlockLevel: 3,
      x: 0.70,
      y: 0.54,
      scale: 0.75,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'grass_08',
      image: 'grass_03.png',
      category: DecorCategory.grass,
      unlockLevel: 3,
      x: 0.30,
      y: 0.52,
      scale: 0.82,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV4 — 更多小花
    DecorConfig(
      id: 'flower_04',
      image: 'flower_01.png',
      category: DecorCategory.flower,
      unlockLevel: 4,
      x: 0.22,
      y: 0.56,
      scale: 0.88,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'flower_05',
      image: 'flower_02.png',
      category: DecorCategory.flower,
      unlockLevel: 4,
      x: 0.78,
      y: 0.54,
      scale: 0.86,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV3 — 石头（保留配置，不参与花草鸟云解锁展示）
    DecorConfig(
      id: 'stone_01',
      image: 'stone_01.png',
      category: DecorCategory.stone,
      unlockLevel: 3,
      x: 0.26,
      y: 0.58,
      scale: 0.85,
    ),
    DecorConfig(
      id: 'stone_02',
      image: 'stone_02.png',
      category: DecorCategory.stone,
      unlockLevel: 3,
      x: 0.76,
      y: 0.57,
      scale: 0.90,
    ),

    // LV4 — 灌木（保留配置，不参与花草鸟云解锁展示）
    DecorConfig(
      id: 'bush_01',
      image: 'bush_01.png',
      category: DecorCategory.bush,
      unlockLevel: 4,
      x: 0.34,
      y: 0.56,
      scale: 1.00,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'bush_02',
      image: 'bush_02.png',
      category: DecorCategory.bush,
      unlockLevel: 4,
      x: 0.64,
      y: 0.55,
      scale: 0.95,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'bush_03',
      image: 'bush_03.png',
      category: DecorCategory.bush,
      unlockLevel: 4,
      x: 0.80,
      y: 0.50,
      scale: 0.78,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV5 — 小树（保留配置，不参与花草鸟云解锁展示）
    DecorConfig(
      id: 'tree_small_01',
      image: 'tree_small_01.png',
      category: DecorCategory.tree,
      unlockLevel: 5,
      x: 0.18,
      y: 0.56,
      scale: 1.12,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'grass_09',
      image: 'grass_02.png',
      category: DecorCategory.grass,
      unlockLevel: 5,
      x: 0.78,
      y: 0.58,
      scale: 0.78,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV6 — 小树
    DecorConfig(
      id: 'tree_small_02',
      image: 'tree_small_02.png',
      category: DecorCategory.tree,
      unlockLevel: 6,
      x: 0.14,
      y: 0.54,
      scale: 1.08,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'tree_small_03',
      image: 'tree_small_03.png',
      category: DecorCategory.tree,
      unlockLevel: 6,
      x: 0.86,
      y: 0.54,
      scale: 1.12,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'tree_small_04',
      image: 'tree_small_04.png',
      category: DecorCategory.tree,
      unlockLevel: 6,
      x: 0.80,
      y: 0.46,
      scale: 1.05,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV7 — 特殊植物
    DecorConfig(
      id: 'mushroom_01',
      image: 'mushroom_01.png',
      category: DecorCategory.special,
      unlockLevel: 7,
      x: 0.24,
      y: 0.54,
      scale: 0.55,
    ),
    DecorConfig(
      id: 'wood_01',
      image: 'wood_01.png',
      category: DecorCategory.special,
      unlockLevel: 7,
      x: 0.76,
      y: 0.54,
      scale: 0.70,
    ),

    // LV8 — 蝴蝶
    DecorConfig(
      id: 'butterfly_01',
      image: 'butterfly_01.png',
      category: DecorCategory.butterfly,
      unlockLevel: 8,
      x: 0.50,
      y: 0.48,
      scale: 0.45,
      animated: true,
      loop: true,
      animationType: 'butterfly_fly',
    ),
    DecorConfig(
      id: 'mushroom_02',
      image: 'mushroom_02.png',
      category: DecorCategory.special,
      unlockLevel: 8,
      x: 0.22,
      y: 0.52,
      scale: 0.50,
    ),
    DecorConfig(
      id: 'fallen_leaf_01',
      image: 'fallen_leaf_01.png',
      category: DecorCategory.special,
      unlockLevel: 8,
      x: 0.78,
      y: 0.52,
      scale: 0.35,
    ),

    // LV9 — 大树环左岸/前缘（避开学院）
    DecorConfig(
      id: 'tree_large_01',
      image: 'tree_large_01.png',
      category: DecorCategory.tree,
      unlockLevel: 9,
      x: 0.13,
      y: 0.57,
      scale: 0.78,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'tree_large_01b',
      image: 'tree_large_01.png',
      category: DecorCategory.tree,
      unlockLevel: 9,
      x: 0.27,
      y: 0.46,
      scale: 0.72,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'tree_large_01c',
      image: 'tree_large_01.png',
      category: DecorCategory.tree,
      unlockLevel: 9,
      x: 0.30,
      y: 0.62,
      scale: 0.70,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV10 — 云朵
    DecorConfig(
      id: 'cloud_01',
      image: 'cloud_01.png',
      category: DecorCategory.cloud,
      unlockLevel: 10,
      x: 0.15,
      y: 0.22,
      scale: 0.90,
      animated: true,
      loop: true,
      animationType: 'cloud_float',
    ),
    DecorConfig(
      id: 'cloud_02',
      image: 'cloud_02.png',
      category: DecorCategory.cloud,
      unlockLevel: 10,
      x: 0.40,
      y: 0.18,
      scale: 0.78,
      animated: true,
      loop: true,
      animationType: 'cloud_float',
    ),
    DecorConfig(
      id: 'cloud_03',
      image: 'cloud_03.png',
      category: DecorCategory.cloud,
      unlockLevel: 10,
      x: 0.65,
      y: 0.20,
      scale: 0.85,
      animated: true,
      loop: true,
      animationType: 'cloud_float',
    ),

    // LV11 — 花田
    DecorConfig(
      id: 'flower_field_01',
      image: 'flower_field_01.png',
      category: DecorCategory.flower,
      unlockLevel: 11,
      x: 0.50,
      y: 0.58,
      scale: 0.82,
    ),

    // LV12 — 鸟类
    DecorConfig(
      id: 'bird_01',
      image: 'bird_01.png',
      category: DecorCategory.bird,
      unlockLevel: 12,
      x: 0.50,
      y: 0.42,
      scale: 0.65,
      animated: true,
      loop: true,
      animationType: 'bird_fly',
    ),

    // LV13 — 大树环右岸/前缘（避开学院）
    DecorConfig(
      id: 'tree_large_02',
      image: 'tree_large_02.png',
      category: DecorCategory.tree,
      unlockLevel: 13,
      x: 0.87,
      y: 0.57,
      scale: 0.80,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'tree_large_02b',
      image: 'tree_large_02.png',
      category: DecorCategory.tree,
      unlockLevel: 13,
      x: 0.73,
      y: 0.46,
      scale: 0.74,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
    DecorConfig(
      id: 'tree_large_02c',
      image: 'tree_large_02.png',
      category: DecorCategory.tree,
      unlockLevel: 13,
      x: 0.70,
      y: 0.62,
      scale: 0.72,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),

    // LV14 — 池塘（静心池塘/温泉视觉）已停用主岛显示，配置保留供素材与目录。
    DecorConfig(
      id: 'pond_01',
      image: 'pond_01.png',
      category: DecorCategory.pond,
      unlockLevel: 14,
      x: 0.26,
      y: 0.66,
      scale: 1.28,
    ),

    // LV15 — 鸟类 + 云
    DecorConfig(
      id: 'bird_02',
      image: 'bird_02.png',
      category: DecorCategory.bird,
      unlockLevel: 15,
      x: 0.38,
      y: 0.38,
      scale: 0.60,
      animated: true,
      loop: true,
      animationType: 'bird_fly',
    ),
    DecorConfig(
      id: 'bird_03',
      image: 'bird_03.png',
      category: DecorCategory.bird,
      unlockLevel: 15,
      x: 0.62,
      y: 0.40,
      scale: 0.62,
      animated: true,
      loop: true,
      animationType: 'bird_fly',
    ),
    DecorConfig(
      id: 'cloud_04',
      image: 'cloud_04.png',
      category: DecorCategory.cloud,
      unlockLevel: 15,
      x: 0.82,
      y: 0.16,
      scale: 0.80,
      animated: true,
      loop: true,
      animationType: 'cloud_float',
    ),

    // LV16 — 萤火虫
    DecorConfig(
      id: 'firefly_01',
      image: 'firefly_01.png',
      category: DecorCategory.firefly,
      unlockLevel: 16,
      x: 0.55,
      y: 0.50,
      scale: 0.50,
      animated: true,
      loop: true,
      animationType: 'firefly',
    ),

    // LV17 — 稀有花
    DecorConfig(
      id: 'rare_flower_01',
      image: 'rare_flower_01.png',
      category: DecorCategory.flower,
      unlockLevel: 17,
      x: 0.76,
      y: 0.54,
      scale: 1.05,
    ),

    // LV18 — 彩虹云
    DecorConfig(
      id: 'rainbow_cloud_01',
      image: 'rainbow_cloud_01.png',
      category: DecorCategory.cloud,
      unlockLevel: 18,
      x: 0.28,
      y: 0.14,
      scale: 0.95,
      animated: true,
      loop: true,
      animationType: 'cloud_float',
    ),

    // LV19 — 海鸥群
    DecorConfig(
      id: 'seagull_group_01',
      image: 'seagull_group_01.png',
      category: DecorCategory.bird,
      unlockLevel: 19,
      x: 0.50,
      y: 0.35,
      scale: 0.80,
      animated: true,
      loop: true,
      animationType: 'bird_fly',
    ),

    // LV20 — 生命之树（中带左内岸；前缘留给主角与 01c/02c）
    DecorConfig(
      id: 'life_tree_01',
      image: 'life_tree_01.png',
      category: DecorCategory.tree,
      unlockLevel: 20,
      x: 0.40,
      y: 0.46,
      scale: 0.84,
      animated: true,
      loop: true,
      animationType: 'grass_sway',
    ),
  ];

  /// 主岛不再渲染的地面装饰（如温泉/池塘）。
  static const _hiddenMainIslandDecorIds = {'pond_01'};

  /// 按等级过滤已解锁装饰。
  static List<DecorConfig> unlockedAt(int userLevel) =>
      all.where((d) => d.unlockLevel <= userLevel).toList(growable: false);

  static bool isNatureDecor(DecorConfig config) {
    return switch (config.category) {
      DecorCategory.grass ||
      DecorCategory.flower ||
      DecorCategory.bird ||
      DecorCategory.cloud =>
        true,
      _ => false,
    };
  }

  /// 主岛地面装饰：草/花/灌木/树/石/池/特殊物件（参与放置与碰撞）。
  static bool isMainIslandGroundDecor(DecorConfig config) {
    return switch (config.category) {
      DecorCategory.grass ||
      DecorCategory.flower ||
      DecorCategory.bush ||
      DecorCategory.tree ||
      DecorCategory.stone ||
      DecorCategory.pond ||
      DecorCategory.special =>
        true,
      _ => false,
    };
  }

  /// 主岛天空装饰：鸟/云/蝶/萤火虫（不参与地面碰撞）。
  static bool isMainIslandSkyDecor(DecorConfig config) {
    return switch (config.category) {
      DecorCategory.bird ||
      DecorCategory.cloud ||
      DecorCategory.butterfly ||
      DecorCategory.firefly =>
        true,
      _ => false,
    };
  }

  /// 仅花草鸟云：用于旧版自然元素统计（等级页已改用 [IslandUnlockCatalog]）。
  static List<DecorConfig> unlockedNatureAt(int userLevel) => all
      .where((d) => d.unlockLevel <= userLevel && isNatureDecor(d))
      .toList(growable: false);

  /// 主岛完整装饰集：地面 + 天空（[DecorManager] / 草坪障碍用）。
  static List<DecorConfig> unlockedMainIslandAt(int userLevel) => all
      .where(
        (d) =>
            d.unlockLevel <= userLevel &&
            !_hiddenMainIslandDecorIds.contains(d.id) &&
            (isMainIslandGroundDecor(d) || isMainIslandSkyDecor(d)),
      )
      .toList(growable: false);

  /// 获取指定等级新解锁的装饰（用于预览）。
  static DecorConfig? primaryForLevel(int level) {
    final exact = all.where((d) => d.unlockLevel == level);
    if (exact.isNotEmpty) return exact.first;
    final lower = all.where((d) => d.unlockLevel <= level).toList();
    return lower.isEmpty ? null : lower.last;
  }
}
