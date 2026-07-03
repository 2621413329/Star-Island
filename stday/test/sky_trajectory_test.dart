import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/sky_trajectory.dart';

void main() {
  group('SkyTrajectoryCatalog', () {
    test('every sky decor has a dedicated trajectory entry', () {
      final skyDecors = DecorConfigs.all
          .where(DecorConfigs.isMainIslandSkyDecor)
          .toList(growable: false);
      for (final decor in skyDecors) {
        expect(
          SkyTrajectoryCatalog.hasDedicatedTrajectory(decor.id),
          isTrue,
          reason: '${decor.id} needs SkyTrajectoryCatalog entry',
        );
      }
    });

    test('birds use distinct orbit radii', () {
      final bird01 = SkyTrajectoryCatalog.resolve(
        DecorConfigs.all.firstWhere((d) => d.id == 'bird_01'),
      );
      final bird02 = SkyTrajectoryCatalog.resolve(
        DecorConfigs.all.firstWhere((d) => d.id == 'bird_02'),
      );
      expect(bird01.kind, SkyMotionKind.birdOrbit);
      expect(bird02.kind, SkyMotionKind.birdOrbit);
      expect(bird01.orbitRadiusX, isNot(equals(bird02.orbitRadiusX)));
    });

    test('clouds use cloud drift with different speed bands', () {
      final cloud01 = SkyTrajectoryCatalog.resolve(
        DecorConfigs.all.firstWhere((d) => d.id == 'cloud_01'),
      );
      final cloud03 = SkyTrajectoryCatalog.resolve(
        DecorConfigs.all.firstWhere((d) => d.id == 'cloud_03'),
      );
      expect(cloud01.kind, SkyMotionKind.cloudDrift);
      expect(cloud03.driftSpeedMax, lessThan(cloud01.driftSpeedMax));
    });

    test('butterfly uses figure-eight loop', () {
      final butterfly = SkyTrajectoryCatalog.resolve(
        DecorConfigs.all.firstWhere((d) => d.id == 'butterfly_01'),
      );
      expect(butterfly.kind, SkyMotionKind.butterflyLoop);
      expect(butterfly.loopRadiusPx, greaterThan(40));
    });

    test('ground decor never resolves to cloud drift', () {
      final groundDecors = DecorConfigs.all
          .where(DecorConfigs.isMainIslandGroundDecor)
          .where((d) => d.animated)
          .toList(growable: false);
      for (final decor in groundDecors) {
        final trajectory = SkyTrajectoryCatalog.resolve(decor);
        expect(
          trajectory.kind,
          SkyMotionKind.groundFixed,
          reason: '${decor.id} should stay anchored on island',
        );
      }
    });
  });

  group('SkyTrajectoryBuilder', () {
    final viewport = Vector2(800, 600);
    final center = Vector2(400, 240);

    test('ellipse orbit is centered on decor anchor', () {
      const definition = SkyTrajectoryDefinition(
        kind: SkyMotionKind.birdOrbit,
        orbitRadiusX: 0.2,
        orbitRadiusY: 0.08,
      );
      final path = SkyTrajectoryBuilder.buildEllipseOrbit(
        center: center,
        viewportSize: viewport,
        definition: definition,
      );
      final bounds = path.getBounds();
      expect(bounds.center.dx, closeTo(center.x, 1));
      expect(bounds.center.dy, closeTo(center.y, 1));
      expect(bounds.width, closeTo(viewport.x * 0.4, 2));
    });

    test('figure-eight path closes near origin', () {
      const radius = 50.0;
      final path = SkyTrajectoryBuilder.buildFigureEight(
        center: center,
        radius: radius,
      );
      final bounds = path.getBounds();
      expect(bounds.center.dx, closeTo(center.x, 1));
      expect(bounds.height, greaterThan(radius * 0.8));
    });

    test('seagull orbit is wider than single bird', () {
      final seagull = SkyTrajectoryCatalog.resolve(
        DecorConfigs.all.firstWhere((d) => d.id == 'seagull_group_01'),
      );
      final bird02 = SkyTrajectoryCatalog.resolve(
        DecorConfigs.all.firstWhere((d) => d.id == 'bird_02'),
      );
      expect(seagull.orbitRadiusX, greaterThan(bird02.orbitRadiusX));
    });
  });
}
