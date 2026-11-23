import 'dart:ui';

import 'package:flame/components.dart';

import 'world_render_probe.dart';

/// 详情页把静止岛面和会动的元素拆开画。
///
/// 卡片游戏的牌面是一张贴图，只有正在移动的牌会重绘。
/// [full] 保持旧的单画布路径，给预览和落地页用。
enum WorldPaintPass {
  full,
  backdrop,
  backMotion,
  island,
  frontMotion,
}

/// 由 [WorldScene] 实现，避免装饰层反向依赖整个场景文件。
abstract class WorldPaintHost {
  WorldPaintPass get paintPass;
  set paintPass(WorldPaintPass value);

  bool get suppressFullPaint;
  set suppressFullPaint(bool value);

  /// 主角脚点，用来决定谁该盖住角色。
  double get heroFootDy;

  /// 详情页放大岛坯。1 表示按默认卡片铺岛。
  double get plateScale => 1;

  double get boardZoom;
  double get boardRotation;

  /// 屏幕像素。正值把整幅画面往右、往下推。天空、海面和岛面用同一套。
  Offset get boardPan;

  void addRetainedFrameListener(void Function() listener);
  void removeRetainedFrameListener(void Function() listener);
  void addIslandFrameListener(void Function() listener);
  void removeIslandFrameListener(void Function() listener);
  void addBoardTransformListener(void Function() listener);
  void removeBoardTransformListener(void Function() listener);

  /// 天空和岛面都要重录（换尺寸、换心情、换天气）。
  void invalidateRetainedFrame();

  /// 只重录岛面。装饰图和建筑图进入时，天空不用重录。
  void invalidateIslandFrame();

  /// 画这一帧时把 Flame 取景器暂时归到不缩放、不旋转。
  /// 整幅画面的缩放只加在 Flutter 画布上，点击用同一套逆矩阵。
  void withNeutralViewfinder(void Function() action);

  /// 详情页把屏幕坐标换回未缩放的世界坐标再命中建筑。
  void handleScreenTap(Offset screenPoint) {}
}

extension WorldPaintComponent on Component {
  WorldPaintHost? get paintHost {
    final game = findGame();
    if (game is WorldPaintHost) return game as WorldPaintHost;
    return null;
  }

  /// 当前这一笔不是本层所属的 pass 时，整棵子树都不画。
  bool skipPaintSlot(WorldPaintPass slot) {
    final host = paintHost;
    final skip = host != null &&
        host.paintPass != WorldPaintPass.full &&
        host.paintPass != slot;
    if (WorldRenderProbe.enabled) {
      WorldRenderProbe.noteSlotVisit(painted: !skip);
    }
    return skip;
  }
}
