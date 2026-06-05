/// 根据标签与备注推断小人配饰（与后端 companion_action_ai 规则对齐）。
class CompanionPropInfer {
  CompanionPropInfer._();

  static const allowedProps = {
    'none',
    'workbook',
    'exam_paper',
    'ball',
    'badminton_racket',
    'friends',
    'chat_bubbles',
    'heart',
    'home',
    'music',
    'stars',
    'umbrella',
    'trophy',
    'game_controller',
    'running_shoes',
    'glasses',
    'medal',
  };

  static String infer(List<String> eventTags, String? note, {String? aiProp}) {
    final fromNote = _fromNote(note);
    final tag = eventTags.isNotEmpty ? eventTags.first : '其它';
    final fromTag = _fromTag(tag);
    final candidate = fromNote ?? fromTag;
    if (candidate != null) return candidate;
    if (aiProp != null && allowedProps.contains(aiProp) && aiProp != 'stars') {
      return aiProp;
    }
    return 'stars';
  }

  static String? _fromNote(String? note) {
    if (note == null || note.trim().isEmpty) return null;
    if (RegExp(r'游戏|通关|手游|端游|手柄|打游戏|打通了|过关').hasMatch(note)) {
      return 'game_controller';
    }
    if (RegExp(r'跑步|跑得好|跑了|赛跑|慢跑|长跑|跑操').hasMatch(note)) {
      return 'running_shoes';
    }
    if (RegExp(r'老师.*骂|被骂|批评|训斥|责骂|罚站|挨骂').hasMatch(note)) {
      return 'chat_bubbles';
    }
    if (RegExp(r'考试|考差|没考好|分数|卷子|试卷').hasMatch(note)) {
      return 'exam_paper';
    }
    if (RegExp(r'羽毛球|球拍|拍子').hasMatch(note)) return 'badminton_racket';
    if (RegExp(r'练习册|作业|题|考试|学|课').hasMatch(note)) return 'workbook';
    if (RegExp(r'球|泳').hasMatch(note)) return 'ball';
    if (RegExp(r'安慰|和好|抱抱|陪').hasMatch(note)) return 'heart';
    if (RegExp(r'吵架|误会|冷战|不理|聊天|说话').hasMatch(note)) {
      return 'chat_bubbles';
    }
    if (RegExp(r'朋友|同学|一起').hasMatch(note)) return 'friends';
    if (RegExp(r'家|爸妈|父母').hasMatch(note)) return 'home';
    return null;
  }

  static String? _fromTag(String tag) => switch (tag) {
        '学习' => 'workbook',
        '朋友' => 'friends',
        '运动' => 'ball',
        '家庭' => 'home',
        '兴趣' => 'music',
        _ => null,
      };
}
