import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_session.dart';
import '../data/local/growth_tag_catalog_cache.dart';
import 'bootstrap_provider.dart';

class AuthState {
  const AuthState({this.token, this.ready = true});
  final String? token;

  /// 是否已完成本地 token 读取（main 预加载后恒为 true）。
  final bool ready;

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({String? initialToken})
      : super(AuthState(token: initialToken, ready: true));

  static const prefsTokenKey = 'stday_access_token';

  String? get currentToken => state.token;
  bool get isLoggedIn => state.isLoggedIn;

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsTokenKey, token);
    state = AuthState(token: token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsTokenKey);
    await GrowthTagCatalogCache.clear();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final boot = ref.watch(appBootstrapProvider);
  final notifier = AuthNotifier(initialToken: boot.token);
  registerApiSession(
    ApiSessionCallbacks(
      readAccessToken: () => notifier.currentToken,
      forceRelogin: () async {
        if (notifier.isLoggedIn) {
          await notifier.logout();
        }
      },
    ),
  );
  return notifier;
});
