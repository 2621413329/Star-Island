import 'dart:math' as math;
import 'dart:ui';

import '../../island/building/building_depth_scale.dart';
import '../../island/building/building_sprite_metrics.dart';
import 'painted_island_pits.dart';

/// 详情页把岛坯放大后，建筑不再跟着变大，挤在一起的脚点再错开。
///
/// 首页预览仍用岛坯上的原坑位。同一等级不会同时出现的升级对保持同一个坑。
class DetailBuildingSpread {
  DetailBuildingSpread._();

  /// 相对「铺满当前岛坯」的立面。小于 1 时多出来的是建筑之间的地面。
  static const bodyScale = 0.74;

  static const plateAspect = 958 / 743;

  static double roleFor(String id) {
    return switch (id) {
      'growth_academy' => 0.30,
      'lighthouse' ||
      'lighthouse_base' ||
      'growth_clocktower' ||
      'dream_observatory' =>
        0.26,
      'growth_tree' => 0.20,
      'harbor_pier' => 0.12,
      'story_plaza' ||
      'companion_plaza' ||
      'starter_stone' ||
      'habit_flowerbed' =>
        0.10,
      _ => 0.17,
    };
  }

  /// [plateScale] 为 1 时原样返回。详情页返回错开后的脚点。
  static Offset place(String id, Offset pit, double plateScale) {
    if (plateScale <= 1.01) return pit;
    return _anchors[id] ?? pit;
  }

  /// 不透明立面在岛坯上的范围。底边贴着脚点。
  static Rect contentRect(String id, Offset anchor, {double pad = 0.008}) {
    final depth = BuildingDepthScale.forAnchorDy(anchor.dy);
    final height = roleFor(id) * depth * bodyScale;
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

  static const _locked = {
    'dream_observatory',
    'harbor_pier',
    'growth_academy',
    'growth_clocktower',
    'lighthouse',
  };

  static const _aliasOf = {
    'growth_house_lv2': 'growth_house',
    'lighthouse_base': 'lighthouse',
  };

  static final Map<String, Offset> _anchors = _solve();

  static Map<String, Offset> _solve() {
    final source = PaintedIslandPits.buildings;
    final ids = source.keys.where((id) => !_aliasOf.containsKey(id)).toList()
      ..sort();
    final pos = <String, Offset>{
      for (final id in ids) id: source[id]!,
    };

    for (var step = 0; step < 120; step++) {
      var moved = false;
      for (final fixed in _locked) {
        if (!pos.containsKey(fixed)) continue;
        for (final id in ids) {
          if (id == fixed || _locked.contains(id)) continue;
          final push = _separation(
            contentRect(fixed, pos[fixed]!),
            contentRect(id, pos[id]!),
          );
          if (push == null) continue;
          if (_set(pos, id, pos[id]! - push)) moved = true;
        }
      }
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = ids[i];
          final b = ids[j];
          final push = _separation(
            contentRect(a, pos[a]!),
            contentRect(b, pos[b]!),
          );
          if (push == null) continue;
          if (_nudge(pos, a, b, push)) {
            moved = true;
            continue;
          }
          final swapped = Offset(push.dy, push.dx);
          if (swapped.distance == 0) continue;
          final sign = pos[a]!.dx >= pos[b]!.dx ? 1.0 : -1.0;
          if (_nudge(pos, a, b, Offset(sign * push.distance, 0))) {
            moved = true;
          }
        }
      }
      if (!moved) break;
    }

    final out = Map<String, Offset>.from(pos);
    for (final entry in _aliasOf.entries) {
      final canonical = out[entry.value];
      if (canonical != null) out[entry.key] = canonical;
    }
    return out;
  }

  static bool _nudge(
    Map<String, Offset> pos,
    String a,
    String b,
    Offset pushOnA,
  ) {
    final aLocked = _locked.contains(a);
    final bLocked = _locked.contains(b);
    if (aLocked && bLocked) return false;
    var moved = false;
    if (!aLocked && !bLocked) {
      moved = _set(pos, a, pos[a]! + pushOnA * 0.5) || moved;
      moved = _set(pos, b, pos[b]! - pushOnA * 0.5) || moved;
      return moved;
    }
    if (!aLocked) return _set(pos, a, pos[a]! + pushOnA);
    return _set(pos, b, pos[b]! - pushOnA);
  }

  static bool _set(Map<String, Offset> pos, String id, Offset next) {
    final clamped = _clamp(next);
    if ((clamped - pos[id]!).distance < 0.0001) return false;
    pos[id] = clamped;
    return true;
  }

  static Offset _clamp(Offset point) {
    return Offset(
      point.dx.clamp(0.14, 0.86),
      point.dy.clamp(0.30, 0.76),
    );
  }

  /// 把前者推出后者的最小位移。重叠更窄的那条轴优先，避免整排被挤向沙滩。
  static Offset? _separation(Rect a, Rect b) {
    final overlapX = math.min(a.right, b.right) - math.max(a.left, b.left);
    final overlapY = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
    if (overlapX <= 0 || overlapY <= 0) return null;
    if (overlapX <= overlapY) {
      final sign = a.center.dx >= b.center.dx ? 1.0 : -1.0;
      return Offset(sign * overlapX, 0);
    }
    final sign = a.center.dy >= b.center.dy ? 1.0 : -1.0;
    return Offset(0, sign * overlapY);
  }
}
