import 'dart:math';

/// 根据标签与备注推断小人配饰（与后端 companion_action_ai 规则对齐）。
class CompanionPropInfer {
  CompanionPropInfer._();

  static final _rnd = Random();

  static const allowedProps = {
    'none',
    'workbook',
    'exam_paper',
    'ball',
    'basketball',
    'badminton_racket',
    'friends',
    'chat_bubbles',
    'heart',
    'home',
    'music',
    'palette',
    'stars',
    'umbrella',
    'trophy',
    'game_controller',
    'running_shoes',
    'water_bottle',
    'glasses',
    'medal',
  };

  /// 允许两类配饰 id：
  /// 1. 内置 id，例如 `workbook`、`basketball`
  /// 2. 文件命名约定 id，例如 `语文`、`story_学习`、`detail_跑步`、`note_考试`
  ///
  /// 第二类会直接映射到 `assets/images/companion/props/<id>.png`。
  static bool isAllowedProp(String prop) {
    if (allowedProps.contains(prop)) return true;
    return _isFileSafeToken(prop);
  }

  static const _tagPools = <String, List<String>>{
    '学习': ['workbook', 'exam_paper', 'glasses', 'trophy', 'medal'],
    '朋友': ['friends', 'chat_bubbles', 'heart', 'umbrella'],
    '运动': [
      'ball',
      'basketball',
      'running_shoes',
      'badminton_racket',
      'water_bottle',
      'trophy',
    ],
    '家庭': ['home', 'heart', 'umbrella', 'chat_bubbles', 'trophy'],
    '兴趣': [
      'music',
      'game_controller',
      'palette',
      'glasses',
      'trophy',
      'medal',
    ],
    '其它': [
      'chat_bubbles',
      'heart',
      'umbrella',
      'trophy',
      'medal',
      'stars',
    ],
  };

  /// 主配饰（兼容旧接口）。
  static String infer(List<String> eventTags, String? note, {String? aiProp}) {
    return inferProps(eventTags, note: note, aiProp: aiProp).first;
  }

  /// 按日常情境生成 2～3 个静态配饰，尽量每次不同。
  static List<String> inferProps(
    List<String> eventTags, {
    String? note,
    String? aiProp,
    int? seed,
  }) {
    final rnd = seed == null ? _rnd : Random(seed);
    final tag = eventTags.isNotEmpty ? eventTags.first : '其它';
    final categoryPrefix = _categoryPrefix(tag);
    final result = <String>[];

    void add(String? prop) {
      if (prop == null || prop == 'none') return;
      if (!isAllowedProp(prop)) return;
      final categorized = _withCategory(categoryPrefix, prop);
      if (!result.contains(categorized)) result.add(categorized);
    }

    for (final prop in _fromNamingConvention(eventTags, note)) {
      add(prop);
    }
    add(_fromNote(note));
    if (aiProp != null && isAllowedProp(aiProp) && aiProp != 'stars') {
      add(aiProp);
    }

    final pool = List<String>.from(_tagPools[tag] ?? _tagPools['其它']!);
    pool.shuffle(rnd);
    final targetCount = 2 + rnd.nextInt(2);
    for (final prop in pool) {
      if (result.length >= targetCount) break;
      add(prop);
    }

    if (result.isEmpty) {
      add(_fromTag(tag));
    }
    if (result.isEmpty) {
      result.add('stars');
    }
    return result;
  }

  static List<String> _fromNamingConvention(
    List<String> eventTags,
    String? note,
  ) {
    final result = <String>[];
    final categoryPrefix =
        eventTags.isEmpty ? 'other' : _categoryPrefix(eventTags.first);

    void addToken(String? token) {
      final safe = _safeToken(token);
      if (safe == null) return;
      if (!result.contains(safe)) result.add(safe);
    }

    void addPrefixed(String prefix, String? token) {
      final safe = _safeToken(token);
      if (safe == null) return;
      final prop = '${prefix}_$safe';
      if (!result.contains(prop)) result.add(prop);
    }

    void addCategoryToken(String? token) {
      final safe = _safeToken(token);
      if (safe == null) return;
      final prop = '${categoryPrefix}__$safe';
      if (!result.contains(prop)) result.add(prop);
    }

    final text = note?.trim();
    if (text != null && text.isNotEmpty) {
      for (final token in _englishWords(text)) {
        addCategoryToken(token);
        addToken(token);
      }
      for (final keyword in _noteFileKeywords) {
        if (text.contains(keyword)) {
          for (final translated in _translatedTokens[keyword] ?? const []) {
            addCategoryToken(translated);
            addToken(translated);
          }
          addCategoryToken(keyword);
          addToken(keyword);
          addPrefixed('note', keyword);
        }
      }
    }

    if (eventTags.isNotEmpty) {
      for (final detail in eventTags.skip(1)) {
        for (final translated in _translatedTokens[detail] ?? const []) {
          addCategoryToken(translated);
          addToken(translated);
        }
        addCategoryToken(detail);
        addToken(detail);
        addPrefixed('detail', detail);
      }
      final primary = eventTags.first;
      for (final translated in _translatedTokens[primary] ?? const []) {
        addCategoryToken(translated);
        addToken(translated);
      }
      addCategoryToken(primary);
      addToken(primary);
      addPrefixed('story', primary);
    }

    return result;
  }

  static const _noteFileKeywords = [
    '考试',
    '试卷',
    '作业',
    '阅读',
    '看书',
    '篮球',
    '羽毛球',
    '板球',
    'cricket',
    'stump',
    'guard',
    '跑步',
    '比赛',
    '喝水',
    '水瓶',
    '朋友',
    '同学',
    '聊天',
    '吵架',
    '和好',
    '家',
    '爸妈',
    '音乐',
    '画画',
    '游戏',
    '奖杯',
    '奖牌',
    '下雨',
    '雨伞',
    '身份证',
    '证件',
    '学生证',
    '书包',
    '背包',
    '计算器',
    '电脑',
    '剪贴板',
    '画布',
    '巴士',
    '公交',
    '公交车',
    '校车',
    '自行车',
  ];

  static const _translatedTokens = <String, List<String>>{
    '学习': ['study', 'school', 'student', 'book'],
    '学业': ['study', 'school', 'student', 'book'],
    '语文': ['chinese', 'book', 'reading'],
    '数学': ['math', 'calculator'],
    '英语': ['english', 'language'],
    '物理': ['physics', 'science'],
    '化学': ['chemistry', 'science'],
    '生物': ['biology', 'science'],
    '历史': ['history'],
    '地理': ['geography', 'map'],
    '政治': ['politics'],
    '考试': ['exam', 'test', 'paper'],
    '试卷': ['exam', 'test', 'paper'],
    '作业': ['homework', 'workbook', 'clipboard'],
    '阅读': ['reading', 'book'],
    '看书': ['reading', 'book'],
    '身份证': ['identification', 'card', 'id'],
    '证件': ['identification', 'card', 'id'],
    '学生证': ['student', 'identification', 'card', 'id'],
    '书包': ['backpack', 'bag'],
    '背包': ['backpack', 'bag'],
    '计算器': ['calculator', 'math'],
    '电脑': ['computer'],
    '剪贴板': ['clipboard', 'data'],
    '画布': ['canvas'],
    '运动': ['sport', 'sports'],
    '跑步': ['running', 'run', 'shoes'],
    '篮球': ['basketball', 'ball'],
    '羽毛球': ['badminton', 'racket'],
    '板球': ['cricket', 'stump', 'guard'],
    '喝水': ['water', 'bottle'],
    '水瓶': ['water', 'bottle'],
    '比赛': ['match', 'competition', 'trophy'],
    '朋友': ['friend', 'friends'],
    '同学': ['classmate', 'student', 'friend'],
    '聊天': ['chat', 'message', 'bubble'],
    '家庭': ['family', 'home'],
    '家': ['family', 'home'],
    '爸妈': ['parent', 'family', 'home'],
    '音乐': ['music'],
    '画画': ['paint', 'palette', 'canvas'],
    '绘画': ['paint', 'palette', 'canvas'],
    '游戏': ['game', 'controller'],
    '巴士': ['bus'],
    '公交': ['bus'],
    '公交车': ['bus'],
    '校车': ['bus', 'school'],
    '自行车': ['bicycle', 'bike'],
  };

  static Iterable<String> _englishWords(String text) {
    return RegExp(r'[A-Za-z0-9]+')
        .allMatches(text)
        .map((match) => match.group(0)!.toLowerCase())
        .where((word) => word.length >= 2);
  }

  static String? _fromNote(String? note) {
    if (note == null || note.trim().isEmpty) return null;
    if (RegExp(r'下雨|淋雨|雨伞|暴雨|雨天|带伞').hasMatch(note)) {
      return 'umbrella';
    }
    if (RegExp(r'获奖|得奖|第一名|冠军|赢了|胜利|奖杯').hasMatch(note)) {
      return 'trophy';
    }
    if (RegExp(r'奖牌|金牌|银牌|铜牌|勋章').hasMatch(note)) {
      return 'medal';
    }
    if (RegExp(r'眼镜|看书|阅读|读书|图书馆').hasMatch(note)) {
      return 'glasses';
    }
    if (RegExp(r'唱歌|听歌|音乐|钢琴|吉他|跳舞|舞蹈').hasMatch(note)) {
      return 'music';
    }
    if (RegExp(r'画画|绘画|美术|颜料|画板').hasMatch(note)) {
      return 'palette';
    }
    if (RegExp(r'游戏|通关|手游|端游|手柄|打游戏|打通了|过关').hasMatch(note)) {
      return 'game_controller';
    }
    if (RegExp(r'跑步|跑得好|跑了|赛跑|慢跑|长跑|跑操').hasMatch(note)) {
      return 'running_shoes';
    }
    if (RegExp(r'篮球').hasMatch(note)) return 'basketball';
    if (RegExp(r'喝水|水瓶|口渴|补水').hasMatch(note)) return 'water_bottle';
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

  static String _categoryPrefix(String tag) => switch (tag) {
        '学习' || '学业' => 'study',
        '运动' => 'sport',
        '朋友' => 'friend',
        '家庭' => 'family',
        '兴趣' => 'hobby',
        _ => 'other',
      };

  static String _withCategory(String category, String prop) {
    if (_hasCategoryToken(prop)) return prop;
    return '${category}__$prop';
  }

  static bool _hasCategoryToken(String prop) {
    final index = prop.indexOf('__');
    if (index <= 0 || index >= prop.length - 2) return false;
    final category = prop.substring(0, index);
    return category == 'study' ||
        category == 'sport' ||
        category == 'friend' ||
        category == 'family' ||
        category == 'hobby' ||
        category == 'other';
  }

  static String? _safeToken(String? value) {
    final token = value?.trim();
    if (token == null || token.isEmpty) return null;
    return _isFileSafeToken(token) ? token : null;
  }

  static bool _isFileSafeToken(String token) {
    if (token.isEmpty || token.length > 40) return false;
    return !RegExp(r'[\\/:*?"<>|.]').hasMatch(token);
  }
}
