import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 将提醒编辑页所选图标（PNG / WebP / SVG）转为 Android 通知大图。
class ReminderNotificationBitmap {
  ReminderNotificationBitmap._();

  static final ReminderNotificationBitmap instance = ReminderNotificationBitmap._();

  static const _targetSize = 256;
  static const _fallbackLargeIcon = '@mipmap/ic_launcher';

  final Map<String, AndroidBitmap<Object>> _cache = {};

  Future<AndroidBitmap<Object>> forAsset(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;

    final bytes = await _loadPngBytes(assetPath);
    if (bytes != null && bytes.isNotEmpty) {
      final bitmap = ByteArrayAndroidBitmap(bytes);
      _cache[assetPath] = bitmap;
      return bitmap;
    }
    return const DrawableResourceAndroidBitmap(_fallbackLargeIcon);
  }

  Future<Uint8List?> _loadPngBytes(String assetPath) async {
    try {
      final lower = assetPath.toLowerCase();
      if (lower.endsWith('.svg')) {
        return _svgAssetToPng(assetPath);
      }
      return _rasterAssetToPng(assetPath);
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _rasterAssetToPng(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _targetSize,
      targetHeight: _targetSize,
    );
    final frame = await codec.getNextFrame();
    try {
      return _imageToPng(frame.image);
    } finally {
      frame.image.dispose();
    }
  }

  Future<Uint8List?> _svgAssetToPng(String assetPath) async {
    final svgString = await rootBundle.loadString(assetPath);
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
    try {
      final w = pictureInfo.size.width;
      final h = pictureInfo.size.height;
      if (w <= 0 || h <= 0) return null;
      final scale = _targetSize / math.max(w, h);
      final image = await pictureInfo.picture.toImage(
        (w * scale).ceil().clamp(1, _targetSize),
        (h * scale).ceil().clamp(1, _targetSize),
      );
      try {
        return _imageToPng(image);
      } finally {
        image.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  }

  Future<Uint8List?> _imageToPng(ui.Image image) async {
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
