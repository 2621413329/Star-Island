import 'emotion_catalog.dart' show aiEmotions, companionBasePlaceholderId, defaultEmotionId, deprecatedEmotionIdRedirects, legacyCompanionExpressionToAssetId, normalizeEmotionId;

/// 小人全身图目录，命名与 [moodFaceAssetDir] 一致：`{gender}_{感受拼音 id}.png`
const companionBaseAssetDir = 'assets/images/companion/base';

/// 缺失资源时的占位图 id（对应 `man__placeholder.png` / `woman__placeholder.png`）。
const companionBasePlaceholderId = '_placeholder';

/// 旧英文 expression（happy/calm 等）→ AI 感受拼音资源 id。
const legacyCompanionExpressionToAssetId = <String, String>{
  'happy': 'kai_xin',
  'calm': 'ping_jing',
  'thinking': 'jiao_lv',
  'sad': 'shi_luo',
  'angry': 'fen_nu',
  'hopeful': 'gan_dong',
  'hurt': 'shi_luo',
  'expecting': 'kai_xin',
  'proud': 'xing_fen',
  'placeholder': companionBasePlaceholderId,
};

/// 将心情 id / 旧 expression 规范为 companion/base 下的拼音文件名。
String companionBaseAssetId(String? raw) {
  final key = raw?.trim();
  if (key == null || key.isEmpty) return defaultEmotionId;
  if (key == companionBasePlaceholderId) return companionBasePlaceholderId;
  final redirected = deprecatedEmotionIdRedirects[key];
  if (redirected != null) return redirected;
  if (aiEmotions.any((e) => e.id == key)) return key;
  final fromLegacyExpression = legacyCompanionExpressionToAssetId[key];
  if (fromLegacyExpression != null) return fromLegacyExpression;
  return normalizeEmotionId(key);
}

String _normalizedCompanionGender(String? gender) {
  return switch (gender?.trim().toLowerCase()) {
    'female' || 'girl' || '女' || 'woman' => 'female',
    'male' || '男' || 'man' => 'male',
    _ => 'male',
  };
}

/// 完整 Flutter asset 路径，例如 `assets/images/companion/base/woman_kai_xin.png`。
String companionBaseAssetPath({
  required String? gender,
  required String? assetId,
}) {
  final candidates = companionBaseAssetCandidates(
    gender: gender,
    assetId: assetId,
  );
  return candidates.isEmpty
      ? '$companionBaseAssetDir/male_${companionBaseAssetId(assetId)}.png'
      : candidates.first;
}

/// 按优先级尝试 companion/base 资源（male_/female_ 优先，兼容 man_/woman_）。
List<String> companionBaseAssetCandidates({
  required String? gender,
  required String? assetId,
  bool includePlaceholder = false,
}) {
  final id = companionBaseAssetId(assetId);
  final prefix = _normalizedCompanionGender(gender);
  final altPrefix = prefix == 'female' ? 'woman' : 'man';
  final paths = <String>[
    '$companionBaseAssetDir/${prefix}_$id.png',
    '$companionBaseAssetDir/${altPrefix}_$id.png',
    '$companionBaseAssetDir/${prefix}_$id.webp',
    '$companionBaseAssetDir/${altPrefix}_$id.webp',
  ];
  if (includePlaceholder && id != companionBasePlaceholderId) {
    paths.add('$companionBaseAssetDir/${prefix}_$companionBasePlaceholderId.png');
    paths.add('$companionBaseAssetDir/${altPrefix}_$companionBasePlaceholderId.png');
  }
  return paths.toSet().toList();
}

/// Flame `game.images.load` 使用的相对路径（去掉 `assets/images/` 前缀）。
String companionBaseFlameAssetPath({
  required String? gender,
  required String? assetId,
}) {
  const imageRoot = 'assets/images/';
  final full = companionBaseAssetPath(gender: gender, assetId: assetId);
  return full.startsWith(imageRoot)
      ? full.substring(imageRoot.length)
      : full;
}
