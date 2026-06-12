import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/material.dart' show Color;

import '../../../world/behaviors/protagonist_behavior.dart';
import '../island_3d_assets.dart';
import '../island_3d_config.dart';

/// 主角：优先 GLB（hero.glb），否则 3D 白胖 procedural mesh。
class Hero3DComponent extends Component3D {
  Hero3DComponent({required this.expression, required this.prop});

  final String expression;
  final String prop;

  double _time = 0;
  final _behavior = const ProtagonistBehavior();

  static Future<Hero3DComponent> create({
    required Vector3 position,
    required String expression,
    required String prop,
  }) async {
    final hero = Hero3DComponent(expression: expression, prop: prop);
    hero.position.setFrom(position);

    final model = await Island3DAssets.loadGlb(Island3DAssets.heroGlb);
    if (model != null) {
      hero.add(
        ModelComponent(
          model: model,
          scale: Vector3.all(0.85),
          position: Vector3(0, 0, 0),
        ),
      );
      return hero;
    }

    hero.addAll(_buildProceduralBody(prop));
    return hero;
  }

  static List<Component3D> _buildProceduralBody(String prop) {
    const white = Color(0xFFF8F8F8);
    const soft = Color(0xFFECECEC);
    final bodyMat = SpatialMaterial(
      albedoColor: white,
      roughness: 0.42,
      metallic: 0.05,
    );
    final headMat = SpatialMaterial(
      albedoColor: soft,
      roughness: 0.38,
      metallic: 0.04,
    );

    final parts = <Component3D>[
      MeshComponent(
        mesh: CuboidMesh(
          size: Vector3(0.52, 0.68, 0.46),
          material: bodyMat,
        ),
        position: Vector3(0, 0.52, 0),
      ),
      MeshComponent(
        mesh: SphereMesh(radius: 0.28, material: headMat),
        position: Vector3(0, 1.08, 0),
      ),
      MeshComponent(
        mesh: SphereMesh(
          radius: 0.06,
          material: SpatialMaterial(albedoColor: const Color(0xFF66BB6A)),
        ),
        position: Vector3(0, 0.72, 0.24),
      ),
    ];

    if (prop == 'backpack') {
      parts.add(
        MeshComponent(
          mesh: CuboidMesh(
            size: Vector3(0.28, 0.32, 0.18),
            material: SpatialMaterial(
              albedoColor: const Color(0xFF8D6E63),
              roughness: 0.55,
            ),
          ),
          position: Vector3(0, 0.62, -0.22),
        ),
      );
    }
    return parts;
  }

  static Vector3 _mapNormalized(double dx, double dy) {
    final d = Island3DConfig.islandRadius * 1.65;
    return Vector3(
      (dx - 0.5) * d,
      0,
      (dy - 0.5) * d * 0.85,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final sample = _behavior.sample(_time);
    final mapped = _mapNormalized(
      sample.normalizedPos.dx,
      sample.normalizedPos.dy,
    );
    transform.position.setValues(
      mapped.x,
      0.05 + sample.bob * 5.5,
      mapped.z,
    );
    transform.rotation.setFrom(
      Quaternion.axisAngle(Vector3(0, 1, 0), sample.facingYaw),
    );
  }
}
