import '../constants/moment_limits.dart';

String _clipToMax(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return value.substring(0, maxLength);
}

/// 将一次语音转写结果合并进已有备注：从尾部追加，超出 [maxLength] 则截断。
String mergeSpeechIntoNote({
  required String existing,
  required String spoken,
  int maxLength = momentNoteMaxLength,
}) {
  return insertSpeechAtSelection(
    existing: existing,
    spoken: spoken,
    selectionStart: existing.length,
    selectionEnd: existing.length,
    maxLength: maxLength,
  );
}

/// 按选区/光标位置插入转写文字，超出 [maxLength] 则截断。
String insertSpeechAtSelection({
  required String existing,
  required String spoken,
  required int selectionStart,
  required int selectionEnd,
  int maxLength = momentNoteMaxLength,
}) {
  final trimmed = spoken.trim();
  if (trimmed.isEmpty) return _clipToMax(existing, maxLength);

  final start = selectionStart.clamp(0, existing.length);
  final end = selectionEnd.clamp(0, existing.length);
  final safeStart = start <= end ? start : end;
  final safeEnd = start <= end ? end : start;

  final before = existing.substring(0, safeStart);
  final after = existing.substring(safeEnd);
  final needsGap = before.isNotEmpty && !RegExp(r'\s$').hasMatch(before);
  final inserted = needsGap ? '$before $trimmed' : '$before$trimmed';
  return _clipToMax('$inserted$after', maxLength);
}

/// 转写插入后的光标位置（落在插入文本末尾）。
int cursorAfterSpeechInsertion({
  required String existing,
  required String spoken,
  required int selectionStart,
  required int selectionEnd,
}) {
  final merged = insertSpeechAtSelection(
    existing: existing,
    spoken: spoken,
    selectionStart: selectionStart,
    selectionEnd: selectionEnd,
  );
  final trimmed = spoken.trim();
  if (trimmed.isEmpty) {
    return selectionStart.clamp(0, merged.length);
  }

  final start = selectionStart.clamp(0, existing.length);
  final end = selectionEnd.clamp(0, existing.length);
  final safeStart = start <= end ? start : end;
  final before = existing.substring(0, safeStart);
  final needsGap = before.isNotEmpty && !RegExp(r'\s$').hasMatch(before);
  final insertLen = trimmed.length + (needsGap ? 1 : 0);
  return (safeStart + insertLen).clamp(0, merged.length);
}
