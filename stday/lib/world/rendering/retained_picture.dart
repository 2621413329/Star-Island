import 'dart:ui';

import '../scene/world_render_probe.dart';

/// 把不变的矢量绘制收成一张 Picture，之后每帧只做一次贴图。
///
/// 动画仍画在 Picture 之外，避免把呼吸、浪纹一起冻住。
class RetainedPicture {
  Picture? _picture;
  Object? _token;
  int rasterCount = 0;

  void draw(Canvas canvas, Object token, void Function(Canvas recording) paint) {
    if (_picture == null || _token != token) {
      WorldRenderProbe.notePictureRecorder();
      final recorder = PictureRecorder();
      paint(Canvas(recorder));
      _picture?.dispose();
      _picture = recorder.endRecording();
      _token = token;
      rasterCount++;
    }
    canvas.drawPicture(_picture!);
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
    _token = null;
  }
}

/// 多张静态图的有界缓存。最近使用的条目留在末尾。
class RetainedPictureMap {
  RetainedPictureMap({this.maxEntries = 48});

  final int maxEntries;
  final Map<String, Picture> _pictures = {};
  int rasterCount = 0;

  void draw(Canvas canvas, String key, void Function(Canvas recording) paint) {
    final existing = _pictures.remove(key);
    final Picture picture;
    if (existing != null) {
      picture = existing;
    } else {
      rasterCount++;
      WorldRenderProbe.notePictureRecorder();
      final recorder = PictureRecorder();
      paint(Canvas(recorder));
      picture = recorder.endRecording();
      while (_pictures.length >= maxEntries) {
        final oldest = _pictures.keys.first;
        _pictures.remove(oldest)?.dispose();
      }
    }
    _pictures[key] = picture;
    canvas.drawPicture(picture);
  }

  void dispose() {
    for (final picture in _pictures.values) {
      picture.dispose();
    }
    _pictures.clear();
  }
}
