/// 各分类默认岛屿全名（含「岛」）。
const storyIslandDefaultNames = <String, String>{
  'work': '工作岛',
  'study': '学业岛',
  'health': '健康岛',
  'social': '人际岛',
  'life': '生活岛',
  'creation': '创作岛',
  'finance': '财务岛',
  'achievement': '成就岛',
  'emotion': '情绪岛',
  'inspiration': '灵感岛',
  'milestone': '特殊事件岛',
};

String defaultStoryIslandName(String categoryId, String categoryLabel) {
  return storyIslandDefaultNames[categoryId] ?? '$categoryLabel岛';
}

/// 编辑时输入框展示的名称（去掉末尾「岛」）。
String storyIslandNameStem(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.endsWith('岛') && trimmed.length > 1) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

/// 保存时补全「岛」后缀。
String storyIslandFullName(String stem) {
  final core = stem.trim();
  if (core.isEmpty) return '';
  if (core.endsWith('岛')) return core;
  return '$core岛';
}

/// 规范化后用于重名比较（补全「岛」、去首尾空白、忽略大小写）。
String normalizeStoryIslandName(String name) {
  return storyIslandFullName(name).toLowerCase();
}

/// [existingNames] 中是否已有与 [candidateName] 相同的岛屿名。
/// 编辑场景请先从列表中排除当前岛屿自身。
bool isDuplicateStoryIslandName({
  required String candidateName,
  required Iterable<String> existingNames,
}) {
  final normalized = normalizeStoryIslandName(candidateName);
  if (normalized.isEmpty) return false;
  for (final name in existingNames) {
    if (normalizeStoryIslandName(name) == normalized) return true;
  }
  return false;
}
