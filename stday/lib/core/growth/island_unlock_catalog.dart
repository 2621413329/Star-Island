import '../../island/config/growth_island_configs.dart';
import '../../island/decor/decor_config.dart';

/// 岛屿装饰 / 建筑解锁目录（Lv.1–20）。
class IslandUnlockItem {
  const IslandUnlockItem({
    required this.level,
    required this.name,
    required this.assetPath,
    required this.kind,
  });

  final int level;
  final String name;
  final String assetPath;
  final IslandUnlockKind kind;
}

enum IslandUnlockKind { decor, building }

class IslandUnlockLevelGroup {
  const IslandUnlockLevelGroup({
    required this.level,
    required this.items,
  });

  final int level;
  final List<IslandUnlockItem> items;

  String get summaryLabel {
    if (items.isEmpty) return '暂无新内容';
    if (items.length == 1) return items.first.name;
    return items.map((item) => item.name).join('、');
  }
}

class IslandUnlockCatalog {
  IslandUnlockCatalog._();

  static const _buildingDisplayNames = <String, String>{
    'starter_stone': '起始石碑',
    'record_shed': '记忆棚屋',
    'memory_mailbox': '记忆邮箱',
    'growth_house': '成长小屋',
    'growth_house_lv2': '成长小屋·扩建',
    'harbor_pier': '港口栈桥',
    'emotion_windchime': '情绪风铃',
    'habit_flowerbed': '习惯花圃',
    'quiet_tent': '静心帐篷',
    'lighthouse_base': '灯塔基座',
    'story_plaza': '故事广场',
    'memory_fountain': '记忆喷泉',
    'library_seed': '图书种子',
    'growth_clocktower': '成长钟塔',
    'lighthouse': '温暖灯塔',
    'companion_plaza': '陪伴广场',
    'memory_gallery': '记忆画廊',
    'dream_observatory': '梦想天文台',
    'growth_academy': '成长学院',
  };

  static const decorDisplayNames = <String, String>{
    'grass_01': '春日矮草',
    'grass_02': '软绒草丛',
    'grass_03': '岸边嫩草',
    'grass_04': '点缀草叶',
    'flower_01': '野趣小花',
    'flower_02': '晨露花芽',
    'flower_03': '点缀花蕊',
    'stone_01': '圆润卧石',
    'stone_02': '滨海怪石',
    'bush_01': '低垂灌木',
    'bush_02': '团簇绿篱',
    'bush_03': '丛生灌丛',
    'tree_small_01': '萌芽小树',
    'tree_small_02': '风向矮树',
    'tree_small_03': '夕照树影',
    'tree_small_04': '幼苗小树',
    'mushroom_01': '森林蘑菇',
    'mushroom_02': '幽光蘑菇',
    'wood_01': '自然原木',
    'butterfly_01': '翩跹蝴蝶',
    'fallen_leaf_01': '飘落叶片',
    'tree_large_01': '广荫大树',
    'cloud_01': '轻柔云朵',
    'cloud_02': '薄雾云絮',
    'cloud_03': '远处云团',
    'flower_field_01': '缤纷花田',
    'bird_01': '岛畔飞鸟',
    'tree_large_02': '古树参天',
    'pond_01': '静心池塘',
    'bird_02': '掠空轻鸟',
    'bird_03': '双鸟和鸣',
    'cloud_04': '远空薄云',
    'firefly_01': '夜游萤火',
    'rare_flower_01': '稀有奇花',
    'rainbow_cloud_01': '彩虹云霭',
    'seagull_group_01': '海鸥群舞',
    'life_tree_01': '生命之树',
  };

  static String decorName(DecorConfig config) =>
      decorDisplayNames[config.id] ?? config.id;

  static String buildingName(String buildingId, {String? fallback}) =>
      _buildingDisplayNames[buildingId] ?? fallback ?? buildingId;

  static List<IslandUnlockLevelGroup> allLevelGroups() {
    return [
      for (var level = 1; level <= 20; level++)
        IslandUnlockLevelGroup(level: level, items: itemsAtLevel(level)),
    ];
  }

  static List<IslandUnlockItem> itemsAtLevel(int level) {
    final decorItems = DecorConfigs.all
        .where((config) => config.unlockLevel == level)
        .map(
          (config) => IslandUnlockItem(
            level: level,
            name: decorName(config),
            assetPath: 'assets/images/${config.assetPath}',
            kind: IslandUnlockKind.decor,
          ),
        );
    final buildingItems = GrowthIslandConfigs.buildings
        .where((config) => config.unlockLevel == level)
        .map(
          (config) => IslandUnlockItem(
            level: level,
            name: buildingName(config.id, fallback: config.name),
            assetPath: 'assets/images/${config.sprite}',
            kind: IslandUnlockKind.building,
          ),
        );
    return [...decorItems, ...buildingItems].toList(growable: false);
  }

  /// 当前等级新解锁内容的摘要文案（用于首页等）。
  static String unlockSummaryForLevel(int level) {
    final group = IslandUnlockLevelGroup(
      level: level,
      items: itemsAtLevel(level),
    );
    if (group.items.isEmpty) return '';
    return 'Lv.$level 解锁 ${group.summaryLabel}';
  }
}
