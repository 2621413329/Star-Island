import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  const AuthState({this.token, this.loading = false});
  final String? token;
  final bool loading;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  AuthState copyWith({String? token, bool? loading}) {
    return AuthState(
      token: token ?? this.token,
      loading: loading ?? this.loading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _load();
  }

  static const _key = 'stday_access_token';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_key);
    if (token != null) {
      state = AuthState(token: token);
    }
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    state = AuthState(token: token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
