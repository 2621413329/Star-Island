import '../engine/world_state.dart';

class NearbyBuildingRenderState {
  const NearbyBuildingRenderState({
    required this.expression,
    required this.prop,
    required this.animationKey,
    required this.showHint,
  });

  final String expression;
  final String prop;
  final String animationKey;
  final bool showHint;
}

/// 第三步改进：将“靠近建筑时角色如何变化”独立成可扩展行为策略。
class NearbyBuildingBehavior {
  const NearbyBuildingBehavior();

  NearbyBuildingRenderState resolve({
    required CharacterSnapshot character,
    required BuildingSnapshot? nearbyBuilding,
  }) {
    if (nearbyBuilding == null) {
      return NearbyBuildingRenderState(
        expression: character.expression,
        prop: character.prop,
        animationKey: character.animationKey,
        showHint: false,
      );
    }

    return switch (nearbyBuilding.definitionId) {
      'library' => const NearbyBuildingRenderState(
          expression: 'thinking',
          prop: 'workbook',
          animationKey: 'slump_read',
          showHint: true,
        ),
      'playground' => const NearbyBuildingRenderState(
          expression: 'happy',
          prop: 'ball',
          animationKey: 'swing',
          showHint: true,
        ),
      'friendship_tree' => const NearbyBuildingRenderState(
          expression: 'happy',
          prop: 'heart',
          animationKey: 'comfort',
          showHint: true,
        ),
      'art_studio' => const NearbyBuildingRenderState(
          expression: 'calm',
          prop: 'music',
          animationKey: 'think',
          showHint: true,
        ),
      _ => NearbyBuildingRenderState(
          expression: character.expression,
          prop: character.prop,
          animationKey: character.animationKey,
          showHint: false,
        ),
    };
  }
}
