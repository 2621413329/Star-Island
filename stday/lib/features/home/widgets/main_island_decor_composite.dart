import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../island/decor/decor_config.dart';
import '../../../island/decor/decor_scale_resolver.dart';
import '../../../world/island/painted_island_asset.dart';
import '../../../world/island/painted_island_pits.dart';

/// 把主岛花草石头收成一张透明位图。建筑和小人不画进这张图。
class MainIslandDecorImageCache {
  MainIslandDecorImageCache._();

  static const maxEntries = 4;
  static final Map<String, _DecorEntry> _images = {};

  static int rasterCount = 0;
  static int hitCount = 0;
  static int evictionCount = 0;

  static ui.Image? peek(String key) {
    final existing = _images.remove(key);
    if (existing == null) return null;
    _images[key] = existing;
    hitCount++;
    return existing.image;
  }

  static void retain(String key) {
    final existing = _images[key];
    if (existing == null) return;
    existing.users++;
  }

  static void release(String key) {
    final existing = _images[key];
    if (existing == null) return;
    existing.users = existing.users > 0 ? existing.users - 1 : 0;
    _evictUnused();
  }

  static void debugReset() {
    for (final image in _images.values) {
      image.image.dispose();
    }
    _images.clear();
    rasterCount = 0;
    hitCount = 0;
    evictionCount = 0;
  }

  static ui.Image _store(String key, ui.Image image) {
    final previous = _images.remove(key);
    if (previous != null) {
      image.dispose();
      _images[key] = previous;
      return previous.image;
    }
    _images[key] = _DecorEntry(image);
    rasterCount++;
    _evictUnused();
    return image;
  }

  static void _evictUnused() {
    while (_images.length > maxEntries) {
      String? oldestUnused;
      for (final entry in _images.entries) {
        if (entry.value.users == 0) {
          oldestUnused = entry.key;
          break;
        }
      }
      if (oldestUnused == null) return;
      _images.remove(oldestUnused)?.image.dispose();
      evictionCount++;
    }
  }
}

class _DecorEntry {
  _DecorEntry(this.image);

  final ui.Image image;
  int users = 0;
}

class MainIslandDecorComposite extends StatefulWidget {
  const MainIslandDecorComposite({
    super.key,
    required this.viewportSize,
    required this.userLevel,
    required this.clearCenter,
  });

  final Size viewportSize;
  final int userLevel;
  final bool clearCenter;

  @override
  State<MainIslandDecorComposite> createState() =>
      _MainIslandDecorCompositeState();
}

class _MainIslandDecorCompositeState extends State<MainIslandDecorComposite> {
  ui.Image? _image;
  String? _key;
  String? _pendingKey;
  int _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(MainIslandDecorComposite oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolve();
  }

  @override
  void dispose() {
    final key = _key;
    if (key != null) MainIslandDecorImageCache.release(key);
    _key = null;
    super.dispose();
  }

  void _hold(String key, ui.Image image) {
    if (_key == key && identical(_image, image)) return;
    final previous = _key;
    if (previous != null && previous != key) {
      MainIslandDecorImageCache.release(previous);
    }
    final alreadyHeld = _key == key;
    _key = key;
    _image = image;
    if (!alreadyHeld) MainIslandDecorImageCache.retain(key);
  }

  String _cacheKey(double dpr) {
    final size = widget.viewportSize;
    return '${size.width.round()}x${size.height.round()}'
        '|${widget.userLevel}|${widget.clearCenter}|${dpr.toStringAsFixed(2)}';
  }

  void _resolve() {
    final size = widget.viewportSize;
    if (size.width < 1 || size.height < 1) return;
    final dpr =
        MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0).toDouble();
    final key = _cacheKey(dpr);
    if (key == _key && _image != null) return;
    if (key == _pendingKey) return;
    final cached = MainIslandDecorImageCache.peek(key);
    if (cached != null) {
      _pendingKey = null;
      _hold(key, cached);
      return;
    }
    _pendingKey = key;
    final requestId = ++_requestId;
    _compose(key, dpr, requestId);
  }

  Future<void> _compose(String key, double dpr, int requestId) async {
    final decor = _previewDecor(
      userLevel: widget.userLevel,
      clearCenter: widget.clearCenter,
    );
    final decoded = <ui.Image>[];
    try {
      for (final config in decor) {
        final box = _decorSize(config, widget.userLevel, widget.viewportSize);
        final cacheW = (box.width * dpr).round().clamp(32, 640);
        try {
          final data =
              await rootBundle.load('assets/images/${config.assetPath}');
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
            targetWidth: cacheW,
          );
          final frame = await codec.getNextFrame();
          codec.dispose();
          decoded.add(frame.image);
        } catch (_) {
          decoded.add(_emptyImage());
        }
        if (!mounted || requestId != _requestId) {
          for (final image in decoded) {
            image.dispose();
          }
          return;
        }
      }
      if (!mounted || requestId != _requestId) return;
      final existing = MainIslandDecorImageCache.peek(key);
      if (existing != null) {
        for (final image in decoded) {
          image.dispose();
        }
        setState(() {
          _pendingKey = null;
          _hold(key, existing);
        });
        return;
      }
      final pixelW = math.max(1, (widget.viewportSize.width * dpr).round());
      final pixelH = math.max(1, (widget.viewportSize.height * dpr).round());
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(dpr);
      for (var i = 0; i < decor.length; i++) {
        final image = decoded[i];
        if (image.width < 1 || image.height < 1) continue;
        final config = decor[i];
        final box = _decorSize(config, widget.userLevel, widget.viewportSize);
        final foot = PaintedIslandAsset.plateToCanvas(
          PaintedIslandPits.decor(config.id),
          widget.viewportSize,
        );
        final dest = Rect.fromLTWH(
          foot.dx - box.width / 2,
          foot.dy - box.height,
          box.width,
          box.height,
        );
        _drawContainBottom(canvas, image, dest);
      }
      final picture = recorder.endRecording();
      final composed = await picture.toImage(pixelW, pixelH);
      picture.dispose();
      for (final image in decoded) {
        image.dispose();
      }
      final stored = MainIslandDecorImageCache._store(key, composed);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _pendingKey = null;
        _hold(key, stored);
      });
    } catch (_) {
      for (final image in decoded) {
        image.dispose();
      }
    }
  }

  ui.Image _emptyImage() {
    final recorder = ui.PictureRecorder();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    picture.dispose();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return SizedBox(
        width: widget.viewportSize.width,
        height: widget.viewportSize.height,
      );
    }
    return RawImage(
      image: image,
      width: widget.viewportSize.width,
      height: widget.viewportSize.height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }
}

void _drawContainBottom(Canvas canvas, ui.Image image, Rect dest) {
  final sourceW = image.width.toDouble();
  final sourceH = image.height.toDouble();
  final scale = math.min(dest.width / sourceW, dest.height / sourceH);
  final width = sourceW * scale;
  final height = sourceH * scale;
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, sourceW, sourceH),
    Rect.fromLTWH(
      dest.left + (dest.width - width) / 2,
      dest.bottom - height,
      width,
      height,
    ),
    Paint()..filterQuality = FilterQuality.low,
  );
}

List<DecorConfig> _previewDecor({
  required int userLevel,
  required bool clearCenter,
}) {
  final all = DecorConfigs.unlockedMainIslandAt(userLevel)
      .where(DecorConfigs.isMainIslandGroundDecor)
      .where((decor) => decor.category != DecorCategory.pond);
  final visible = !clearCenter
      ? all.toList()
      : all.where((decor) {
          final plate = PaintedIslandPits.decor(decor.id);
          final dx = plate.dx - PaintedIslandPits.character.dx;
          final dy = plate.dy - PaintedIslandPits.character.dy;
          return dx * dx + dy * dy > 0.0064;
        }).toList();
  visible.sort(
    (a, b) => a.category.layerPriority.compareTo(b.category.layerPriority),
  );
  return visible;
}

Size _decorSize(DecorConfig config, int userLevel, Size viewportSize) {
  final resolver = const DecorScaleResolver();
  final baseHeight = DecorScaleResolver.baseHeightFor(config.category);
  final scale = resolver.finalScale(config, userLevel);
  final plateY = PaintedIslandPits.decor(config.id).dy;
  final depth = 0.82 + (plateY - 0.44).clamp(0.0, 0.28) * 0.9;
  final largeTree = DecorScaleResolver.matchesAcademyScale(config.id);
  final (boost, floor, capFactor) = switch (config.category) {
    DecorCategory.tree =>
      (largeTree ? 1.35 : 1.15, 16.0, largeTree ? 0.15 : 0.10),
    DecorCategory.bush => (1.15, 10.0, 0.07),
    DecorCategory.flower || DecorCategory.grass => (1.05, 8.0, 0.05),
    _ => (1.1, 10.0, 0.07),
  };
  final height = (baseHeight * scale * depth * boost)
      .clamp(floor, viewportSize.height * capFactor)
      .toDouble();
  return Size(height, height);
}
