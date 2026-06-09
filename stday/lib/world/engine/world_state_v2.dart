import 'world_state.dart';

class WorldStateV2 extends WorldState {
  const WorldStateV2({
    required super.island,
    required super.characters,
    required super.buildings,
    required super.flora,
    required super.environment,
    required super.zones,
    required super.decorations,
    required super.paths,
    required super.effects,
    required super.anchors,
    super.companionGender,
  }) : super(schemaVersion: 2);
}
