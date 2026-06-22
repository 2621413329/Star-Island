import 'package:flutter/material.dart';

import '../utils/companion_prop_infer.dart';

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
    int? inferSeed,
  }) {
    final mood = payload['emotion_tag'] as String? ?? fallbackMood;
    final note = payload['note_hint'] as String?;
    final hasNewSchema =
        payload.containsKey('expression') || payload.containsKey('prop');
    final aiProp = payload['prop'] as String?;
    final eventTags = (payload['event_tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final storedProp = payload['prop'] as String?;
    final storedExtras = (payload['extra_props'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where(CompanionPropInfer.isAllowedProp)
            .toList() ??
        const <String>[];
    final inferTags = eventTags.isNotEmpty
        ? eventTags
        : [_legacyTag(payload['base_scene'] as String?)];
    final inferred = CompanionPropInfer.inferProps(
      inferTags,
      note: note,
      aiProp: hasNewSchema ? aiProp : null,
      seed: inferSeed,
    );
    final inferredProp = inferred.isNotEmpty ? inferred.first : null;
    final storedAllowed =
        storedProp != null && CompanionPropInfer.isAllowedProp(storedProp);
    final prop = inferredProp ?? (storedAllowed ? storedProp : 'stars');
    final extraProps = <String>[
      ...inferred.skip(1),
      if (inferred.isEmpty && storedAllowed && storedProp != prop) storedProp,
      if (inferred.isEmpty) ...storedExtras,
    ].where((p) => p != prop).toSet().toList();
    final storedExpr = payload['expression'] as String?;
    var expression = storedExpr ?? _exprFromMood(mood);
    if (storedExpr != null && !_expressionMatchesMood(storedExpr, mood)) {
      expression = _exprFromMood(mood);
    }
    var animationType = (payload['animation_type'] ??
        payload['action_type'] ??
        'wave') as String;
    if (!hasNewSchema && (payload['animation_type'] == null)) {
      animationType = _animFromLegacy(mood, prop, note, animationType);
    }
    final tintHex = payload['companion_tint'] as String?;
    return CompanionSpec(
      expression: expression,
      prop: prop,
      extraProps: extraProps,
      animationType: animationType,
      tint: _parseHex(tintHex) ?? _defaultTint(mood),
      sceneTitle: payload['scene_title'] as String?,
      performanceHint: payload['performance_hint'] as String?,
    );
  }

  static String _legacyTag(String? baseScene) => switch (baseScene) {
        'study' => '学习',
        'friendship' => '朋友',
        'sport' => '运动',
        'family' => '家庭',
        'hobby' => '兴趣',
        _ => '其它',
      };

  static String _animFromLegacy(
      String mood, String prop, String? note, String fallbackAction) {
    if ((prop == 'workbook' || prop == 'exam_paper') &&
        (mood == 'sad' || mood == 'thinking' || mood == 'angry')) {
      return 'slump_read';
    }
    if (prop == 'game_controller') {
      return mood == 'happy' ? 'celebrate' : 'think';
    }
    if (prop == 'running_shoes') {
      return mood == 'happy' ? 'cheer' : 'wave';
    }
    if (prop == 'badminton_racket') {
      if (note != null && RegExp(r'输|输了|失败|没赢').hasMatch(note)) {
        return 'lose_slump';
      }
      return 'swing';
    }
    if (prop == 'chat_bubbles') return 'reach_out';
    if (prop == 'heart') return 'comfort';
    if (note != null &&
        RegExp(r'错|失败|难过').hasMatch(note) &&
        prop == 'workbook') {
      return 'slump_read';
    }
    if (mood == 'sad' && prop != 'none' && prop != 'stars') {
      return 'slump_read';
    }
    return fallbackAction;
  }

  static String _exprFromMood(String mood) => switch (mood) {
        'happy' => 'happy',
        'sad' => 'sad',
        'angry' => 'angry',
        'thinking' => 'thinking',
        _ => 'calm',
      };

  static bool _expressionMatchesMood(String expression, String mood) {
    final mapped = switch (expression) {
      'happy' => 'happy',
      'sad' || 'hurt' => 'sad',
      'angry' => 'angry',
      'thinking' => 'thinking',
      'calm' => 'calm',
      _ => null,
    };
    return mapped == null || mapped == mood;
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
