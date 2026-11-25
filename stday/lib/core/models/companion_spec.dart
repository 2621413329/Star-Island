import 'package:flutter/material.dart';

import '../constants/companion_base_asset.dart';
import '../constants/emotion_catalog.dart';

/// 由 AI / 后端 visual_payload 驱动的小人表演规格。
class CompanionSpec {
  const CompanionSpec({
    required this.expression,
    required this.prop,
    required this.animationType,
    required this.tint,
    this.extraProps = const [],
    this.sceneTitle,
    this.performanceHint,
  });

  final String expression;
  final String prop;
  final String animationType;
  final Color tint;
  final List<String> extraProps;
  final String? sceneTitle;
  final String? performanceHint;

  List<String> get allProps => [
        prop,
        ...extraProps.where((p) => p != prop && p != 'none'),
      ];

  factory CompanionSpec.fromPayload(
    Map<String, dynamic> payload, {
    String fallbackMood = 'calm',
  }) {
    final mood = payload['emotion_tag'] as String? ?? fallbackMood;
    final storedExpr = payload['expression'] as String?;
    final moodAssetId = companionBaseAssetId(normalizeEmotionId(mood));
    var expression =
        storedExpr != null ? companionBaseAssetId(storedExpr) : moodAssetId;
    if (storedExpr != null && expression != moodAssetId) {
      expression = moodAssetId;
    }
    final animationType = (payload['animation_type'] ??
        payload['action_type'] ??
        'wave') as String;
    final tintHex = payload['companion_tint'] as String?;
    return CompanionSpec(
      expression: expression,
      prop: 'none',
      extraProps: const [],
      animationType: animationType,
      tint: _parseHex(tintHex) ?? _defaultTint(mood),
      sceneTitle: payload['scene_title'] as String?,
      performanceHint: payload['performance_hint'] as String?,
    );
  }

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
