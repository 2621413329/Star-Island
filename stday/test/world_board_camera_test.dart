import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/world/scene/world_board_camera.dart';

void main() {
  test('pinch keeps the point under the fingers', () {
    const size = Size(400, 800);
    const startZoom = 1.4;
    const startPan = Offset(30, -20);
    const fingers = Offset(140, 260);
    final world = mapInverseBoardCameraPoint(
      zoomedPoint: fingers,
      size: size,
      zoom: startZoom,
      rotation: 0,
      pan: startPan,
    );
    for (final zoom in [0.7, 1.0, 1.4, 2.2]) {
      final pan = panForAnchoredZoom(
        worldFocal: world,
        screenFocal: fingers,
        size: size,
        zoom: zoom,
      );
      final screen = mapBoardCameraPoint(
        neutralPoint: world,
        size: size,
        zoom: zoom,
        rotation: 0,
        pan: pan,
      );
    expect(screen.dx, closeTo(fingers.dx, 0.01));
    expect(screen.dy, closeTo(fingers.dy, 0.01));
    }
  });
}
