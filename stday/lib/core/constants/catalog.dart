import 'package:flutter/material.dart';

class MoodOption {
  const MoodOption(this.id, this.label, this.color, this.faceType);
  final String id;
  final String label;
  final Color color;
  final MoodFaceType faceType;
}

enum MoodFaceType { rad, good, meh, bad, awful }

const moods = <MoodOption>[
  MoodOption('happy', '超开心', Color(0xFF2A9D8F), MoodFaceType.rad),
  MoodOption('calm', '开心', Color(0xFF7CB342), MoodFaceType.good),
  MoodOption('thinking', '平静', Color(0xFF42A5F5), MoodFaceType.meh),
  MoodOption('sad', '低落', Color(0xFFFF9800), MoodFaceType.bad),
  MoodOption('angry', '生气', Color(0xFFEF5350), MoodFaceType.awful),
];

class EventTagOption {
  const EventTagOption(
    this.id,
    this.emoji,
    this.label,
    this.storyLabel,
    this.color,
  );
  final String id;
  final String emoji;
  final String label;
  final String storyLabel;
  final Color color;
}

const eventTags = <EventTagOption>[
  EventTagOption('学习', '📚', '学业', '学业故事', Color(0xFF42A5F5)),
  EventTagOption('朋友', '👫', '朋友', '友谊故事', Color(0xFFFFB74D)),
  EventTagOption('运动', '🏃', '运动', '运动故事', Color(0xFF66BB6A)),
  EventTagOption('家庭', '🏠', '家庭', '家庭故事', Color(0xFFAB47BC)),
  EventTagOption('兴趣', '🎨', '兴趣', '兴趣故事', Color(0xFFFF7043)),
  EventTagOption('其它', '✨', '其它', '今日故事', Color(0xFF78909C)),
];

class MomentDetailOption {
  const MomentDetailOption(this.id, this.icon, this.label, this.color);
  final String id;
  final IconData icon;
  final String label;
  final Color color;
}

const studySubjectTags = <MomentDetailOption>[
  MomentDetailOption('语文', Icons.menu_book_rounded, '语文', Color(0xFFE57373)),
  MomentDetailOption('数学', Icons.functions_rounded, '数学', Color(0xFF42A5F5)),
  MomentDetailOption('英语', Icons.translate_rounded, '英语', Color(0xFF7E57C2)),
  MomentDetailOption('物理', Icons.bolt_rounded, '物理', Color(0xFF26A69A)),
  MomentDetailOption('化学', Icons.science_rounded, '化学', Color(0xFFFFA726)),
  MomentDetailOption('生物', Icons.eco_rounded, '生物', Color(0xFF66BB6A)),
  MomentDetailOption('历史', Icons.history_edu_rounded, '历史', Color(0xFF8D6E63)),
  MomentDetailOption('地理', Icons.public_rounded, '地理', Color(0xFF29B6F6)),
  MomentDetailOption(
      '政治', Icons.account_balance_rounded, '政治', Color(0xFF5C6BC0)),
  MomentDetailOption('自定义', Icons.edit_note_rounded, '自定义', Color(0xFF78909C)),
];

const studyStateTags = <MomentDetailOption>[
  MomentDetailOption('深耕', Icons.psychology_rounded, '深耕', Color(0xFF5E97F6)),
  MomentDetailOption('浅学', Icons.lightbulb_rounded, '浅学', Color(0xFFFFCA28)),
  MomentDetailOption('搁置', Icons.pause_circle_rounded, '搁置', Color(0xFF90A4AE)),
  MomentDetailOption('自定义', Icons.edit_note_rounded, '自定义', Color(0xFF78909C)),
];

const momentKeywordTags = <String, List<MomentDetailOption>>{
  '朋友': [
    MomentDetailOption(
        '聊天', Icons.chat_bubble_rounded, '聊天', Color(0xFFFFB74D)),
    MomentDetailOption('陪伴', Icons.favorite_rounded, '陪伴', Color(0xFFF06292)),
    MomentDetailOption('合作', Icons.handshake_rounded, '合作', Color(0xFF4DB6AC)),
    MomentDetailOption('误会', Icons.cloud_rounded, '误会', Color(0xFF90A4AE)),
    MomentDetailOption(
        '和好', Icons.volunteer_activism_rounded, '和好', Color(0xFFFF8A65)),
    MomentDetailOption(
        '自定义', Icons.edit_note_rounded, '自定义', Color(0xFF78909C)),
  ],
  '运动': [
    MomentDetailOption(
        '跑步', Icons.directions_run_rounded, '跑步', Color(0xFF66BB6A)),
    MomentDetailOption(
        '球类', Icons.sports_basketball_rounded, '球类', Color(0xFFFFA726)),
    MomentDetailOption(
        '训练', Icons.fitness_center_rounded, '训练', Color(0xFF42A5F5)),
    MomentDetailOption(
        '比赛', Icons.emoji_events_rounded, '比赛', Color(0xFFFFCA28)),
    MomentDetailOption(
        '恢复', Icons.self_improvement_rounded, '恢复', Color(0xFF26A69A)),
    MomentDetailOption(
        '自定义', Icons.edit_note_rounded, '自定义', Color(0xFF78909C)),
  ],
  '家庭': [
    MomentDetailOption(
        '爸妈', Icons.family_restroom_rounded, '爸妈', Color(0xFFAB47BC)),
    MomentDetailOption('陪伴', Icons.home_rounded, '陪伴', Color(0xFFFFB74D)),
    MomentDetailOption(
        '沟通', Icons.record_voice_over_rounded, '沟通', Color(0xFF42A5F5)),
    MomentDetailOption(
        '争执', Icons.thunderstorm_rounded, '争执', Color(0xFFFF7043)),
    MomentDetailOption(
        '安心', Icons.night_shelter_rounded, '安心', Color(0xFF66BB6A)),
    MomentDetailOption(
        '自定义', Icons.edit_note_rounded, '自定义', Color(0xFF78909C)),
  ],
  '兴趣': [
    MomentDetailOption('绘画', Icons.brush_rounded, '绘画', Color(0xFFFF7043)),
    MomentDetailOption('音乐', Icons.music_note_rounded, '音乐', Color(0xFF7E57C2)),
    MomentDetailOption(
        '阅读', Icons.auto_stories_rounded, '阅读', Color(0xFF8D6E63)),
    MomentDetailOption(
        '游戏', Icons.sports_esports_rounded, '游戏', Color(0xFF42A5F5)),
    MomentDetailOption(
        '创作', Icons.auto_awesome_rounded, '创作', Color(0xFFFFCA28)),
    MomentDetailOption(
        '自定义', Icons.edit_note_rounded, '自定义', Color(0xFF78909C)),
  ],
  '其它': [
    MomentDetailOption('小确幸', Icons.wb_sunny_rounded, '小确幸', Color(0xFFFFCA28)),
    MomentDetailOption('烦恼', Icons.water_drop_rounded, '烦恼', Color(0xFF78909C)),
    MomentDetailOption('期待', Icons.star_rounded, '期待', Color(0xFFFFB74D)),
    MomentDetailOption(
        '变化', Icons.change_circle_rounded, '变化', Color(0xFF42A5F5)),
    MomentDetailOption(
        '自定义', Icons.edit_note_rounded, '自定义', Color(0xFF78909C)),
  ],
};

const notePromptPools = <String, List<String>>{
  '学习': [
    '例如：今天数学错题卡住了，我想记录下哪里还没想通',
    '例如：英语单词背得有点慢，但我找到了一个小方法',
    '例如：这节课我突然明白了一个知识点，想把感觉写下来',
  ],
  '朋友': [
    '例如：今天和朋友聊完后，我心里有一点被理解的感觉',
    '例如：和同学相处时有个小瞬间，我想慢慢说清楚',
    '例如：今天的友情像一阵风，有开心也有一点在意',
  ],
  '运动': [
    '例如：跑完步很累，但我发现自己比昨天多坚持了一点',
    '例如：今天练球有个动作总不顺，我想记下身体的感觉',
    '例如：比赛里有个瞬间让我很紧张，也让我更想进步',
  ],
  '家庭': [
    '例如：今天和家人说话时，我有个小情绪想被看见',
    '例如：家里的一个细节让我安心，我想把它留下来',
    '例如：和爸妈的对话有点复杂，我想先写给小星听',
  ],
  '兴趣': [
    '例如：今天画画时突然有灵感，我想记录这个小火花',
    '例如：练琴时有一段反复卡住，但我还想再试试',
    '例如：做喜欢的事让我放松了一点，我想留住这份感觉',
  ],
  '其它': [
    '例如：今天有个说不清的小瞬间，我想先放进小岛里',
    '例如：这件事不大，但我好像一直在想着它',
    '例如：今天的心情有点混合，我想慢慢讲给小星听',
  ],
};

const welcomeLines = [
  '欢迎回来',
  '今天也辛苦啦',
  '今天有什么想记录的吗',
];

const defaultWaitingLines = [
  '小星正在轻轻醒来…',
  '把你的故事织进风里',
  '马上来见你啦',
];

MoodOption moodById(String id) =>
    moods.firstWhere((m) => m.id == id, orElse: () => moods[2]);

String moodLabel(String id) => moodById(id).label;

Color moodColor(String id) => moodById(id).color;

String primaryStoryLabel(List<String> tags) {
  if (tags.isEmpty) return '今日故事';
  final tag = tags.first;
  return eventTags
      .firstWhere((e) => e.id == tag, orElse: () => eventTags.last)
      .storyLabel;
}

/// 将 moment 的 event_tags + emotion 转为展示用小标签文案。
List<String> momentSelectionLabels({
  required List<String> tags,
  required String emotionTag,
}) {
  final labels = <String>[];
  if (tags.isNotEmpty) {
    final primary = eventTags.firstWhere(
      (e) => e.id == tags.first,
      orElse: () => eventTags.last,
    );
    labels.add(primary.label);
    for (var i = 1; i < tags.length; i++) {
      if (tags[i] != '自定义') labels.add(tags[i]);
    }
  }
  labels.add(moodLabel(emotionTag));
  return labels;
}
