import 'package:flutter/material.dart';

import '../utils/companion_prop_infer.dart';

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

  factory CompanionSpec.fromPayload(Map<String, dynamic> payload,
      {String fallbackMood = 'calm'}) {
    final mood = payload['emotion_tag'] as String? ?? fallbackMood;
    final note = payload['note_hint'] as String?;
    final hasNewSchema =
        payload.containsKey('expression') || payload.containsKey('prop');
    final aiProp = payload['prop'] as String?;
    final eventTags = (payload['event_tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final prop = hasNewSchema
        ? CompanionPropInfer.infer(eventTags, note, aiProp: aiProp)
        : _propFromLegacy(payload['base_scene'] as String?, note);
    final expression = payload['expression'] as String? ?? _exprFromMood(mood);
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
      animationType: animationType,
      tint: _parseHex(tintHex) ?? _defaultTint(mood),
      sceneTitle: payload['scene_title'] as String?,
      performanceHint: payload['performance_hint'] as String?,
    );
  }

  static String _propFromLegacy(String? baseScene, String? note) {
    final tag = switch (baseScene) {
      'study' => '学习',
      'friendship' => '朋友',
      'sport' => '运动',
      'family' => '家庭',
      'hobby' => '兴趣',
      _ => '其它',
    };
    return CompanionPropInfer.infer([tag], note);
  }

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
