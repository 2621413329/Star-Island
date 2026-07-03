import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/building/building_depth_scale.dart';
import 'package:stday/island/viewport/island_view_camera.dart';

void main() {
  group('BuildingDepthScale', () {
    test('back buildings render smaller than front buildings', () {
      final back = BuildingDepthScale.forAnchorDy(0.24);
      final front = BuildingDepthScale.forAnchorDy(0.68);
      expect(back, lessThan(front));
      expect(back, closeTo(0.85, 0.01));
      expect(front, closeTo(1.0, 0.01));
    });
  });

  group('IslandViewCamera', () {
    test('Lv20 default zoom is lower than Lv1', () {
      expect(
        IslandViewCamera.defaultZoomForLevel(20),
        lessThan(IslandViewCamera.defaultZoomForLevel(1)),
      );
    });

    test('Lv20 allows wider min zoom for edge buildings', () {
      expect(
        IslandViewCamera.minZoomForLevel(20),
        lessThan(IslandViewCamera.minZoomForLevel(1)),
      );
    });

    test('default zoom fits island growth curve', () {
      final lv20Zoom = IslandViewCamera.defaultZoomForLevel(20);
      final radius = IslandViewCamera.islandRadiusForLevel(20);
      expect(lv20Zoom * radius, closeTo(0.62, 0.08));
    });
  });
}
