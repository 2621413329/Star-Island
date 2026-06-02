/// 开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
