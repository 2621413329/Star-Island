/// 小人对话台词：存储 `{nickname}` 模板，展示时替换为当前昵称。
const companionNicknamePlaceholder = '{nickname}';

String applyCompanionNickname(String line, String? nickname) {
  final text = line.trim();
  if (!text.contains(companionNicknamePlaceholder)) {
    return text;
  }
  final name = nickname?.trim();
  if (name != null && name.isNotEmpty) {
    return text.replaceAll(companionNicknamePlaceholder, name);
  }
  var result = text.replaceAll('对我们$companionNicknamePlaceholder', '对你');
  result = result.replaceAll('$companionNicknamePlaceholder，', '');
  result = result.replaceAll('$companionNicknamePlaceholder,', '');
  result = result.replaceAll('，$companionNicknamePlaceholder', '，你');
  result = result.replaceAll(',$companionNicknamePlaceholder', ',你');
  return result.replaceAll(companionNicknamePlaceholder, '你');
}

List<String> applyCompanionNicknameLines(
  List<String> lines,
  String? nickname,
) {
  return lines
      .map((line) => applyCompanionNickname(line, nickname))
      .where((line) => line.trim().isNotEmpty)
      .toList();
}
