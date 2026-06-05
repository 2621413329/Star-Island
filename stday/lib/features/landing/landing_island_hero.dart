import 'package:flutter/material.dart';

import '../../core/growth/growth_system.dart';
import '../../core/models/mood_island_config.dart';
import '../../design_system/growth_island_widget.dart';

/// 兼容旧引用：首页岛屿请使用 [GrowthIslandWidget]。
@Deprecated('Use GrowthIslandWidget instead')
class LandingIslandHero extends StatelessWidget {
  const LandingIslandHero({
    super.key,
    required this.islandStyle,
    this.stage = const IslandGrowthStage(1),
    this.size = 220,
  });

  final MoodIslandConfig islandStyle;
  final IslandGrowthStage stage;
  final double size;

  static const double islandAspect = GrowthIslandWidget.aspectRatio;

  @override
  Widget build(BuildContext context) {
    return GrowthIslandWidget(
      islandStyle: islandStyle,
      stage: stage,
      compact: true,
      size: Size(size, size / GrowthIslandWidget.aspectRatio),
    );
  }
}
