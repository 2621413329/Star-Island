import '../../core/models/character_mood.dart';
import '../engine/growth_event.dart';

class AccessoryBundle {
  const AccessoryBundle({
    this.head,
    this.hand,
    this.back,
    this.aura,
    this.ground,
  });

  final String? head;
  final String? hand;
  final String? back;
  final String? aura;
  final String? ground;

  List<String> get allIds =>
      [head, hand, back, aura, ground].whereType<String>().toList();
}

class AccessorySystem {
  AccessoryBundle resolve(CharacterMood mood, GrowthEvent event) {
    final prop = event.prop;
    final type = event.type;

    String? hand = _handFromProp(prop);
    String? back = _backFromType(type, mood);
    String? aura = _auraFromMood(mood);
    String? head = _headFromMood(mood, type);

    if (hand == null && type == GrowthEventType.reading) {
      hand = 'book';
    }
    if (hand == null && type == GrowthEventType.exercise) {
      hand = 'ball';
    }
    if (back == null && type == GrowthEventType.helpFriend) {
      back = 'friendship_ribbon';
    }

    return AccessoryBundle(head: head, hand: hand, back: back, aura: aura);
  }

  static String? _handFromProp(String prop) => switch (prop) {
        'workbook' || 'book' || 'exam_paper' => 'book',
        'ball' || 'badminton_racket' => 'ball',
        'game_controller' => 'gamepad',
        'running_shoes' => 'shoes',
        'heart' => 'heart',
        'friends' || 'chat_bubbles' => 'chat',
        'music' => 'music_note',
        _ => null,
      };

  static String? _backFromType(GrowthEventType type, CharacterMood mood) =>
      switch (type) {
        GrowthEventType.exercise when mood == CharacterMood.proud => 'medal',
        GrowthEventType.hobby => 'pinwheel',
        GrowthEventType.artCreate => 'palette',
        _ => null,
      };

  static String? _auraFromMood(CharacterMood mood) => switch (mood) {
        CharacterMood.happy => 'sparkle',
        CharacterMood.proud => 'golden_glow',
        CharacterMood.anxious => 'mist',
        CharacterMood.angry => 'steam',
        _ => null,
      };

  static String? _headFromMood(CharacterMood mood, GrowthEventType type) {
    if (type == GrowthEventType.reading) return 'glasses';
    if (mood == CharacterMood.happy) return 'sunflower';
    return null;
  }
}
