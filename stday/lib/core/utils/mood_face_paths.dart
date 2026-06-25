import '../constants/catalog.dart';
import '../constants/emotion_catalog.dart';

/// 已有性别分图的感受（仅旧五档 + 后续补齐的拼音图）。
const _knownGenderedStems = {
  'man_happy',
  'man_calm',
  'man_sad',
  'man_thinking',
  'man_angry',
  'woman_happy',
  'woman_calm',
  'woman_sad',
  'woman_thinking',
  'woman_angry',
  for (final id in [
    'kai_xin',
    'ping_jing',
    'jiao_lv',
    'ya_li',
    'xing_fen',
    'gan_dong',
    'shi_luo',
    'fen_nu',
    'zi_wo_jue_cha',
    'shen_ti_guan_huai',
  ]) ...[
    'man_$id',
    'woman_$id',
  ],
};

/// 同步解析 mood_faces 资源路径（优先拼音通用图，再性别图，最后 legacy 五档）。
List<String> moodFaceAssetCandidates(String? moodId, {String? gender}) {
  final id = normalizeEmotionId(moodId);
  final prefix = switch (gender?.trim().toLowerCase()) {
    'female' || 'girl' || '女' => 'woman',
    'male' || '男' => 'man',
    _ => null,
  };

  final paths = <String>[];

  // 1. 拼音通用图（新美术主资源）
  paths.add('$moodFaceAssetDir/$id.png');

  // 2. 拼音性别图（仅当资源存在或已纳入已知列表）
  if (prefix != null) {
    final gendered = '${prefix}_$id';
    if (_knownGenderedStems.contains(gendered)) {
      paths.add('$moodFaceAssetDir/$gendered.png');
    }
  }

  // 3. 旧五档英文文件名（历史兼容）
  for (final entry in legacyTagToEmotionId.entries) {
    if (entry.value != id) continue;
    final legacy = entry.key;
    paths.add('$moodFaceAssetDir/$legacy.png');
    if (prefix != null && _knownGenderedStems.contains('${prefix}_$legacy')) {
      paths.add('$moodFaceAssetDir/${prefix}_$legacy.png');
    }
  }

  paths.add('$moodFaceAssetDir/$emotionPlaceholderAssetId.png');
  return paths.toSet().toList();
}

String? moodFaceAssetPath(String? moodId, {String? gender}) {
  final paths = moodFaceAssetCandidates(moodId, gender: gender);
  return paths.isEmpty ? null : paths.first;
}
