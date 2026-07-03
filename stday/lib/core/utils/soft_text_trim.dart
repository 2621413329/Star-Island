import 'package:characters/characters.dart';

/// 在标点或自然边界处截断，避免句中硬切；超出 [maxChars] 才省略。
String softTrimText(String text, int maxChars) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || maxChars <= 0) return trimmed;

  final chars = trimmed.characters;
  if (chars.length <= maxChars) return trimmed;

  final slice = chars.take(maxChars).toString();
  const breakers = '。！？…；，、.!?,;';
  final minIndex = (maxChars * 0.55).floor();
  for (var i = slice.length - 1; i >= minIndex; i--) {
    if (breakers.contains(slice[i])) {
      return slice.substring(0, i + 1);
    }
  }
  if (maxChars >= 2) {
    return '${chars.take(maxChars - 1).toString()}…';
  }
  return '…';
}
