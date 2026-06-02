import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/companion_spec.dart';
import '../../data/models/profile_models.dart';

/// API 不可用时的本地小人数据（与后端 companion_action_ai 规则对齐）。
class ClientMomentFactory {
  static final _rnd = Random();

  static DailyMomentModel build({
    required List<String> eventTags,
    required String emotionTag,
    String? note,
    String companionStyle = 'chibi',
  }) {
    final tag = eventTags.isNotEmpty ? eventTags.first : '其它';
    final prop = _prop(tag, note);
    final expr = _expr(emotionTag, note);
    final anim = _anim(emotionTag, prop, note);
    final tint = _tint(emotionTag, tag, note);
    final title = _title(tag, note);
    final id = 'local-${DateTime.now().millisecondsSinceEpoch}-${_rnd.nextInt(9999)}';
    return DailyMomentModel(
      id: id,
      eventTags: eventTags,
      emotionTag: emotionTag,
      note: note,
      companionScene: '${companionStyle}_${anim}_$tag',
      companionPose: emotionTag == 'happy' ? 'float' : 'breathing',
      visualPayload: {
        'expression': expr,
        'prop': prop,
        'animation_type': anim,
        'action_type': anim,
        'companion_tint': _hex(tint),
        'scene_title': title,
        'performance_ms': 2000,
        'waiting_lines': [
          '小星读懂了你的故事…',
          title,
          '正在为你准备表演',
        ],
        'performance_hint': note != null && note.length > 4
            ? '小星${emotionTag == 'sad' ? '轻轻叹气看着' : '看着'}${_propLabel(tag)}'
            : '小星缓缓转过身来',
        'local_fallback': true,
      },
    );
  }

  static CompanionSpec previewSpec({
    required List<String> eventTags,
    required String emotionTag,
    String? note,
  }) {
    final m = build(eventTags: eventTags, emotionTag: emotionTag, note: note);
    return m.companionSpec;
  }

  static String _prop(String tag, String? note) {
    if (note != null) {
      if (RegExp(r'练习册|作业|题|考试|学|课').hasMatch(note)) return 'workbook';
      if (RegExp(r'球|跑|泳|运动').hasMatch(note)) return 'ball';
      if (RegExp(r'朋友|同学|一起').hasMatch(note)) return 'friends';
      if (RegExp(r'家|爸妈|父母').hasMatch(note)) return 'home';
    }
    const map = {'学习': 'workbook', '朋友': 'friends', '运动': 'ball', '家庭': 'home', '兴趣': 'music'};
    return map[tag] ?? 'stars';
  }

  static String _expr(String mood, String? note) {
    if (note != null && RegExp(r'错|失败|难过|哭|糟').hasMatch(note)) {
      if (mood == 'sad' || mood == 'angry' || mood == 'thinking') return 'sad';
    }
    return switch (mood) {
      'happy' => 'happy',
      'sad' => 'sad',
      'angry' => 'angry',
      'thinking' => 'thinking',
      _ => 'calm',
    };
  }

  static String _anim(String mood, String prop, String? note) {
    if (prop == 'workbook' && (mood == 'sad' || mood == 'thinking' || mood == 'angry')) {
      return 'slump_read';
    }
    if (prop == 'workbook' && mood == 'happy') return 'cheer';
    return switch (mood) {
      'happy' => 'celebrate',
      'sad' => prop == 'none' ? 'look_down' : 'slump_read',
      'angry' => 'shake',
      'thinking' => 'think',
      _ => 'wave',
    };
  }

  static Color _tint(String mood, String tag, String? note) {
    if (tag == '学习' && (mood == 'sad' || mood == 'thinking')) {
      return const Color(0xFF90A4AE);
    }
    if (note != null && RegExp(r'错|难过').hasMatch(note)) {
      return const Color(0xFF90A4AE);
    }
    return CompanionSpec.fromPayload({}, fallbackMood: mood).tint;
  }

  static String _hex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static String _title(String tag, String? note) {
    if (note != null && note.contains('练习册')) return '练习册前的片刻';
    if (tag == '学习') return '学业故事里的小星';
    final suffix = '的小岛时刻';
    final t = tag.length > 6 ? tag.substring(0, 6) : tag;
    return '$t$suffix';
  }

  static String _propLabel(String tag) =>
      {'学习': '练习册', '朋友': '朋友', '运动': '球场', '家庭': '家', '兴趣': '画板'}[tag] ?? '远方';
}
