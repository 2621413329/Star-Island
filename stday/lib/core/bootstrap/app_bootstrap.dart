/// 在 [main] 中从 SharedPreferences 同步读出，避免首帧时登录态未知导致白屏/闪跳。
class AppBootstrap {
  const AppBootstrap({this.token});

  final String? token;

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}
