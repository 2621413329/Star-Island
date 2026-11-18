import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/src/game/transform2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/models/mood_island_config.dart';
import 'package:stday/world/engine/world_state.dart';
import 'package:stday/world/scene/world_board_camera.dart';
import 'package:stday/world/scene/world_render_probe.dart';
import 'package:stday/world/scene/world_scene.dart';

void main() {
  setUp(() {
    WorldRenderControls.freezeMotion = false;
    WorldRenderControls.forceFullPaint = false;
    WorldRenderControls.pauseDynamicPasses = false;
    WorldRenderControls.rebakeOnCamera = false;
    WorldRenderControls.catchUpTicks = 0;
    WorldRenderProbe.enabled = true;
    WorldRenderProbe.logSummaries = false;
    WorldRenderProbe.reset();
  });

  test('static picture camera matches the flame viewfinder', () {
    const world = Offset(100, 120);
    const sizes = [Size(300, 500), Size(400, 700), Size(1080, 2400)];
    const focuses = [Offset(150, 250), Offset(40, 90)];
    const zooms = [0.65, 1.0, 1.8, 5.0];
    const rotations = [0.0, 0.25, -0.25, 1.2];

    for (final size in sizes) {
      for (final focus in focuses) {
        for (final zoom in zooms) {
          for (final rotation in rotations) {
            final center = Offset(size.width / 2, size.height / 2);
            final neutral = center + (world - focus);
            final mapped = mapBoardCameraPoint(
              neutralPoint: neutral,
              size: size,
              zoom: zoom,
              rotation: rotation,
            );
            final transform = Transform2D()
              ..position = Vector2(center.dx, center.dy)
              ..offset = Vector2(-focus.dx, -focus.dy)
              ..scale = Vector2.all(zoom)
              ..angle = -rotation;
            final screen =
                transform.localToGlobal(Vector2(world.dx, world.dy));
            expect(mapped.dx, closeTo(screen.x, 1e-3), reason: '$size $zoom $rotation');
            expect(mapped.dy, closeTo(screen.y, 1e-3), reason: '$size $zoom $rotation');
            final back = mapInverseBoardCameraPoint(
              zoomedPoint: mapped,
              size: size,
              zoom: zoom,
              rotation: rotation,
            );
            expect(back.dx, closeTo(neutral.dx, 1e-3));
            expect(back.dy, closeTo(neutral.dy, 1e-3));
          }
        }
      }
    }
  });

  test('percentile uses the upper sample so a spike is visible', () {
    expect(WorldRenderProbe.percentileUpper([1, 2, 3, 4, 100], 0.95), 100);
    expect(WorldRenderProbe.percentileUpper(const [], 0.95), 0);
  });

  testWidgets('zoom reapplies the static picture without recording it again',
      (tester) async {
    final key = GlobalKey<WorldSceneWidgetState>();
    await _pumpScene(tester, key);
    await _untilPicturesSettle(tester);

    final outer = WorldRenderProbe.outerPictureRecorders;
    final recorded = WorldRenderProbe.pictureRecorders;
    final invalidations = WorldRenderProbe.invalidations;
    final cameras = WorldRenderProbe.cameraTransforms;
    expect(outer, greaterThan(0));

    key.currentState!.setViewTransform(zoom: 1.8, rotationRadians: 0.25);
    await tester.pump();

    expect(WorldRenderProbe.outerPictureRecorders, outer);
    expect(WorldRenderProbe.pictureRecorders, recorded);
    expect(WorldRenderProbe.invalidations, invalidations);
    expect(WorldRenderProbe.cameraTransforms, greaterThan(cameras));
  });

  testWidgets('rebaking the camera records the static pictures again',
      (tester) async {
    WorldRenderControls.rebakeOnCamera = true;
    final key = GlobalKey<WorldSceneWidgetState>();
    await _pumpScene(tester, key);
    await _untilPicturesSettle(tester);

    final outer = WorldRenderProbe.outerPictureRecorders;
    key.currentState!.setViewTransform(zoom: 1.6);
    await tester.pump();

    expect(WorldRenderProbe.outerPictureRecorders - outer, 2);
  });

  testWidgets('pausing dynamic passes keeps the ticker but stops update',
      (tester) async {
    WorldRenderControls.pauseDynamicPasses = true;
    final key = GlobalKey<WorldSceneWidgetState>();
    await _pumpScene(tester, key);
    await _untilPicturesSettle(tester);

    expect(WorldRenderProbe.updates, 0);
    expect(WorldRenderProbe.tickers, greaterThan(0));
    final tickers = WorldRenderProbe.tickers;
    await tester.pump(const Duration(milliseconds: 120));
    expect(WorldRenderProbe.updates, 0);
    expect(WorldRenderProbe.tickers, greaterThan(tickers));
  });

  testWidgets('recording a static picture does not write the live viewfinder',
      (tester) async {
    final key = GlobalKey<WorldSceneWidgetState>();
    await _pumpScene(tester, key, width: 360, height: 540);
    await _untilPicturesSettle(tester);
    final scene = key.currentState!.debugScene;

    scene.setViewTransform(zoom: 1.8, rotationRadians: -0.25);
    var writes = 0;
    void onTransform() => writes++;
    scene.camera.viewfinder.transform.addListener(onTransform);
    await tester.pump();
    scene.camera.viewfinder.transform.removeListener(onTransform);

    expect(writes, 0);
    expect(scene.camera.viewfinder.zoom, closeTo(1.8, 1e-5));
    expect(scene.camera.viewfinder.angle, closeTo(-0.25, 1e-5));
    final laidOut = tester.getSize(find.byType(WorldSceneWidget));
    expect(scene.size.x, closeTo(laidOut.width, 0.5));
    expect(scene.size.y, closeTo(laidOut.height, 0.5));
    expect(laidOut, const Size(360, 540));
    expect(
      scene.camera.viewfinder.transform.position.x,
      closeTo(scene.size.x / 2, 0.5),
    );
    expect(
      scene.camera.viewfinder.transform.position.y,
      closeTo(scene.size.y / 2, 0.5),
    );
  });

  testWidgets('camera focus offset follows the mounted viewport', (tester) async {
    final key = GlobalKey<WorldSceneWidgetState>();
    final base = WorldState.empty(_style());
    final focused = WorldState(
      island: base.island,
      characters: base.characters,
      buildings: base.buildings,
      flora: base.flora,
      environment: base.environment,
      anchors: const [
        WorldAnchorSnapshot(
          id: 'focus',
          type: 'test',
          position: Offset(0.2, 0.8),
          visualWeight: 1,
          cameraFocus: true,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
        child: SizedBox(
          width: 360,
          height: 480,
          child: WorldSceneWidget(
            key: key,
            worldState: focused,
            retainStaticBoard: true,
            enableDecor: false,
            showBuildings: false,
            showCharacters: false,
            islandOnly: true,
          ),
        ),
        ),
      ),
    );
    await _untilPicturesSettle(tester);
    final scene = key.currentState!.debugScene;
    final size = scene.size;
    final center = size / 2;
    final anchor = Vector2(0.2 * size.x, 0.8 * size.y);
    final expected = center + (anchor - center) * 0.22;
    expect(scene.camera.viewfinder.position.x, closeTo(expected.x, 0.5));
    expect(scene.camera.viewfinder.position.y, closeTo(expected.y, 0.5));
  });
}

Future<void> _pumpScene(
  WidgetTester tester,
  GlobalKey<WorldSceneWidgetState> key, {
  double width = 180,
  double height = 320,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: WorldSceneWidget(
          key: key,
          worldState: WorldState.empty(_style()),
          retainStaticBoard: true,
          enableDecor: false,
          showBuildings: false,
          showCharacters: false,
          islandOnly: true,
        ),
        ),
      ),
    ),
  );
}

Future<void> _untilPicturesSettle(WidgetTester tester) async {
  var last = -1;
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    final now = WorldRenderProbe.outerPictureRecorders;
    if (now > 0 && now == last) return;
    last = now;
  }
  fail('static pictures did not settle at $last recordings');
}

MoodIslandConfig _style() {
  return const MoodIslandConfig(
    moodId: 'calm',
    styleKey: 'growth_world',
    label: '成长岛',
    skyTop: Color(0xFFE3F2FD),
    skyBottom: Color(0xFFB3E5FC),
    sea: Color(0xFF4FC3F7),
    sand: Color(0xFFECEFF1),
    accent: Color(0xFFFFCC80),
    grass: Color(0xFF81C784),
    flower: Color(0xFFF8BBD0),
    waveIntensity: 0.35,
    rain: false,
    wind: false,
    islandShape: 'growth_world',
    biome: 'growth_world',
    ambientParticles: 'sparkle',
  );
}
