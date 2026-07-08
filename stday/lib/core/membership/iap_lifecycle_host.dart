import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/iap_provider.dart';

/// 登录后在 iOS 上初始化 App Store 内购监听。
class IapLifecycleHost extends ConsumerStatefulWidget {
  const IapLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IapLifecycleHost> createState() => _IapLifecycleHostState();
}

class _IapLifecycleHostState extends ConsumerState<IapLifecycleHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    final loggedIn = ref.read(authProvider).isLoggedIn;
    if (loggedIn) {
      ref.read(iapCatalogProvider.notifier).ensureInitialized();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isLoggedIn && (previous == null || !previous.isLoggedIn)) {
        ref.read(iapCatalogProvider.notifier).ensureInitialized();
      }
    });
    return widget.child;
  }
}
