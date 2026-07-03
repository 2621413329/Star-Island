/// 每日上限：副岛待办成长 15；副岛日常入驻成长 20；日常入驻用户经验 20。
const storyIslandDailyTaskGrowthCap = 15;
const userDailyMainTaskXpCap = 15;
const storyIslandDailyMomentGrowthCap = 20;
const userDailyMomentXpCap = 20;
const storyIslandDailyRoutineGrowthCap = storyIslandDailyMomentGrowthCap;
const storyIslandDailyGrowthCap = storyIslandDailyTaskGrowthCap;

/// 单次完成待办：副岛 +5 岛屿成长 / 主岛 +5 用户经验。
const storyIslandTaskGrowthDelta = 5;

/// 单条日常入驻：+10 用户经验；副岛另 +10 岛屿成长（各有限额）。
const storyIslandMomentGrowthDelta = 10;

/// 副岛每升一级所需成长值（累计阈值步进）。
const storyIslandGrowthPerLevel = 30;

/// 副岛建筑满级累计成长值（10 级 × 30）。
const storyIslandMaxLevelGrowth = 300;

const storyIslandSizeDayTargets = <String, int>{
  'small': 10,
  'medium': 30,
  'large': 90,
};

const storyIslandSizeGrowthTargets = <String, int>{
  'small': 300,
  'medium': 900,
  'large': 2700,
};

class StoryIslandSizeOption {
  const StoryIslandSizeOption({
    required this.kind,
    required this.title,
    required this.dayHint,
    required this.growthTarget,
  });

  final String kind;
  final String title;
  final String dayHint;
  final int growthTarget;

  String get cardTitle => '$title（$dayHint）';
}

const storyIslandSizeOptions = <StoryIslandSizeOption>[
  StoryIslandSizeOption(
    kind: 'small',
    title: '小岛',
    dayHint: '10天左右能到达满级',
    growthTarget: 300,
  ),
  StoryIslandSizeOption(
    kind: 'medium',
    title: '中岛',
    dayHint: '30天左右到达满级',
    growthTarget: 900,
  ),
  StoryIslandSizeOption(
    kind: 'large',
    title: '大岛',
    dayHint: '90天左右到达满级',
    growthTarget: 2700,
  ),
];

StoryIslandSizeOption storyIslandSizeOptionFor(String kind) {
  return storyIslandSizeOptions.firstWhere(
    (option) => option.kind == kind,
    orElse: () => storyIslandSizeOptions.first,
  );
}

int storyIslandGrowthTargetFor(String sizeKind) {
  return storyIslandSizeGrowthTargets[sizeKind] ??
      storyIslandSizeGrowthTargets['large']!;
}

int? storyIslandUserXpGrantFromPayload(Map<String, dynamic> visualPayload) {
  final userXp = visualPayload['user_xp_grant_delta'];
  if (userXp is int) return userXp;
  if (userXp is num) return userXp.round();
  return null;
}

int? storyIslandGrowthDeltaFromPayload(Map<String, dynamic> visualPayload) {
  final raw = visualPayload['story_island_growth_delta'];
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  return null;
}

/// 兼容旧调用：优先返回用户经验 grant，否则岛屿成长。
int? storyIslandMomentGrowthDeltaFromPayload(
  Map<String, dynamic> visualPayload,
) {
  return storyIslandUserXpGrantFromPayload(visualPayload) ??
      storyIslandGrowthDeltaFromPayload(visualPayload);
}
