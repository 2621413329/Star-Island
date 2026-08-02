/// App Store / 应用内使用的公开法律文档 URL。
///
/// 正式站点：https://lcxxingyu.fun （官网 SPA 路由 /privacy、/terms）。
abstract final class LegalUrls {
  static const siteBase = 'https://lcxxingyu.fun';

  /// Terms of Use (EULA) — 填入 App Store 描述或自定义 EULA，并在订阅页展示。
  static const termsOfUse = '$siteBase/terms';

  /// Privacy Policy — 填入 App Store Connect「隐私政策」字段。
  static const privacyPolicy = '$siteBase/privacy';

  /// Apple 标准 EULA（若改用标准条款，可在 App 描述中附此链接）。
  static const appleStandardEula =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
}
