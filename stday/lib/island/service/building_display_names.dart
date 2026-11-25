/// 成长岛建筑中文展示名。
class BuildingDisplayNames {
  BuildingDisplayNames._();

  static const _byId = <String, String>{
    'starter_stone': '起始石碑',
    'record_shed': '记忆棚屋',
    'memory_mailbox': '记忆邮箱',
    'growth_house': '成长小屋',
    'growth_house_lv2': '成长小屋·扩建',
    'habit_flowerbed': '习惯花园',
    'emotion_windchime': '情绪风铃',
    'quiet_tent': '静心帐篷',
    'memory_fountain': '记忆喷泉',
    'growth_clocktower': '成长钟塔',
    'library_seed': '图书种子',
    'lighthouse_base': '灯塔基座',
    'lighthouse': '温暖灯塔',
    'story_plaza': '故事广场',
    'harbor_pier': '港口栈桥',
    'companion_plaza': '伙伴广场',
    'memory_gallery': '记忆画廊',
    'dream_observatory': '梦想天文台',
    'growth_academy': '成长学院',
    'growth_lighthouse': '灯塔',
    'growth_library': '图书馆',
    'growth_plaza': '记忆广场',
    'growth_tree': '成长树',
    'prop_sun_beach': '阳光沙滩',
    'prop_green_rest': '绿茵小憩',
    'prop_zen_stones': '静心石庭',
    'prop_warm_lamp': '暖光灯塔',
    'prop_lava_vent': '火山气孔',
  };

  static final _latin = RegExp(r'[A-Za-z]');

  static String nameFor(String id, {String? fallback}) {
    return labelFor(id, displayName: fallback);
  }

  /// 点击气泡用：已登记的建筑一律用中文名，忽略英文配置名。
  static String labelFor(String id, {String? displayName}) {
    final known = _byId[id];
    if (known != null && known.isNotEmpty) return known;
    final raw = displayName?.trim();
    if (raw != null && raw.isNotEmpty && !_latin.hasMatch(raw)) return raw;
    return '小岛建筑';
  }
}
