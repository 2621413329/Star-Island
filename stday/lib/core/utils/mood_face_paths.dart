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
  'man_kai_xin',
  'woman_kai_xin',
  'man_ping_jing',
  'woman_ping_jing',
  'man_jiao_lv',
  'woman_jiao_lv',
  'man_ya_li',
  'woman_ya_li',
  'man_xing_fen',
  'woman_xing_fen',
  'man_gan_dong',
  'woman_gan_dong',
  'man_shi_luo',
  'woman_shi_luo',
  'man_fen_nu',
  'woman_fen_nu',
  'man_zi_wo_jue_cha',
  'woman_zi_wo_jue_cha',
  'man_shen_ti_guan_huai',
  'woman_shen_ti_guan_huai',
};

/// 同步解析 mood_faces 资源路径（优先性别分图，再通用/legacy，最后占位）。
List<String> moodFaceAssetCandidates(String? moodId, {String? gender}) {
  final id = normalizeEmotionId(moodId);
  final prefix = switch (gender?.trim().toLowerCase()) {
    'female' || 'girl' || '女' => 'woman',
    'male' || '男' => 'man',
    _ => null,
  };

  final paths = <String>[];

  // 1. 性别分图（主分支正确美术资源）
  if (prefix != null) {
    final gendered = '${prefix}_$id';
    if (_knownGenderedStems.contains(gendered)) {
      paths.add('$moodFaceAssetDir/$gendered.png');
    }
  } else {
    paths.add('$moodFaceAssetDir/man_$id.png');
    paths.add('$moodFaceAssetDir/woman_$id.png');
  }

  // 2. 拼音通用图（历史兼容）
  paths.add('$moodFaceAssetDir/$id.png');

  // 3. 旧五档英文文件名（历史兼容）
  for (final entry in legacyTagToEmotionId.entries) {
    if (entry.value != id) continue;
    final legacy = entry.key;
    paths.add('$moodFaceAssetDir/$legacy.png');
    if (prefix != null && _knownGenderedStems.contains('${prefix}_$legacy')) {
      paths.add('$moodFaceAssetDir/${prefix}_$legacy.png');
    }
  }

  if (prefix != null) {
    paths.add('$moodFaceAssetDir/${prefix}_placeholder.png');
  } else {
    paths.add('$moodFaceAssetDir/man_placeholder.png');
    paths.add('$moodFaceAssetDir/woman_placeholder.png');
  }
  return paths.toSet().toList();
}

String? moodFaceAssetPath(String? moodId, {String? gender}) {
  final paths = moodFaceAssetCandidates(moodId, gender: gender);
  return paths.isEmpty ? null : paths.first;
}
