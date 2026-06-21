import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import 'write_story_page.dart';

Future<bool?> showEditMomentSheet(
  BuildContext context,
  WidgetRef ref, {
  required DailyMomentModel moment,
}) {
  return showWriteStoryPage(context, ref, editing: moment)
      .then((value) => value == true);
}
