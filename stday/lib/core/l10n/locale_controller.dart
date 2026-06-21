import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../data/repositories/app_repository.dart';

const _prefsLocaleKey = 'app_locale_override';

/// 应用支持的语言（BCP-47 风格 tag）。
const supportedLocaleTags = [
  'zh_CN',
  'zh_TW',
  'en_US',
  'ja_JP',
  'ko_KR',
];

Locale localeFromTag(String tag) {
  final parts = tag.split('_');
  if (parts.length == 1) return Locale(parts[0]);
  return Locale(parts[0], parts[1]);
}

String localeToTag(Locale locale) {
  if (locale.countryCode == null || locale.countryCode!.isEmpty) {
    return locale.languageCode;
  }
  return '${locale.languageCode}_${locale.countryCode}';
}

/// 解析启动语言：用户设置 → 发布默认 → 设备 → 简体中文。
Locale resolveAppLocale({
  required String? userLocaleTag,
  required String defaultLocaleTag,
  required Locale? deviceLocale,
}) {
  for (final candidate in [
    userLocaleTag,
    defaultLocaleTag,
    deviceLocale != null ? localeToTag(deviceLocale) : null,
    'zh_CN',
  ]) {
    if (candidate == null || candidate.isEmpty) continue;
    final locale = localeFromTag(candidate);
    if (_matchesSupported(locale)) return _normalize(locale);
  }
  return const Locale('zh', 'CN');
}

bool _matchesSupported(Locale locale) {
  return AppLocalizations.supportedLocales.any(
    (supported) =>
        supported.languageCode == locale.languageCode &&
        (supported.countryCode == null ||
            locale.countryCode == null ||
            supported.countryCode == locale.countryCode),
  );
}

Locale _normalize(Locale locale) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode != locale.languageCode) continue;
    if (locale.countryCode == null ||
        supported.countryCode == null ||
        supported.countryCode == locale.countryCode) {
      return supported;
    }
  }
  if (locale.languageCode == 'zh') return const Locale('zh');
  if (locale.languageCode == 'en') return const Locale('en');
  return const Locale('zh', 'CN');
}

class LocaleSettings {
  const LocaleSettings({
    required this.locale,
    required this.defaultLocaleTag,
    this.remoteOverrides = const {},
  });

  final Locale locale;
  final String defaultLocaleTag;
  final Map<String, String> remoteOverrides;

  String resolve(String key, String bundled) {
    final value = remoteOverrides[key];
    if (value != null && value.trim().isNotEmpty) return value;
    return bundled;
  }
}

class LocaleController extends AsyncNotifier<LocaleSettings> {
  @override
  Future<LocaleSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final userTag = prefs.getString(_prefsLocaleKey);
    final defaultTag = await _loadDefaultLocaleTag();
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    final locale = resolveAppLocale(
      userLocaleTag: userTag,
      defaultLocaleTag: defaultTag,
      deviceLocale: device,
    );
    final remote = await _loadRemoteBundle(locale);
    return LocaleSettings(
      locale: locale,
      defaultLocaleTag: defaultTag,
      remoteOverrides: remote,
    );
  }

  Future<String> _loadDefaultLocaleTag() async {
    try {
      final repo = ref.read(appRepositoryProvider);
      final config = await repo.fetchI18nConfig();
      final tag = config['default_language']?.toString();
      if (tag != null && tag.isNotEmpty) return tag;
    } catch (_) {}
    return 'zh_CN';
  }

  Future<Map<String, String>> _loadRemoteBundle(Locale locale) async {
    try {
      final repo = ref.read(appRepositoryProvider);
      return await repo.fetchI18nBundle(localeToTag(locale));
    } catch (_) {
      return const {};
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLocaleKey, localeToTag(locale));
    state = await AsyncValue.guard(() async {
      final current = state.valueOrNull;
      final remote = await _loadRemoteBundle(locale);
      return LocaleSettings(
        locale: locale,
        defaultLocaleTag: current?.defaultLocaleTag ?? 'zh_CN',
        remoteOverrides: remote,
      );
    });
  }
}

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, LocaleSettings>(
  LocaleController.new,
);
