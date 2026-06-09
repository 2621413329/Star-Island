import 'dart:ui';

import 'world_layer.dart';

class UIOverlayLayer extends WorldLayer {
  UIOverlayLayer() : super(layerPriority: 30);

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final size = sceneSize;
    if (state.anchors.isNotEmpty) {
      final anchor = state.anchors.first;
      final p =
          Offset(anchor.position.dx * size.x, anchor.position.dy * size.y);
      final r = 18 + anchor.visualWeight * 18;
      canvas.drawOval(
        Rect.fromCenter(
          center: p + const Offset(0, 6),
          width: r * 1.6,
          height: r * 0.42,
        ),
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      return;
    }
    for (final zone in state.zones) {
      if (zone.id != 'CenterZone') continue;
      final rect = Rect.fromLTWH(
        zone.bounds.left * size.x,
        zone.bounds.top * size.y,
        zone.bounds.width * size.x,
        zone.bounds.height * size.y,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }
}
