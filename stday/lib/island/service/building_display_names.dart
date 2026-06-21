/// 成长岛建筑中文展示名。
class BuildingDisplayNames {
  BuildingDisplayNames._();

  static const _byId = <String, String>{
    'starter_stone': '启程石',
    'record_shed': '记录小屋',
    'memory_mailbox': '记忆信箱',
    'growth_house': '成长小屋',
    'growth_house_lv2': '成长小屋·二阶',
    'habit_flowerbed': '习惯花圃',
    'emotion_windchime': '心情风铃',
    'quiet_tent': '静思帐篷',
    'memory_fountain': '记忆喷泉',
    'growth_clocktower': '成长钟楼',
    'library_seed': '日常图书馆',
    'lighthouse_base': '灯塔基座',
    'lighthouse': '成长灯塔',
    'story_plaza': '日常广场',
    'harbor_pier': '港口栈桥',
    'companion_plaza': '伙伴广场',
    'memory_gallery': '记忆画廊',
    'dream_observatory': '梦想观测台',
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

  static String nameFor(String id, {String? fallback}) {
    return _byId[id] ?? fallback ?? '小岛建筑';
  }
}
