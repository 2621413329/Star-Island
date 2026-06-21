import '../../core/config/app_config.dart';

String momentVoiceFullUrl(String? urlPath) {
  if (urlPath == null || urlPath.isEmpty) return '';
  if (urlPath.startsWith('http://') || urlPath.startsWith('https://')) {
    return urlPath;
  }
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final path = urlPath.startsWith('/') ? urlPath : '/$urlPath';
  return '$base$path';
}

String formatVoiceDuration(int seconds) {
  final safe = seconds.clamp(0, 5999);
  final m = safe ~/ 60;
  final s = safe % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
