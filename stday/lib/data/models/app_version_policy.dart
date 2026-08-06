class AppVersionPolicy {
  const AppVersionPolicy({
    required this.platform,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.title,
    required this.message,
    required this.storeUrl,
    required this.appleAppId,
  });

  final String platform;
  final String latestVersion;
  final String minSupportedVersion;
  final String title;
  final String message;
  final String storeUrl;
  final int appleAppId;

  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    return AppVersionPolicy(
      platform: json['platform'] as String? ?? 'ios',
      latestVersion: json['latest_version'] as String? ?? '',
      minSupportedVersion: json['min_supported_version'] as String? ?? '',
      title: json['title'] as String? ?? '需要更新后才能继续使用',
      message: json['message'] as String? ??
          '当前版本已停止支持，请前往 App Store 更新至最新版本。',
      storeUrl: json['store_url'] as String? ??
          'https://apps.apple.com/app/id6782086773',
      appleAppId: (json['apple_app_id'] as num?)?.toInt() ?? 6782086773,
    );
  }
}
