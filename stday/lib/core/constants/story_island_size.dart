/// 每日成长上限：副岛任务 15；日常入驻用户经验 20。
const storyIslandDailyTaskGrowthCap = 15;
const userDailyMainTaskXpCap = 15;
const storyIslandDailyRoutineGrowthCap = 20;
const userDailyMomentXpCap = 20;
const storyIslandDailyGrowthCap = 15;

/// 单次完成任务的默认成长值（副岛岛屿成长 / 主岛用户经验）。
const storyIslandTaskGrowthDelta = 5;

/// 单条日常入驻岛屿的默认用户经验值（每日累计不超过 [userDailyMomentXpCap]）。
const storyIslandMomentGrowthDelta = 10;

const storyIslandSizeDayTargets = <String, int>{
  'small': 7,
  'medium': 30,
  'large': 90,
};

const storyIslandSizeGrowthTargets = <String, int>{
  'small': 210,
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
    dayHint: '7天左右能到达满级',
    growthTarget: 210,
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

int? storyIslandMomentGrowthDeltaFromPayload(
  Map<String, dynamic> visualPayload,
) {
  final userXp = visualPayload['user_xp_grant_delta'];
  if (userXp is int) return userXp;
  if (userXp is num) return userXp.round();
  final raw = visualPayload['story_island_growth_delta'];
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  return null;
}
