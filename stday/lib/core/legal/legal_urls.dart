import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static Uri uriForDocumentId(String documentId) {
    if (documentId == 'privacy_policy') {
      return Uri.parse(privacyPolicy);
    }
    return Uri.parse(termsOfUse);
  }

  /// 在系统浏览器中打开法律文档；成功返回 true。
  static Future<bool> openInBrowser(String documentId) async {
    final uri = uriForDocumentId(documentId);
    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stack) {
      debugPrint('LegalUrls.openInBrowser failed: $error\n$stack');
      return false;
    }
  }
}
