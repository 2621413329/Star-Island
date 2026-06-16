import 'package:flutter/widgets.dart';

import 'story_reminder_service.dart';

/// App 回到前台时重新注册本地提醒（应对部分机型清掉闹钟）。
class ReminderLifecycleHost extends StatefulWidget {
  const ReminderLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  State<ReminderLifecycleHost> createState() => _ReminderLifecycleHostState();
}

class _ReminderLifecycleHostState extends State<ReminderLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      StoryReminderService.instance.rescheduleFromCacheIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
