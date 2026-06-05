import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/companion_spec.dart';
import '../../data/models/profile_models.dart';
import 'companion_prop_infer.dart';

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
    final prop = CompanionPropInfer.infer(eventTags, note);
    final expr = _expr(emotionTag, note);
    final anim = _anim(emotionTag, prop, note);
    final tint = _tint(emotionTag, tag, note);
    final title = _title(eventTags, note);
    final id =
        'local-${DateTime.now().millisecondsSinceEpoch}-${_rnd.nextInt(9999)}';
    final now = DateTime.now();
    return DailyMomentModel(
      id: id,
      eventTags: eventTags,
      emotionTag: emotionTag,
      note: note,
      companionScene: '${companionStyle}_${anim}_$tag',
      companionPose: emotionTag == 'happy' ? 'float' : 'breathing',
      momentDate: now,
      createdAt: now,
      visualPayload: {
        'expression': expr,
        'prop': prop,
        'animation_type': anim,
        'action_type': anim,
        'companion_tint': _hex(tint),
        'scene_title': title,
        'performance_ms': 2000,
        'waiting_lines': _waitingLines(eventTags, title),
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
    if (prop == 'exam_paper') {
      if (mood == 'sad' || mood == 'thinking' || mood == 'angry') {
        return 'slump_read';
      }
      return 'think';
    }
    if (prop == 'heart') return mood == 'happy' ? 'hug' : 'comfort';
    if (prop == 'chat_bubbles' || prop == 'friends') {
      if (note != null && RegExp(r'吵架|误会|冷战|难过').hasMatch(note)) {
        return 'reach_out';
      }
      return 'hug';
    }
    if (prop == 'workbook' &&
        (mood == 'sad' || mood == 'thinking' || mood == 'angry')) {
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
    if (note != null && RegExp(r'羽毛球|球拍').hasMatch(note)) {
      return mood == 'happy'
          ? const Color(0xFF81C784)
          : const Color(0xFF90A4AE);
    }
    if (note != null && RegExp(r'吵架|误会|和好|朋友').hasMatch(note)) {
      return mood == 'happy'
          ? const Color(0xFFFFD54F)
          : const Color(0xFFF8BBD0);
    }
    if (note != null && RegExp(r'考试|考差|没考好|分数|卷子|试卷').hasMatch(note)) {
      return const Color(0xFF8EA4B8);
    }
    if (tag == '学习' && (mood == 'sad' || mood == 'thinking')) {
      return const Color(0xFF90A4AE);
    }
    if (note != null && RegExp(r'错|难过').hasMatch(note)) {
      return const Color(0xFF90A4AE);
    }
    return CompanionSpec.fromPayload({}, fallbackMood: mood).tint;
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static String _title(List<String> tags, String? note) {
    final tag = tags.isNotEmpty ? tags.first : '其它';
    final detail = tags.length > 1 && tags[1] != '自定义' ? tags[1] : null;
    if (note != null && note.contains('羽毛球')) return '球拍旁的小星';
    if (note != null && RegExp(r'吵架|误会|和好').hasMatch(note)) return '朋友之间的云';
    if (note != null && RegExp(r'考试|考差|没考好|分数|卷子|试卷').hasMatch(note)) {
      return '试卷旁的安静时刻';
    }
    if (note != null && note.contains('练习册')) return '练习册前的片刻';
    if (tag == '学习') {
      final subject = detail ?? '学业';
      final state = tags.length > 2 && tags[2] != '自定义' ? tags[2] : '';
      return '$subject$state时刻';
    }
    if (detail != null) return '$detail时刻';
    final suffix = '的小岛时刻';
    final t = tag.length > 6 ? tag.substring(0, 6) : tag;
    return '$t$suffix';
  }

  static List<String> _waitingLines(List<String> tags, String title) {
    final tag = tags.isNotEmpty ? tags.first : '其它';
    final detail = tags.length > 1 && tags[1] != '自定义' ? tags[1] : null;
    final detailLine = detail == null ? title : '看见了$detail';
    final lines = switch (tag) {
      '学习' => [
          '小星翻开练习册',
          detailLine,
          '把难题折成星光',
          '给知识点找座位',
          '正在点亮书页',
          title,
        ],
      '朋友' => [
          '小星听见心事',
          detailLine,
          '把话语放慢一点',
          '给友情织朵云',
          '正在整理表情',
          title,
        ],
      '运动' => [
          '小星系紧鞋带',
          detailLine,
          '风从操场跑过',
          '汗珠变成小星星',
          '正在准备动作',
          title,
        ],
      '家庭' => [
          '小星走近窗边',
          detailLine,
          '把家里的声音收好',
          '给情绪盖条毯子',
          '正在点亮小屋',
          title,
        ],
      '兴趣' => [
          '小星拿起画笔',
          detailLine,
          '灵感冒出泡泡',
          '把喜欢藏进口袋',
          '正在布置舞台',
          title,
        ],
      _ => [
          '小星抬头听风',
          detailLine,
          '把今天轻轻收起',
          '给心情找个名字',
          '正在点亮小岛',
          title,
        ],
    };
    return lines;
  }

  static String _propLabel(String tag) =>
      {'学习': '练习册', '朋友': '朋友', '运动': '球拍', '家庭': '家', '兴趣': '画板'}[tag] ?? '远方';
}
