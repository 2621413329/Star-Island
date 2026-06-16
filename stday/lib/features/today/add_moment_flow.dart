import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'write_story_page.dart';

/// 成长记录：直接写故事，由 AI 自动分类打标。
Future<bool?> showAddMomentFlow(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey? islandKey,
}) {
  return showWriteStoryPage(context, ref);
}
