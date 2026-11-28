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

  test('two fingers zoom the main island and do not drag it', () {
    const size = Size(400, 800);
    final session = BoardPointerSession(viewportSize: size);
    const left = Offset(150, 360);
    const right = Offset(250, 360);
    session
      ..down(1, left)
      ..down(2, right);
    // 两指一起平移，间距不变：不能把岛面或名称拖走。
    session
      ..move(1, left + const Offset(40, 30))
      ..move(2, right + const Offset(40, 30));
    expect(session.zoom, 1);
    expect(session.pan, Offset.zero);

    session
      ..move(1, const Offset(80, 360))
      ..move(2, const Offset(320, 360));
    expect(session.zoom, greaterThan(1.4));
    final focal = mapBoardCameraPoint(
      neutralPoint: const Offset(200, 360),
      size: size,
      zoom: session.zoom,
      rotation: 0,
      pan: session.pan,
    );
    expect(focal.dx, closeTo(200, 0.5));
    expect(focal.dy, closeTo(360, 0.5));
    expect(session.up(2), isFalse);
    expect(session.up(1), isFalse);
  });

  test('one finger does not pan until the island is zoomed', () {
    final session = BoardPointerSession(viewportSize: const Size(400, 800));
    session.down(1, const Offset(200, 400));
    session.move(1, const Offset(120, 320));
    expect(session.zoom, 1);
    expect(session.pan, Offset.zero);
    expect(session.up(1), isFalse);

    session.zoom = 1.8;
    session.down(1, const Offset(200, 400));
    session.move(1, const Offset(160, 400));
    expect(session.zoom, 1.8);
    expect(session.pan.dx, lessThan(-18));
    expect(session.up(1), isFalse);
  });
}
