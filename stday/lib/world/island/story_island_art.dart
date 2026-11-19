import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'painted_island_asset.dart';

/// 副岛手绘岛图。每类一张，和主岛同一套落位。
class StoryIslandArt {
  StoryIslandArt._();

  static const ids = [
    'work',
    'study',
    'health',
    'social',
    'life',
    'creation',
    'finance',
    'achievement',
    'emotion',
    'inspiration',
    'milestone',
  ];

  static final Map<String, ui.Image> _images = {};
  static final Map<String, Future<void>> _loading = {};
  static int revision = 0;
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback listener) => _listeners.add(listener);

  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  static String fileId(String categoryId) {
    if (categoryId == 'wealth') return 'finance';
    if (ids.contains(categoryId)) return categoryId;
    return 'life';
  }

  static String assetPath(String categoryId) =>
      'assets/images/islands/${fileId(categoryId)}/land.png';

  static Future<void> ensure(String? categoryId) {
    final id = fileId(categoryId ?? 'life');
    if (_images.containsKey(id)) return Future<void>.value();
    return _loading[id] ??= _load(id);
  }

  static Future<void> _load(String id) async {
    try {
      final data = await rootBundle.load(assetPath(id));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      _images[id] = frame.image;
      revision++;
      final listeners = List<VoidCallback>.of(_listeners);
      for (final listener in listeners) {
        listener();
      }
    } catch (_) {
      _loading.remove(id);
    }
  }

  static void paint(Canvas canvas, Size size, String categoryId) {
    final plate = _images[fileId(categoryId)];
    if (plate == null) {
      ensure(categoryId);
      return;
    }
    final dest = PaintedIslandAsset.layoutRect(size);
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
