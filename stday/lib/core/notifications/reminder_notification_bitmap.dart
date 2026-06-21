import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'notification_attachment_storage.dart';

/// 将提醒编辑页所选图标（PNG / WebP / SVG）转为各平台通知可用资源。
class ReminderNotificationBitmap {
  ReminderNotificationBitmap._();

  static final ReminderNotificationBitmap instance =
      ReminderNotificationBitmap._();

  static const _targetSize = 256;
  static const _fallbackLargeIcon = '@mipmap/ic_launcher';

  final Map<String, AndroidBitmap<Object>> _androidCache = {};
  final Map<String, String> _iosAttachmentCache = {};

  Future<AndroidBitmap<Object>> forAsset(String assetPath) async {
    final cached = _androidCache[assetPath];
    if (cached != null) return cached;

    if (!_canRasterizeAssets) {
      return const DrawableResourceAndroidBitmap(_fallbackLargeIcon);
    }

    final bytes = await _loadPngBytes(assetPath);
    if (bytes != null && bytes.isNotEmpty) {
      final bitmap = ByteArrayAndroidBitmap(bytes);
      _androidCache[assetPath] = bitmap;
      return bitmap;
    }
    return const DrawableResourceAndroidBitmap(_fallbackLargeIcon);
  }

  /// iOS / macOS 本地通知附件路径（需持久化到磁盘，供定时通知触发时读取）。
  Future<String?> attachmentFilePathForAsset(String assetPath) async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return null;
    }
    if (!_canRasterizeAssets) return null;

    final cached = _iosAttachmentCache[assetPath];
    if (cached != null && await notificationIconFileExists(cached)) {
      return cached;
    }

    final bytes = await _loadPngBytes(assetPath);
    if (bytes == null || bytes.isEmpty) return null;

    try {
      final path = await persistNotificationIconPng(assetPath, bytes);
      if (path == null) return null;
      _iosAttachmentCache[assetPath] = path;
      return path;
    } catch (e, st) {
      debugPrint(
        'ReminderNotificationBitmap: iOS attachment failed: $e\n$st',
      );
      return null;
    }
  }

  bool get _canRasterizeAssets {
    try {
      return WidgetsBinding.instance.platformDispatcher.views.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> _loadPngBytes(String assetPath) async {
    try {
      final lower = assetPath.toLowerCase();
      if (lower.endsWith('.svg')) {
        return _svgAssetToPng(assetPath);
      }
      return _rasterAssetToPng(assetPath);
    } catch (e, st) {
      debugPrint('ReminderNotificationBitmap: $assetPath failed: $e\n$st');
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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
