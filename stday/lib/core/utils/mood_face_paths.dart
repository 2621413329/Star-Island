import '../constants/catalog.dart';
import '../constants/emotion_catalog.dart';

/// 同步解析 mood_faces 资源路径（优先性别图，再通用图，最后占位）。
List<String> moodFaceAssetCandidates(String? moodId, {String? gender}) {
  final id = normalizeEmotionId(moodId);
  final prefix = switch (gender?.trim().toLowerCase()) {
    'female' || 'girl' || '女' => 'woman',
    'male' || '男' => 'man',
    _ => null,
  };

  final paths = <String>[];
  if (prefix != null) {
    paths.add('$moodFaceAssetDir/${prefix}_$id.png');
  }
  paths.add('$moodFaceAssetDir/$id.png');
  if (prefix == 'woman') {
    paths.add('$moodFaceAssetDir/man_$id.png');
  } else if (prefix == 'man') {
    paths.add('$moodFaceAssetDir/woman_$id.png');
  }
  for (final legacy in legacyTagToEmotionId.keys) {
    if (legacyTagToEmotionId[legacy] == id) {
      if (prefix != null) {
        paths.add('$moodFaceAssetDir/${prefix}_$legacy.png');
      }
      paths.add('$moodFaceAssetDir/$legacy.png');
    }
  }
  paths.add('$moodFaceAssetDir/$emotionPlaceholderAssetId.png');
  return paths.toSet().toList();
}

String? moodFaceAssetPath(String? moodId, {String? gender}) {
  final paths = moodFaceAssetCandidates(moodId, gender: gender);
  return paths.isEmpty ? null : paths.first;
}
