/// 故事岛屿规模与成长值上限计算。
///
/// 每日成长上限：任务 10 + 日常 20 = 30。
const storyIslandDailyTaskGrowthCap = 10;
const storyIslandDailyRoutineGrowthCap = 20;
const storyIslandDailyGrowthCap = 30;

/// 单次完成任务的默认成长值（每日累计不超过 [storyIslandDailyTaskGrowthCap]）。
const storyIslandTaskGrowthDelta = 5;

/// 单条日常写入岛屿的默认成长值（每日累计不超过 [storyIslandDailyRoutineGrowthCap]）。
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
      storyIslandSizeGrowthTargets['small']!;
}
