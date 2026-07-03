import 'dart:ui';

import '../../../common/island_contracts/decor_config.dart';
import '../../../common/island_contracts/decor_placement_resolver.dart';
import '../../../island/debug/main_island_debug_overlay.dart';
import '../../engine/world_state.dart';
import 'world_layer.dart';

/// 主岛布局调试层（仅 debug 模式启用）。
class MainIslandDebugOverlayLayer extends WorldLayer {
  MainIslandDebugOverlayLayer() : super(layerPriority: 1000);

  Map<String, Offset> _decorPositions = const {};

  @override
  void onWorldStateChanged(WorldState worldState) {
    final level =
        worldState.characters.isEmpty ? 1 : worldState.characters.first.level;
    _decorPositions = const DecorPlacementResolver().resolve(
      DecorConfigs.unlockedMainIslandAt(level),
      buildings: worldState.buildings,
    );
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final s = sceneSize;
    if (s.x < 1 || s.y < 1) return;
    final level =
        state.characters.isEmpty ? 1 : state.characters.first.level;
    MainIslandDebugOverlay.draw(
      canvas,
      Size(s.x, s.y),
      worldState: state,
      decorPositions: _decorPositions,
      userLevel: level,
    );
  }
}
