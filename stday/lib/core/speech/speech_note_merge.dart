import '../constants/moment_limits.dart';

/// 将一次语音转写结果合并进已有备注：从尾部追加，超出 [maxLength] 则截断。
String mergeSpeechIntoNote({
  required String existing,
  required String spoken,
  int maxLength = momentNoteMaxLength,
}) {
  final trimmed = spoken.trim();
  if (trimmed.isEmpty) {
    return existing.length <= maxLength
        ? existing
        : existing.substring(0, maxLength);
  }

  final needsGap =
      existing.isNotEmpty && !RegExp(r'\s$').hasMatch(existing);
  final merged =
      needsGap ? '$existing $trimmed' : '$existing$trimmed';
  if (merged.length <= maxLength) return merged;
  return merged.substring(0, maxLength);
}
