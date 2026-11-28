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

/// 缩放后仍让 [worldFocal] 落在 [screenFocal]。双指中点因此不会在放大缩小时溜走。
Offset panForAnchoredZoom({
  required Offset worldFocal,
  required Offset screenFocal,
  required Size size,
  required double zoom,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  return screenFocal - center - (worldFocal - center) * zoom;
}

/// 主岛详情的手指会话：双指只放大，并让双指中点下的岛面留在原地。
/// 单指只在已经放大后平移。名称气泡跟的是同一套取景，不会被双指拖走。
class BoardPointerSession {
  BoardPointerSession({
    this.zoom = 1,
    this.pan = Offset.zero,
    this.viewportSize = const Size(390, 844),
  });

  static const minZoom = 1.0;
  static const maxZoom = 3.6;
  static const panSlop = 18.0;

  double zoom;
  Offset pan;
  Size viewportSize;

  final Map<int, Offset> _pointers = {};
  double _zoom0 = 1;
  Offset _pan0 = Offset.zero;
  double _span0 = 0;
  Offset? _worldFocal;
  Offset? _singleOrigin;
  bool moved = false;
  Offset? tapPoint;

  void down(int pointer, Offset position) {
    _pointers[pointer] = position;
    if (_pointers.length == 1) {
      _zoom0 = zoom;
      _pan0 = pan;
      _singleOrigin = position;
      tapPoint = position;
      moved = false;
      _span0 = 0;
      _worldFocal = null;
      return;
    }
    _armPinch();
  }

  void move(int pointer, Offset position) {
    if (!_pointers.containsKey(pointer)) return;
    _pointers[pointer] = position;
    if (_pointers.length >= 2) {
      if (_span0 <= 1 || _worldFocal == null) _armPinch();
      if (_span0 <= 1 || _worldFocal == null) return;
      final scale = _span() / _span0;
      if ((scale - 1).abs() > 0.02) moved = true;
      if (!moved) return;
      final nextZoom = (_zoom0 * scale).clamp(minZoom, maxZoom);
      zoom = nextZoom;
      // 双指只改缩放。平移只用来把开始时的那一点留在原处，名称不会被拖走。
      pan = _limitPan(
        panForAnchoredZoom(
          worldFocal: _worldFocal!,
          screenFocal: _pinchFocal0,
          size: viewportSize,
          zoom: nextZoom,
        ),
        nextZoom,
      );
      return;
    }
    final origin = _singleOrigin;
    if (origin != null && (position - origin).distance > panSlop) {
      moved = true;
    }
    if (zoom <= 1.02) return;
    if (origin == null) return;
    final delta = position - origin;
    if (delta.distance > panSlop) moved = true;
    if (!moved) return;
    zoom = _zoom0;
    pan = _limitPan(_pan0 + delta, _zoom0);
  }

  /// 全部手指离开且没有拖动过时，这次抬起是一次点击。
  bool up(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.isEmpty) {
      final tap = !moved;
      moved = false;
      _span0 = 0;
      _worldFocal = null;
      return tap;
    }
    moved = true;
    _zoom0 = zoom;
    _pan0 = pan;
    if (_pointers.length == 1) {
      _singleOrigin = _pointers.values.first;
      _span0 = 0;
      _worldFocal = null;
    } else {
      _armPinch();
    }
    return false;
  }

  Offset _pinchFocal0 = Offset.zero;

  void _armPinch() {
    if (_pointers.length < 2) return;
    _zoom0 = zoom;
    _pan0 = pan;
    _span0 = _span();
    _pinchFocal0 = _centroid();
    _worldFocal = mapInverseBoardCameraPoint(
      zoomedPoint: _pinchFocal0,
      size: viewportSize,
      zoom: _zoom0,
      rotation: 0,
      pan: _pan0,
    );
  }

  Offset _centroid() {
    var sum = Offset.zero;
    for (final point in _pointers.values) {
      sum += point;
    }
    return sum / _pointers.length.toDouble();
  }

  double _span() {
    final center = _centroid();
    var total = 0.0;
    for (final point in _pointers.values) {
      total += (point - center).distance;
    }
    return total / _pointers.length;
  }

  Offset _limitPan(Offset value, double atZoom) {
    final extra = (atZoom - 1).clamp(0.0, 3.0);
    final maxX = viewportSize.width * (0.36 + extra * 0.72);
    final maxY = viewportSize.height * (0.10 + extra * 0.48);
    return Offset(
      value.dx.clamp(-maxX, maxX),
      value.dy.clamp(-maxY, maxY),
    );
  }
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
