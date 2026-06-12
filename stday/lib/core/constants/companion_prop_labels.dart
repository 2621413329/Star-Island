/// 配饰 id / 资源文件名 → 中文展示名（存储与展示统一使用）。
class CompanionPropLabels {
  CompanionPropLabels._();

  static const knownTitles = <String, String>{
    'workbook': '练习册',
    'exam_paper': '试卷',
    'ball': '球类',
    'basketball': '篮球',
    'badminton_racket': '羽毛球拍',
    'friends': '朋友',
    'chat_bubbles': '聊天',
    'heart': '温暖',
    'home': '家庭',
    'music': '音乐',
    'palette': '绘画',
    'umbrella': '雨伞',
    'trophy': '奖杯',
    'game_controller': '游戏',
    'game': '游戏',
    'running_shoes': '跑步鞋',
    'water_bottle': '水瓶',
    'glasses': '眼镜',
    'medal': '奖牌',
    'stars': '星光',
    'none': '无',
    'camera': '相机',
    'coffee': '咖啡',
    'book': '书本',
    'novel': '小说',
    'present': '礼物',
    'robot': '机器人',
    'duck': '小鸭子',
    'sleep': '睡眠',
    'peace': '平静',
    'love': '爱心',
    'children': '伙伴',
    'education': '学习',
    'construction': '积木',
    'playground-equipment': '游乐',
    'baby-toy': '玩具',
    'game-console': '游戏机',
  };

  static String resolve({
    required String prop,
    String? assetPath,
    String? storedLabel,
  }) {
    final label = storedLabel?.trim();
    if (label != null && label.isNotEmpty) return label;

    final fileStem = _assetStem(assetPath);
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(fileStem)) return fileStem;

    final token = _rawPropToken(prop);
    if (knownTitles.containsKey(token)) return knownTitles[token]!;
    if (knownTitles.containsKey(fileStem)) return knownTitles[fileStem]!;
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(token)) return token;

    return _fallbackEnglishLabel(fileStem.isNotEmpty ? fileStem : token);
  }

  static String _fallbackEnglishLabel(String token) {
    if (token.isEmpty) return '配饰';
    return token
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .trim();
  }

  static String _assetStem(String? assetPath) {
    if (assetPath == null || assetPath.isEmpty) return '';
    final fileName = assetPath.split('/').last;
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? fileName : fileName.substring(0, dot);
  }

  static String _rawPropToken(String prop) {
    final trimmed = prop.trim();
    final categoryIndex = trimmed.indexOf('__');
    if (categoryIndex > 0 && categoryIndex < trimmed.length - 2) {
      return trimmed.substring(categoryIndex + 2);
    }
    for (final prefix in ['story_', 'detail_', 'note_']) {
      if (trimmed.startsWith(prefix)) {
        return trimmed.substring(prefix.length);
      }
    }
    return trimmed;
  }
}
