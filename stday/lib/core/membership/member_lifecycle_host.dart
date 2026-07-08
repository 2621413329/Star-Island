import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/member_provider.dart';

/// App 生命周期内按需刷新会员状态。
class MemberLifecycleHost extends ConsumerStatefulWidget {
  const MemberLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MemberLifecycleHost> createState() =>
      _MemberLifecycleHostState();
}

class _MemberLifecycleHostState extends ConsumerState<MemberLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberProvider.notifier).ensureFresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(memberProvider.notifier).ensureFresh();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
