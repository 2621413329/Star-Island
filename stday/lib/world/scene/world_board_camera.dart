import 'dart:math' as math;
import 'dart:ui';

/// 静态 Picture 按 zoom=1、angle=0 的画面保存。绘制时绕视口中心补上当前取景器。
///
/// Flame 的 [Viewfinder.angle] 写入变换时会取反，所以这里旋转 `-rotation`。
void applyBoardCamera(
  Canvas canvas,
  Size size,
  double zoom,
  double rotation, {
  Offset pan = Offset.zero,
}) {
  if (zoom == 1.0 && rotation == 0.0 && pan == Offset.zero) return;
  final cx = size.width / 2;
  final cy = size.height / 2;
  canvas.translate(cx + pan.dx, cy + pan.dy);
  canvas.rotate(-rotation);
  canvas.scale(zoom, zoom);
  canvas.translate(-cx, -cy);
}

/// [applyBoardCamera] 的逆变换。录制时先套在画布上，抵消真实取景器里的缩放和旋转。
///
/// 均匀缩放与旋转可交换，所以逆矩阵是先缩放再旋转。
void applyInverseBoardCamera(
  Canvas canvas,
  Size size,
  double zoom,
  double rotation, {
  Offset pan = Offset.zero,
}) {
  if (zoom == 1.0 && rotation == 0.0 && pan == Offset.zero) return;
  final cx = size.width / 2;
  final cy = size.height / 2;
  canvas.translate(cx, cy);
  canvas.scale(1 / zoom, 1 / zoom);
  canvas.rotate(rotation);
  canvas.translate(-(cx + pan.dx), -(cy + pan.dy));
}

/// 与 [applyBoardCamera] 同一套矩阵，供测试对照取景器。
Offset mapBoardCameraPoint({
  required Offset neutralPoint,
  required Size size,
  required double zoom,
  required double rotation,
  Offset pan = Offset.zero,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final delta = (neutralPoint - center) * zoom;
  final cosA = math.cos(-rotation);
  final sinA = math.sin(-rotation);
  return center +
      pan +
      Offset(
        cosA * delta.dx - sinA * delta.dy,
        sinA * delta.dx + cosA * delta.dy,
      );
}

/// 与 [applyInverseBoardCamera] 同一套矩阵。
Offset mapInverseBoardCameraPoint({
  required Offset zoomedPoint,
  required Size size,
  required double zoom,
  required double rotation,
  Offset pan = Offset.zero,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final delta = zoomedPoint - center - pan;
  final cosA = math.cos(rotation);
  final sinA = math.sin(rotation);
  final unrotated = Offset(
    cosA * delta.dx - sinA * delta.dy,
    sinA * delta.dx + cosA * delta.dy,
  );
  return center + unrotated / zoom;
}
