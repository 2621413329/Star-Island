import 'emotion_catalog.dart';

/// 小人全身图目录，命名与 [moodFaceAssetDir] 一致：`{gender}_{感受拼音 id}.png`
const companionBaseAssetDir = 'assets/images/companion/base';

/// 缺失资源时的占位图 id（对应 `male__placeholder.png` / `female__placeholder.png`）。
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
  if (aiEmotions.any((e) => e.id == key)) return key;
  final fromLegacyExpression = legacyCompanionExpressionToAssetId[key];
  if (fromLegacyExpression != null) return fromLegacyExpression;
  return normalizeEmotionId(key);
}

String _normalizedCompanionGender(String? gender) {
  return switch (gender?.toLowerCase()) {
    'female' || 'girl' || '女' => 'female',
    _ => 'male',
  };
}

/// 完整 Flutter asset 路径，例如 `assets/images/companion/base/female_kai_xin.png`。
String companionBaseAssetPath({
  required String? gender,
  required String? assetId,
}) {
  final id = companionBaseAssetId(assetId);
  final g = _normalizedCompanionGender(gender);
  return '$companionBaseAssetDir/${g}_$id.png';
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
