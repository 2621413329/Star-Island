import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import '../../core/utils/moment_date_groups.dart';
import 'write_story_page.dart';

Future<bool?> showEditMomentSheet(
  BuildContext context,
  WidgetRef ref, {
  required DailyMomentModel moment,
}) {
  if (!isMomentToday(moment)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('仅今日故事可以修改')),
    );
    return Future.value(false);
  }
  return showWriteStoryPage(context, ref, editing: moment)
      .then((value) => value == true);
}
