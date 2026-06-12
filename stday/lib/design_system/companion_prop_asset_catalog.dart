import 'package:flutter/services.dart';

const companionPropAssetDir = 'assets/images/companion/props';

/// 读取打包后的 assets 清单，并把故事内容映射到可替换的配饰图片。
///
/// 匹配顺序：
/// 1. 根目录精确匹配：`<prop>.png`
/// 2. 分类目录精确/部分匹配：`study/identification-card.png`
/// 3. 分类目录候选：`study/*.png`
/// 3. 原 prop 返回，让 Image.asset / Flame resolver 走原有兜底
class CompanionPropAssetCatalog {
  CompanionPropAssetCatalog._(this._assets);

  static Future<CompanionPropAssetCatalog>? _future;

  final Set<String> _assets;

  static Future<CompanionPropAssetCatalog> load() {
    return _future ??= _load();
  }

  static Future<CompanionPropAssetCatalog> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((path) =>
            path.startsWith('$companionPropAssetDir/') &&
            _isSupportedAsset(path))
        .toSet();
    return CompanionPropAssetCatalog._(assets);
  }

  /// 返回完整 asset path，例如：
  /// `assets/images/companion/props/study/calculator.png`
  String resolve(String prop) {
    final rawToken = _rawToken(prop);
    final categoryToken = _categoryToken(prop.trim());
    if (categoryToken != null) {
      return _resolveInCategory(categoryToken.$1, rawToken) ??
          '$companionPropAssetDir/${categoryToken.$1}/$rawToken.png';
    }

    final exact = '$companionPropAssetDir/$rawToken.png';
    if (_assets.contains(exact)) return exact;

    final prefix = _categoryPrefix(prop);
    if (prefix != null) {
      final matched = _resolveInCategory(prefix, rawToken);
      if (matched != null) return matched;
    }

    final globalMatched = _matchByWords(_assets.toList()..sort(), rawToken);
    if (globalMatched != null) return globalMatched;

    return exact;
  }

  String? _resolveInCategory(String prefix, String rawToken) {
    final categoryExact = '$companionPropAssetDir/$prefix/$rawToken.png';
    if (_assets.contains(categoryExact)) return categoryExact;

    final categoryAssets = _assets
        .where((path) => path.startsWith('$companionPropAssetDir/$prefix/'))
        .toList()
      ..sort();
    final matched = _matchByWords(categoryAssets, rawToken) ??
        _matchLegacyAliases(categoryAssets, rawToken);
    if (matched != null) return matched;
    if (categoryAssets.isNotEmpty) {
      return categoryAssets[rawToken.hashCode.abs() % categoryAssets.length];
    }
    return null;
  }

  static String _fileName(String path) {
    return path.substring(path.lastIndexOf('/') + 1);
  }

  static bool _isSupportedAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.svg');
  }

  static String _stem(String path) {
    final fileName = _fileName(path);
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? fileName : fileName.substring(0, dot);
  }

  static String? _matchByWords(List<String> assets, String prop) {
    final tokens = _matchTokens(prop);
    if (tokens.isEmpty) return null;
    for (final asset in assets) {
      final stem = _stem(asset).toLowerCase();
      final stemTokens = _matchTokens(stem);
      final matched = tokens.any((token) =>
          stem == token || stem.contains(token) || stemTokens.contains(token));
      if (matched) return asset;
    }
    return null;
  }

  static String? _matchLegacyAliases(List<String> assets, String prop) {
    final hints = _legacyPropAliases[prop.trim().toLowerCase()];
    if (hints == null) return null;
    for (final hint in hints) {
      final matched = _matchByWords(assets, hint);
      if (matched != null) return matched;
    }
    return null;
  }

  static Set<String> _matchTokens(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return const {};
    final parts = normalized
        .split(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'))
        .where((part) => part.isNotEmpty)
        .toSet();
    final aliases = _legacyPropAliases[normalized] ?? const [];
    return {normalized, ...parts, ...aliases};
  }

  static String? _categoryPrefix(String prop) {
    final normalized = prop.trim();
    if (normalized.isEmpty) return null;
    final categoryToken = _categoryToken(normalized);
    if (categoryToken != null) return categoryToken.$1;

    final raw = normalized.startsWith('story_')
        ? normalized.substring('story_'.length)
        : normalized.startsWith('detail_')
            ? normalized.substring('detail_'.length)
            : normalized.startsWith('note_')
                ? normalized.substring('note_'.length)
                : normalized;

    if (_studyTokens.contains(raw)) return 'study';
    if (_sportTokens.contains(raw)) return 'sport';
    if (_friendTokens.contains(raw)) return 'friend';
    if (_familyTokens.contains(raw)) return 'family';
    if (_hobbyTokens.contains(raw)) return 'hobby';
    if (_otherTokens.contains(raw)) return 'other';
    return null;
  }

  static String _rawToken(String prop) {
    final categoryToken = _categoryToken(prop.trim());
    return categoryToken?.$2 ?? prop;
  }

  static (String, String)? _categoryToken(String prop) {
    final index = prop.indexOf('__');
    if (index <= 0 || index >= prop.length - 2) return null;
    final category = prop.substring(0, index);
    final token = prop.substring(index + 2);
    return switch (category) {
      'study' || 'sport' || 'friend' || 'family' || 'hobby' || 'other' => (
          category,
          token
        ),
      _ => null,
    };
  }
}

const _legacyPropAliases = <String, List<String>>{
  'workbook': ['paper', 'homework', 'notebook', 'clipboard', 'book'],
  'exam_paper': ['paper', 'exam', 'test'],
  'glasses': ['vision', 'goggles', 'ski-goggles'],
  'ball': ['ball', 'football', 'baseball', 'tennis'],
  'basketball': ['basketball', 'ball'],
  'running_shoes': ['running', 'shoes', 'tennis-shoes'],
  'badminton_racket': ['badminton', 'racket'],
  'water_bottle': ['water', 'bottle', 'cola'],
  'cricket': ['cricket', 'stump', 'guard'],
  'friends': ['children', 'relationships', 'love'],
  'chat_bubbles': ['chat', 'message', 'bubble'],
  'heart': ['love', 'peace'],
  'home': ['home', 'house'],
  'music': ['music', 'ukulele', 'speakers'],
  'palette': ['paint', 'composition', 'canvas'],
  'game_controller': ['game', 'game-console', 'controller'],
  'umbrella': ['water', 'rain'],
  'trophy': ['achievements', 'present'],
  'medal': ['achievements', 'present'],
  'stars': ['magic', 'present'],
  'backpack': ['backpack', 'bag'],
};

const _studyTokens = {
  '学习',
  '学业',
  '语文',
  '数学',
  '英语',
  '物理',
  '化学',
  '生物',
  '历史',
  '地理',
  '政治',
  '深耕',
  '浅学',
  '搁置',
  '考试',
  '试卷',
  '作业',
  '阅读',
  '看书',
  'study',
  'school',
  'student',
  'book',
  'reading',
  'achievements',
  'atom',
  'bomb',
  'backpack',
  'bag',
  'bicycle',
  'bike',
  'bus',
  'calculator',
  'canvas',
  'clipboard',
  'commencement',
  'computer',
  'desk',
  'certificate',
  'education',
  'graduation',
  'group',
  'hat',
  'home',
  'identification',
  'card',
  'id',
  'lamp',
  'lamps',
  'learning',
  'notebook',
  'online',
  'projector',
  'ruler',
  'screen',
  'students',
  'teaching',
  'university',
  'whiteboard',
  'whiteboards',
  'world',
  'chinese',
  'math',
  'english',
  'language',
  'physics',
  'science',
  'chemistry',
  'biology',
  'history',
  'geography',
  'map',
  'politics',
  'exam',
  'test',
  'paper',
  'homework',
  'workbook',
  'exam_paper',
  'glasses',
  'data',
  '身份证',
  '证件',
  '学生证',
  '巴士',
  '公交',
  '公交车',
  '校车',
  '自行车',
};

const _sportTokens = {
  '运动',
  '跑步',
  '球类',
  '训练',
  '比赛',
  '恢复',
  '篮球',
  '羽毛球',
  '喝水',
  '水瓶',
  'sport',
  'sports',
  'running',
  'running_shoes',
  'run',
  'shoes',
  'basketball',
  'ball',
  'badminton',
  'badminton_racket',
  'cricket',
  'stump',
  'guard',
  'racket',
  'water',
  'water_bottle',
  'bottle',
  'match',
  'competition',
  'medal',
};

const _friendTokens = {
  '朋友',
  '同学',
  '聊天',
  '陪伴',
  '合作',
  '误会',
  '和好',
  '吵架',
  'friend',
  'friends',
  'classmate',
  'chat',
  'chat_bubbles',
  'message',
  'bubble',
  'heart',
};

const _familyTokens = {
  '家庭',
  '家',
  '爸妈',
  '父母',
  '沟通',
  '争执',
  '安心',
  'family',
  'home',
  'parent',
};

const _hobbyTokens = {
  '兴趣',
  '绘画',
  '音乐',
  '游戏',
  '创作',
  '画画',
  'hobby',
  'music',
  'paint',
  'palette',
  'game',
  'game_controller',
  'controller',
};

const _otherTokens = {
  '其它',
  '其他',
  '小确幸',
  '烦恼',
  '期待',
  '变化',
  '下雨',
  '雨伞',
  '奖杯',
  '奖牌',
  'other',
  'umbrella',
  'trophy',
  'medal',
};
