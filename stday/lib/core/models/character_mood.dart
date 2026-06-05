/// 角色与世界环境共用的情绪枚举。
enum CharacterMood {
  happy,
  calm,
  anxious,
  angry,
  proud;

  static CharacterMood fromString(String? raw) => switch (raw) {
        'happy' => CharacterMood.happy,
        'sad' => CharacterMood.anxious,
        'thinking' => CharacterMood.calm,
        'angry' => CharacterMood.angry,
        'proud' => CharacterMood.proud,
        _ => CharacterMood.calm,
      };

  String get id => switch (this) {
        CharacterMood.happy => 'happy',
        CharacterMood.calm => 'calm',
        CharacterMood.anxious => 'anxious',
        CharacterMood.angry => 'angry',
        CharacterMood.proud => 'proud',
      };
}
