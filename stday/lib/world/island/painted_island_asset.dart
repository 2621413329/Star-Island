import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 主岛手绘岛坯。副岛使用各自的手绘岛图。
///
/// 陆地、浅滩、土层边缘和码头都在这张图里。海、天空和水纹仍由场景层绘制。
class PaintedIslandAsset {
  PaintedIslandAsset._();

  static const path = 'assets/images/islands/main_island_blank.png';

  static ui.Image? _image;
  static Future<void>? _loading;
  static int revision = 0;
  static final List<VoidCallback> _listeners = [];

  static ui.Image? get image => _image;

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static Future<void> ensureLoaded() {
    if (_image != null) return Future<void>.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      _image = frame.image;
      revision++;
      final listeners = List<VoidCallback>.of(_listeners);
      for (final listener in listeners) {
        listener();
      }
    } catch (_) {
      _loading = null;
    }
  }

  /// 详情页只略放大，崖壁、草地、沙滩和码头都留在画面里。首页预览仍用 1。
  static const detailScale = 1.04;

  /// 岛坯局部坐标（左上为 0，右下为 1）落到视口像素。
  static Offset plateToCanvas(
    Offset plate,
    Size viewport, {
    double scale = 1,
  }) {
    final rect = layoutRect(viewport, scale: scale);
    return Offset(
      rect.left + plate.dx * rect.width,
      rect.top + plate.dy * rect.height,
    );
  }

  /// 岛坯局部坐标换成视口归一化坐标，给仍按整屏比例摆放的组件使用。
  static Offset plateToViewportNorm(
    Offset plate,
    Size viewport, {
    double scale = 1,
  }) {
    if (viewport.width <= 0 || viewport.height <= 0) return plate;
    final canvas = plateToCanvas(plate, viewport, scale: scale);
    return Offset(canvas.dx / viewport.width, canvas.dy / viewport.height);
  }

  /// 顶栏卡片下方、岛坯上方的开阔天空。云放在这段里。
  static double openSkyTop(Size size, {double scale = 1}) {
    final plateTop = layoutRect(size, scale: scale).top;
    final belowCard = size.height * 0.26 > 168 ? size.height * 0.26 : 168.0;
    final aboveIsland = plateTop - 36;
    if (aboveIsland < size.height * 0.06) return size.height * 0.06;
    return belowCard < aboveIsland ? belowCard : aboveIsland;
  }

  /// [openSkyTop] 对应的下沿，停在岛坯顶边之上。
  static double openSkyBottom(Size size, {double scale = 1}) {
    final top = openSkyTop(size, scale: scale);
    final abovePlate = layoutRect(size, scale: scale).top - 12;
    return abovePlate > top + 20 ? abovePlate : top + 20;
  }

  /// 岛坯在视口中的落位。保持原图比例，居中，四周留给海水。
  ///
  /// [scale] 大于 1 时岛面超出默认卡片，边缘由视口裁切，陆地相对变大。
  static Rect layoutRect(Size size, {double scale = 1}) {
    final plate = _image;
    final aspect = plate == null || plate.height == 0
        ? 958 / 743
        : plate.width / plate.height;
    final fitted = scale.clamp(1.0, 1.45);
    final maxW = size.width * 0.96 * fitted;
    final maxH = size.height * 0.86 * fitted;
    var width = maxW;
    var height = width / aspect;
    if (height > maxH) {
      height = maxH;
      width = height * aspect;
    }
    final centerY = fitted > 1.01 ? 0.58 : 0.54;
    return Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * centerY),
      width: width,
      height: height,
    );
  }

  static void paint(Canvas canvas, Size size, {double scale = 1}) {
    final plate = _image;
    if (plate == null) return;
    final dest = layoutRect(size, scale: scale);
    final shadow = Rect.fromCenter(
      center: Offset(dest.center.dx, dest.bottom - dest.height * 0.04),
      width: dest.width * 0.62,
      height: dest.height * 0.10,
    );
    canvas.drawOval(
      shadow,
      Paint()
        ..color = const Color(0x332E6E85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawImageRect(
      plate,
      Rect.fromLTWH(0, 0, plate.width.toDouble(), plate.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}
