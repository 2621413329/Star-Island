import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'write_story_page.dart';

/// 成长记录：直接写日常，由 AI 自动分类打标。
/// [targetDay] 补录指定日期（缺省为今天）。
Future<bool?> showAddMomentFlow(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey? islandKey,
  DateTime? targetDay,
  String? forcedStoryIslandId,
  String? forcedStoryIslandName,
}) {
  return showWriteStoryPage(
    context,
    ref,
    targetDay: targetDay,
    forcedStoryIslandId: forcedStoryIslandId,
    forcedStoryIslandName: forcedStoryIslandName,
  );
}
