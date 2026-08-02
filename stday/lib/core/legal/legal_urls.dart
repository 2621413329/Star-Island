import '../config/app_config.dart';

/// App Store / 应用内使用的公开法律文档 URL。
///
/// 这些页面由后端静态托管，审核与元数据必须使用可公网访问的链接。
abstract final class LegalUrls {
  static String get base => '${AppConfig.productionApiBaseUrl}/legal';

  /// Terms of Use (EULA) — 填入 App Store 描述或自定义 EULA，并在订阅页展示。
  static String get termsOfUse => '$base/terms';

  /// Privacy Policy — 填入 App Store Connect「隐私政策」字段。
  static String get privacyPolicy => '$base/privacy';

  /// Apple 标准 EULA（若改用标准条款，可在 App 描述中附此链接）。
  static const appleStandardEula =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
}
