import 'dart:ui';

import '../../island/building/building_depth_scale.dart';
import '../../island/building/building_sprite_metrics.dart';

/// 主岛建筑在岛坯上的立面比例，以及和树木之间的遮挡判定。
///
/// 坑位写在 [PaintedIslandPits]，已经按草地轮廓排开。详情页不再把它们
/// 挤出草地。这里的矩形和实际画上去的不透明立面一致。
class DetailBuildingSpread {
  DetailBuildingSpread._();

  /// 碰撞盒比立面略收一点，留下树冠和屋脚可以轻轻叠上的余量。
  static const bodyScale = 0.96;

  static const plateAspect = 958 / 743;

  /// 画布高度占岛坯高度的比例。灯塔最高，广场最矮。
  static double roleFor(String id) {
    return switch (id) {
      'lighthouse' || 'lighthouse_base' => 0.18,
      'growth_academy' => 0.17,
      'growth_clocktower' => 0.16,
      'dream_observatory' || 'growth_house_lv2' => 0.15,
      'growth_house' || 'library_seed' => 0.14,
      'growth_tree' || 'memory_gallery' => 0.13,
      'record_shed' || 'emotion_windchime' => 0.12,
      'quiet_tent' => 0.11,
      'memory_fountain' || 'harbor_pier' => 0.10,
      'memory_mailbox' => 0.13,
      'habit_flowerbed' => 0.09,
      'starter_stone' || 'story_plaza' || 'companion_plaza' => 0.08,
      _ => 0.12,
    };
  }

  /// 树冠高度占岛坯高度的比例。小树矮于房子，生命之树接近钟楼。
  static double treeHeightFactor(String id) {
    if (id == 'life_tree_01') return 0.11;
    if (id.startsWith('tree_large')) return 0.095;
    return 0.075;
  }

  /// 坑位已经按岛形排好，放大岛坯时不再推移。
  static Offset place(String id, Offset pit, double plateScale) => pit;

  /// 不透明立面在岛坯上的范围。底边贴着脚点。
  static Rect contentRect(String id, Offset anchor, {double pad = 0.008}) {
    final depth = BuildingDepthScale.forAnchorDy(anchor.dy);
    final height =
        roleFor(id) * BuildingSpriteMetrics.verticalFillRatio(id) * depth * bodyScale;
    final width = height *
        BuildingSpriteMetrics.contentAspectRatio(id) /
        plateAspect;
    return Rect.fromLTRB(
      anchor.dx - width / 2 - pad,
      anchor.dy - height - pad,
      anchor.dx + width / 2 + pad,
      anchor.dy + pad,
    );
  }

  /// 树冠在岛坯上的范围。底边贴着脚点。
  static Rect treeContentRect(String id, Offset anchor, {double pad = 0}) {
    final depth = BuildingDepthScale.forAnchorDy(anchor.dy);
    final height = treeHeightFactor(id) * depth;
    final width = height * 0.82 / plateAspect;
    return Rect.fromLTRB(
      anchor.dx - width / 2 - pad,
      anchor.dy - height - pad,
      anchor.dx + width / 2 + pad,
      anchor.dy + pad,
    );
  }

  /// 左右并排的立面不能相交。前后排只允许盖住后方底部约三成，算作纵深。
  static bool coversAbnormally(Rect a, Rect b) {
    if (!a.overlaps(b)) return false;
    final hit = a.intersect(b);
    if (hit.width <= 0.004 || hit.height <= 0.004) return false;
    if ((a.bottom - b.bottom).abs() < 0.04) return true;
    final front = a.bottom >= b.bottom ? a : b;
    final back = a.bottom >= b.bottom ? b : a;
    final allowTop = back.bottom - back.height * 0.30;
    return front.top < allowTop - 0.001;
  }
}
