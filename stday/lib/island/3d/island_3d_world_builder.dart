import 'dart:ui' show Offset;

import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/material.dart' show Color;

import '../../island/config/building_config.dart';
import '../../island/config/island_terrain_config.dart';
import '../../world/engine/world_state.dart';
import 'components/hero_3d_component.dart';
import 'components/island_3d_group.dart';
import 'island_3d_assets.dart';
import 'island_3d_config.dart';

/// 将 [WorldState] 转为 3D 场景节点。
class Island3DWorldBuilder {
  Island3DWorldBuilder._();

  static Future<List<Component3D>> build({
    required WorldState state,
    required bool compact,
  }) async {
    final out = <Component3D>[];
    out.addAll(_environment(compact));
    out.addAll(await _islandTerrain());
    out.addAll(_terrainLayers(state));
    out.addAll(await _flora(state));
    out.add(await _hero(state));
    if (state.island.prosperityTier >= 1) {
      out.add(await _centerTree(state.island.prosperityTier));
    }
    out.addAll(_buildings(state));
    return out;
  }

  static List<Component3D> _environment(bool compact) {
    final sea = SpatialMaterial(
      albedoColor: const Color(0xFF5BB5D5),
      roughness: 0.25,
      metallic: 0.08,
    );
    final seaSize = compact ? 28.0 : 36.0;
    return [
      LightComponent.ambient(
        color: const Color(0xFFFFF8E1),
        intensity: 0.85,
      ),
      LightComponent.point(
        position: Vector3(4, 9, 6),
        color: const Color(0xFFFFFFFF),
        intensity: compact ? 18 : 24,
      ),
      MeshComponent(
        mesh: PlaneMesh(
          size: Vector2(seaSize, seaSize),
          material: sea,
        ),
        position: Vector3(0, -0.08, 0),
      ),
    ];
  }

  static Future<List<Component3D>> _islandTerrain() async {
    final ground = await Island3DAssets.loadGlb(Island3DAssets.islandGroundGlb);
    if (ground != null) {
      return [
        ModelComponent(
          model: ground,
          position: Vector3(0, 0, 0),
          scale: Vector3.all(1.0),
        ),
      ];
    }

    final r = Island3DConfig.islandRadius;
    final h = Island3DConfig.islandHeight;
    final grass = SpatialMaterial(
      albedoColor: const Color(0xFF7EC87A),
      roughness: 0.72,
      metallic: 0.02,
    );
    final rim = SpatialMaterial(
      albedoColor: const Color(0xFFB0BEC5),
      roughness: 0.82,
      metallic: 0.12,
    );
    return [
      MeshComponent(
        mesh: CylinderMesh(
          radius: r,
          height: h,
          material: grass,
        ),
        position: Vector3(0, h * 0.5, 0),
      ),
      MeshComponent(
        mesh: CylinderMesh(
          radius: r + 0.18,
          height: Island3DConfig.rimHeight,
          material: rim,
        ),
        position: Vector3(0, h * 0.15, 0),
      ),
    ];
  }

  static Future<List<Component3D>> _flora(WorldState state) async {
    final out = <Component3D>[];
    for (final f in state.flora) {
      final pos = _mapNormalized(f.position);
      if (f.floraId.startsWith('rock')) {
        final glb = await Island3DAssets.loadGlb(Island3DAssets.rockGlb);
        if (glb != null) {
          out.add(
            ModelComponent(
              model: glb,
              position: pos + Vector3(0, 0.05, 0),
              scale: Vector3.all(0.55 + f.growth * 0.35),
            ),
          );
        } else {
          out.add(_rockAt(pos, f.growth));
        }
        continue;
      }
      if (f.kind == FloraKind.tree) {
        out.add(await _treeAt(pos, f.floraId, f.growth));
      }
    }
    return out;
  }

  static List<Component3D> _terrainLayers(WorldState state) {
    final tier = state.island.prosperityTier;
    if (tier <= 1) return const [];

    final out = <Component3D>[];
    final grass = SpatialMaterial(
      albedoColor: const Color(0xFF7EC87A),
      roughness: 0.72,
    );
    final stone = SpatialMaterial(
      albedoColor: const Color(0xFFB0BEC5),
      roughness: 0.82,
    );

    if (tier >= 2) {
      out.add(
        MeshComponent(
          mesh: CylinderMesh(radius: 1.05, height: 0.08, material: grass),
          position: Vector3(0, 0.12, -0.15),
        ),
      );
      out.add(
        MeshComponent(
          mesh: CylinderMesh(radius: 0.72, height: 0.06, material: grass),
          position: Vector3(-0.55, 0.18, 0.05),
        ),
      );
      out.add(
        MeshComponent(
          mesh: CylinderMesh(radius: 0.68, height: 0.06, material: grass),
          position: Vector3(0.58, 0.16, 0.08),
        ),
      );
    }
    if (tier >= 3) {
      for (final pad in IslandTerrainConfig.padsForTier(tier)) {
        final pos = _mapNormalized(pad.anchor);
        out.add(
          MeshComponent(
            mesh: CylinderMesh(
              radius: 0.22 + pad.size * 0.8,
              height: 0.05,
              material: stone,
            ),
            position: pos + Vector3(0, -0.12 - pad.drop * 2, 0),
          ),
        );
      }
    }
    if (tier >= 4) {
      out.add(
        MeshComponent(
          mesh: CylinderMesh(radius: 0.45, height: 0.05, material: grass),
          position: Vector3(0, 0.22, -0.35),
        ),
      );
    }
    return out;
  }

  static List<Component3D> _buildings(WorldState state) {
    final out = <Component3D>[];
    for (final b in state.buildings) {
      final pos = _mapNormalized(b.anchor);
      final def = IslandBuildingConfig.find(b.definitionId);
      final depth = def?.depthScale ?? 1.0;
      switch (b.definitionId) {
        case 'growth_lighthouse':
          out.add(_lighthouseAt(pos, b.level, depth));
        case 'growth_library':
          out.add(_libraryAt(pos, b.level, depth));
        case 'growth_plaza':
          out.add(_memoryPlazaAt(pos, b.level, depth));
        default:
          break;
      }
    }
    return out;
  }

  static Component3D _lighthouseAt(Vector3 pos, int level, double depth) {
    final scale = (0.85 + level * 0.08) * depth;
    final stone = SpatialMaterial(
      albedoColor: const Color(0xFFCFD8DC),
      roughness: 0.78,
    );
    final glow = SpatialMaterial(
      albedoColor: const Color(0xFFFFF59D),
      roughness: 0.2,
      metallic: 0.1,
    );
    return Island3DGroup(
      position: pos + Vector3(0, 0.05, 0),
      scale: Vector3.all(scale),
      children: [
        MeshComponent(
          mesh: CylinderMesh(radius: 0.22, height: 0.95, material: stone),
          position: Vector3(0, 0.48, 0),
        ),
        MeshComponent(
          mesh: SphereMesh(radius: 0.18, material: glow),
          position: Vector3(0, 1.05, 0),
        ),
      ],
    );
  }

  static Component3D _libraryAt(Vector3 pos, int level, double depth) {
    final scale = (0.9 + level * 0.06) * depth;
    final wall = SpatialMaterial(
      albedoColor: const Color(0xFFD7CCC8),
      roughness: 0.7,
    );
    final roof = SpatialMaterial(
      albedoColor: const Color(0xFF8D6E63),
      roughness: 0.65,
    );
    return Island3DGroup(
      position: pos + Vector3(0, 0.05, 0),
      scale: Vector3.all(scale),
      children: [
        MeshComponent(
          mesh: CuboidMesh(size: Vector3(0.72, 0.52, 0.58), material: wall),
          position: Vector3(0, 0.26, 0),
        ),
        MeshComponent(
          mesh: ConeMesh(radius: 0.52, height: 0.38, material: roof),
          position: Vector3(0, 0.68, 0),
        ),
      ],
    );
  }

  static Component3D _memoryPlazaAt(Vector3 pos, int level, double depth) {
    final scale = (0.88 + level * 0.05) * depth;
    final slab = SpatialMaterial(
      albedoColor: const Color(0xFFB0BEC5),
      roughness: 0.82,
    );
    final pillar = SpatialMaterial(
      albedoColor: const Color(0xFFECEFF1),
      roughness: 0.75,
    );
    return Island3DGroup(
      position: pos + Vector3(0, 0.04, 0),
      scale: Vector3.all(scale),
      children: [
        MeshComponent(
          mesh: CylinderMesh(radius: 0.55, height: 0.06, material: slab),
          position: Vector3(0, 0.03, 0),
        ),
        for (final dx in [-0.28, 0.28])
          MeshComponent(
            mesh: CylinderMesh(radius: 0.06, height: 0.42, material: pillar),
            position: Vector3(dx, 0.24, 0),
          ),
      ],
    );
  }

  static Future<Component3D> _hero(WorldState state) async {
    if (state.characters.isEmpty) {
      return Hero3DComponent.create(
        position: Vector3(0, 0.05, 0),
        expression: 'calm',
        prop: 'none',
      );
    }
    final protagonist = state.characters.firstWhere(
      (c) => c.id == 'protagonist',
      orElse: () => state.characters.first,
    );
    final pos = _mapNormalized(protagonist.normalizedPos);
    return Hero3DComponent.create(
      position: pos + Vector3(0, 0.05, 0),
      expression: protagonist.expression,
      prop: protagonist.prop,
    );
  }

  static Future<Component3D> _centerTree(int tier) async {
    final scale = 0.9 + tier * 0.08;
    final glb = await Island3DAssets.loadGlb(Island3DAssets.treePuffyGlb);
    if (glb != null) {
      return ModelComponent(
        model: glb,
        position: Vector3(0, 0.1, -0.6),
        scale: Vector3.all(scale),
      );
    }
    return _puffyTreeMesh(
      Vector3(0, 0.05, -0.55),
      scale * 1.1,
    );
  }

  static Future<Component3D> _treeAt(
    Vector3 pos,
    String floraId,
    double growth,
  ) async {
    final scale = 0.65 + growth * 0.45;
    final isPine = floraId.contains('pine');
    final path =
        isPine ? Island3DAssets.treePineGlb : Island3DAssets.treePuffyGlb;
    final glb = await Island3DAssets.loadGlb(path);
    if (glb != null) {
      return ModelComponent(
        model: glb,
        position: pos,
        scale: Vector3.all(scale),
      );
    }
    return isPine
        ? _pineTreeMesh(pos, scale)
        : _puffyTreeMesh(pos, scale);
  }

  static Component3D _pineTreeMesh(Vector3 pos, double scale) {
    final mat = SpatialMaterial(
      albedoColor: const Color(0xFF43A047),
      roughness: 0.65,
    );
    final trunk = SpatialMaterial(
      albedoColor: const Color(0xFF795548),
      roughness: 0.8,
    );
    return Island3DGroup(
      position: pos,
      scale: Vector3.all(scale),
      children: [
        MeshComponent(
          mesh: CylinderMesh(radius: 0.08, height: 0.45, material: trunk),
          position: Vector3(0, 0.22, 0),
        ),
        MeshComponent(
          mesh: ConeMesh(radius: 0.42, height: 0.75, material: mat),
          position: Vector3(0, 0.72, 0),
        ),
        MeshComponent(
          mesh: ConeMesh(radius: 0.32, height: 0.55, material: mat),
          position: Vector3(0, 1.05, 0),
        ),
      ],
    );
  }

  static Component3D _puffyTreeMesh(Vector3 pos, double scale) {
    final mat = SpatialMaterial(
      albedoColor: const Color(0xFF66BB6A),
      roughness: 0.58,
    );
    return Island3DGroup(
      position: pos,
      scale: Vector3.all(scale),
      children: [
        MeshComponent(
          mesh: CylinderMesh(
            radius: 0.07,
            height: 0.38,
            material: SpatialMaterial(albedoColor: const Color(0xFF6D4C41)),
          ),
          position: Vector3(0, 0.19, 0),
        ),
        MeshComponent(
          mesh: SphereMesh(radius: 0.32, material: mat),
          position: Vector3(0, 0.62, 0),
        ),
        MeshComponent(
          mesh: SphereMesh(radius: 0.22, material: mat),
          position: Vector3(-0.18, 0.52, 0.05),
        ),
        MeshComponent(
          mesh: SphereMesh(radius: 0.2, material: mat),
          position: Vector3(0.16, 0.55, -0.04),
        ),
      ],
    );
  }

  static Component3D _rockAt(Vector3 pos, double growth) {
    final scale = 0.55 + growth * 0.35;
    return MeshComponent(
      mesh: SphereMesh(
        radius: 0.22,
        material: SpatialMaterial(
          albedoColor: const Color(0xFF78909C),
          roughness: 0.88,
        ),
      ),
      position: pos + Vector3(0, 0.12 * scale, 0),
      scale: Vector3(scale * 1.1, scale * 0.65, scale),
    );
  }

  static Vector3 _mapNormalized(Offset n) {
    final d = Island3DConfig.islandRadius * 1.65;
    return Vector3(
      (n.dx - 0.5) * d,
      0,
      (n.dy - 0.5) * d * 0.85,
    );
  }
}
