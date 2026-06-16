import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/notifications/reminder_lifecycle_host.dart';
import 'core/notifications/story_reminder_service.dart';
import 'providers/auth_provider.dart';
import 'providers/bootstrap_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  await StoryReminderService.instance.initialize();
  await StoryReminderService.instance.rescheduleFromCacheIfEnabled();
  final prefs = await SharedPreferences.getInstance();
  final bootstrap = AppBootstrap(
    token: prefs.getString(AuthNotifier.prefsTokenKey),
  );
  runApp(
    ProviderScope(
      overrides: [
        appBootstrapProvider.overrideWithValue(bootstrap),
      ],
      child: const ReminderLifecycleHost(
        child: StdayApp(),
      ),
    ),
  );
}
