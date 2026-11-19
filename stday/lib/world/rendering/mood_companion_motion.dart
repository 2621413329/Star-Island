import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../core/constants/companion_base_asset.dart';

/// 用现成的心情全身图做肢体动作。图本身不变，只挪手臂、腿和头。
class MoodCompanionMotion {
  MoodCompanionMotion._();

  static final Map<int, ui.Rect> _bounds = {};
  static final Set<int> _pending = {};

  static void prepare(ui.Image image) {
    final id = identityHashCode(image);
    if (_bounds.containsKey(id) || !_pending.add(id)) return;
    image.toByteData(format: ui.ImageByteFormat.rawRgba).then((data) {
      _pending.remove(id);
      if (data == null) return;
      _bounds[id] = _opaqueBounds(image, data);
    });
  }

  static void paint(
    ui.Canvas canvas, {
    required ui.Image image,
    required ui.Rect source,
    required ui.Rect dest,
    required String moodId,
    required double time,
  }) {
    prepare(image);
    final bounds = _bounds[identityHashCode(image)] ?? source;
    final pose = _pose(companionBaseAssetId(moodId), time);

    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(dest.center.dx, dest.bottom - dest.height * 0.02),
        width: dest.width * 0.42,
        height: dest.height * 0.06,
      ),
      ui.Paint()..color = const ui.Color(0x332B4B5A),
    );

    const cols = 12;
    const rows = 16;
    final positions = <ui.Offset>[];
    final textures = <ui.Offset>[];
    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= cols; x++) {
        final u = x / cols;
        final v = y / rows;
        final sx = source.left + u * source.width;
        final sy = source.top + v * source.height;
        textures.add(ui.Offset(sx, sy));
        final local = _displace(
          sx: sx,
          sy: sy,
          bounds: bounds,
          dest: dest,
          source: source,
          pose: pose,
        );
        positions.add(ui.Offset(
          dest.left + u * dest.width + local.dx,
          dest.top + v * dest.height + local.dy,
        ));
      }
    }

    final indices = <int>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final i = y * (cols + 1) + x;
        indices
          ..add(i)
          ..add(i + 1)
          ..add(i + cols + 1)
          ..add(i + 1)
          ..add(i + cols + 2)
          ..add(i + cols + 1);
      }
    }

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: textures,
      indices: indices,
    );
    final shader = ui.ImageShader(
      image,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      Matrix4Identity.storage,
    );
    canvas.drawVertices(
      vertices,
      ui.BlendMode.srcOver,
      ui.Paint()
        ..shader = shader
        ..filterQuality = ui.FilterQuality.medium,
    );
    shader.dispose();
    vertices.dispose();
  }

  static ui.Offset _displace({
    required double sx,
    required double sy,
    required ui.Rect bounds,
    required ui.Rect dest,
    required ui.Rect source,
    required _Pose pose,
  }) {
    if (bounds.width <= 1 || bounds.height <= 1) return ui.Offset.zero;
    final bx = ((sx - bounds.left) / bounds.width).clamp(0.0, 1.0);
    final by = ((sy - bounds.top) / bounds.height).clamp(0.0, 1.0);
    if (bx > 0.32 && bx < 0.68 && by > 0.06 && by < 0.40) {
      final tilt = pose.head;
      return ui.Offset(
          (bx - 0.5) * tilt * dest.width * 0.08, tilt * dest.height * 0.01);
    }

    final left = _armWeight(bx, by, left: true, raised: pose.raised);
    final right = _armWeight(bx, by, left: false, raised: pose.raised);
    final legL = _legWeight(bx, by, left: true);
    final legR = _legWeight(bx, by, left: false);
    var dx = 0.0;
    var dy = 0.0;
    if (left > right && left > 0) {
      final spun = _spin(
        pivotX: pose.raised ? 0.34 : 0.36,
        pivotY: pose.raised ? 0.40 : 0.50,
        angle: pose.armL,
        dest: dest,
        bounds: bounds,
        source: source,
        sx: sx,
        sy: sy,
      );
      dx += spun.dx * left;
      dy += spun.dy * left;
    } else if (right > 0) {
      final spun = _spin(
        pivotX: pose.raised ? 0.66 : 0.64,
        pivotY: pose.raised ? 0.40 : 0.50,
        angle: pose.armR,
        dest: dest,
        bounds: bounds,
        source: source,
        sx: sx,
        sy: sy,
      );
      dx += spun.dx * right;
      dy += spun.dy * right;
    }
    dy -= legL * pose.legL * dest.height;
    dy -= legR * pose.legR * dest.height;
    if (by > 0.40 && by < 0.72 && bx > 0.34 && bx < 0.66) {
      dy += pose.breathe * dest.height * 0.02;
    }
    return ui.Offset(dx, dy);
  }

  static ui.Offset _spin({
    required double pivotX,
    required double pivotY,
    required double angle,
    required ui.Rect dest,
    required ui.Rect bounds,
    required ui.Rect source,
    required double sx,
    required double sy,
  }) {
    ui.Offset toDest(double imageX, double imageY) {
      final u = (imageX - source.left) / source.width;
      final v = (imageY - source.top) / source.height;
      return ui.Offset(dest.left + u * dest.width, dest.top + v * dest.height);
    }

    final pivot = toDest(
      bounds.left + pivotX * bounds.width,
      bounds.top + pivotY * bounds.height,
    );
    final point = toDest(sx, sy);
    final relX = point.dx - pivot.dx;
    final relY = point.dy - pivot.dy;
    final c = math.cos(angle);
    final s = math.sin(angle);
    return ui.Offset(
      relX * c - relY * s - relX,
      relX * s + relY * c - relY,
    );
  }

  static double _armWeight(double bx, double by,
      {required bool left, required bool raised}) {
    final side = left ? (0.40 - bx) / 0.40 : (bx - 0.60) / 0.40;
    if (side <= 0) return 0;
    final y0 = raised ? 0.16 : 0.34;
    final y1 = raised ? 0.64 : 0.84;
    if (by < y0 || by > y1) return 0;
    final mid = (y0 + y1) / 2;
    final half = (y1 - y0) / 2;
    final yWeight = 1 - ((by - mid).abs() / half);
    return side.clamp(0.0, 1.0) * yWeight.clamp(0.0, 1.0);
  }

  static double _legWeight(double bx, double by, {required bool left}) {
    if (by < 0.70) return 0;
    final side = left ? (0.52 - bx) / 0.28 : (bx - 0.48) / 0.28;
    if (side <= 0) return 0;
    return side.clamp(0.0, 1.0) * ((by - 0.70) / 0.30).clamp(0.0, 1.0);
  }

  static _Pose _pose(String id, double time) {
    final t = time;
    return switch (id) {
      'kai_xin' => _Pose(
          armL: math.sin(t * 5.0) * 0.55,
          armR: math.sin(t * 5.0 + 0.9) * 0.55,
          legL: math.max(0, math.sin(t * 5.0)) * 0.09,
          legR: math.max(0, math.sin(t * 5.0 + math.pi)) * 0.09,
          head: math.sin(t * 2.2) * 0.08,
          breathe: math.sin(t * 5.0),
          raised: true,
        ),
      'fen_nu' => _Pose(
          armL: 0.25 + math.max(0, math.sin(t * 7.0)) * 0.75,
          armR: -0.2 + math.sin(t * 7.0 + 1.2) * 0.15,
          legL: math.max(0, math.sin(t * 7.0)) * 0.11,
          legR: math.max(0, math.sin(t * 7.0 + math.pi)) * 0.04,
          head: -0.05,
          breathe: 0,
          raised: false,
        ),
      'jiao_lv' || 'ya_li' => _Pose(
          armL: math.sin(t * 10.5) * 0.22,
          armR: math.sin(t * 10.5 + 0.7) * 0.22,
          legL: 0.015,
          legR: 0.015,
          head: math.sin(t * 8.0) * 0.07,
          breathe: math.sin(t * 9.0) * 0.4,
          raised: false,
        ),
      'xing_fen' => _Pose(
          armL: 0.45 + math.sin(t * 2.8) * 0.35,
          armR: math.sin(t * 1.8) * 0.12,
          legL: 0.02,
          legR: math.max(0, math.sin(t * 2.8)) * 0.05,
          head: -0.08 + math.sin(t * 1.6) * 0.04,
          breathe: math.sin(t * 2.0),
          raised: true,
        ),
      'shi_luo' => _Pose(
          armL: 0.18 + math.sin(t * 1.1) * 0.08,
          armR: 0.18 + math.sin(t * 1.1 + 0.5) * 0.08,
          legL: 0,
          legR: 0,
          head: 0.12 + math.sin(t * 0.8) * 0.03,
          breathe: math.sin(t * 1.0) * 0.5,
          raised: false,
        ),
      'gan_dong' => _Pose(
          armL: math.sin(t * 1.7) * 0.28,
          armR: math.sin(t * 1.7 + 1.1) * 0.28,
          legL: 0.02,
          legR: 0.02,
          head: math.sin(t * 1.2) * 0.05,
          breathe: math.sin(t * 1.4),
          raised: false,
        ),
      _ => _Pose(
          armL: math.sin(t * 1.3) * 0.24,
          armR: math.sin(t * 1.3 + 0.8) * 0.24,
          legL: math.max(0, math.sin(t * 1.3)) * 0.04,
          legR: math.max(0, math.sin(t * 1.3 + math.pi)) * 0.04,
          head: math.sin(t * 0.8) * 0.04,
          breathe: math.sin(t * 1.4),
          raised: false,
        ),
    };
  }

  static ui.Rect _opaqueBounds(ui.Image image, ByteData data) {
    final w = image.width;
    final h = image.height;
    final bytes = data.buffer.asUint8List();
    var minX = w;
    var minY = h;
    var maxX = 0;
    var maxY = 0;
    for (var y = 0; y < h; y += 2) {
      for (var x = 0; x < w; x += 2) {
        final alpha = bytes[(y * w + x) * 4 + 3];
        if (alpha < 24) continue;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX <= minX || maxY <= minY) {
      return ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    }
    return ui.Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      maxX.toDouble(),
      maxY.toDouble(),
    );
  }
}

class _Pose {
  const _Pose({
    required this.armL,
    required this.armR,
    required this.legL,
    required this.legR,
    required this.head,
    required this.breathe,
    required this.raised,
  });

  final double armL;
  final double armR;
  final double legL;
  final double legR;
  final double head;
  final double breathe;
  final bool raised;
}

/// ImageShader 需要一个 4x4 单位矩阵，避免再引入 vector_math。
class Matrix4Identity {
  static final Float64List storage = Float64List.fromList(const [
    1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1,
  ]);
}
