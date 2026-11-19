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

  /// 岛坯局部坐标（左上为 0，右下为 1）落到视口像素。
  static Offset plateToCanvas(Offset plate, Size viewport) {
    final rect = layoutRect(viewport);
    return Offset(
      rect.left + plate.dx * rect.width,
      rect.top + plate.dy * rect.height,
    );
  }

  /// 岛坯局部坐标换成视口归一化坐标，给仍按整屏比例摆放的组件使用。
  static Offset plateToViewportNorm(Offset plate, Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return plate;
    final canvas = plateToCanvas(plate, viewport);
    return Offset(canvas.dx / viewport.width, canvas.dy / viewport.height);
  }

  /// 岛坯在视口中的落位。保持原图比例，居中，四周留给海水。
  static Rect layoutRect(Size size) {
    final plate = _image;
    final aspect = plate == null || plate.height == 0
        ? 958 / 743
        : plate.width / plate.height;
    final maxW = size.width * 0.96;
    final maxH = size.height * 0.86;
    var width = maxW;
    var height = width / aspect;
    if (height > maxH) {
      height = maxH;
      width = height * aspect;
    }
    return Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.54),
      width: width,
      height: height,
    );
  }

  static void paint(Canvas canvas, Size size) {
    final plate = _image;
    if (plate == null) return;
    final dest = layoutRect(size);
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
