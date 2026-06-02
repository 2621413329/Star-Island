import 'package:flutter/material.dart';

/// 由 AI / 后端 visual_payload 驱动的小人表演规格。
class CompanionSpec {
  const CompanionSpec({
    required this.expression,
    required this.prop,
    required this.animationType,
    required this.tint,
    this.sceneTitle,
    this.performanceHint,
  });

  final String expression;
  final String prop;
  final String animationType;
  final Color tint;
  final String? sceneTitle;
  final String? performanceHint;

  factory CompanionSpec.fromPayload(Map<String, dynamic> payload, {String fallbackMood = 'calm'}) {
    final tintHex = payload['companion_tint'] as String?;
    return CompanionSpec(
      expression: payload['expression'] as String? ?? _exprFromMood(fallbackMood),
      prop: payload['prop'] as String? ?? 'none',
      animationType: (payload['animation_type'] ?? payload['action_type'] ?? 'wave') as String,
      tint: _parseHex(tintHex) ?? _defaultTint(fallbackMood),
      sceneTitle: payload['scene_title'] as String?,
      performanceHint: payload['performance_hint'] as String?,
    );
  }

  static String _exprFromMood(String mood) => switch (mood) {
        'happy' => 'happy',
        'sad' => 'sad',
        'angry' => 'angry',
        'thinking' => 'thinking',
        _ => 'calm',
      };

  static Color _defaultTint(String mood) => switch (mood) {
        'happy' => const Color(0xFFFFD54F),
        'sad' => const Color(0xFF90A4AE),
        'angry' => const Color(0xFFFF8A65),
        'thinking' => const Color(0xFFB0BEC5),
        _ => const Color(0xFFA8DFCF),
      };

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
    final v = int.tryParse(hex.substring(1), radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
}
