import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'real_weather_snapshot.dart';

/// 通过 Open-Meteo 获取用户所在地当日天气（无需 API Key）。
class IslandWeatherService {
  IslandWeatherService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const defaultLatitude = 31.2304;
  static const defaultLongitude = 121.4737;

  Future<RealWeatherSnapshot?> fetchToday() async {
    final coords = await _resolveCoordinates();
    try {
      final weatherFuture = _dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': coords.latitude,
          'longitude': coords.longitude,
          'current': 'weather_code,wind_speed_10m,is_day',
          'timezone': 'auto',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      final locationFuture = coords.usedFallback
          ? Future<String?>.value(null)
          : _resolveLocationName(coords.latitude, coords.longitude);
      final results = await Future.wait([weatherFuture, locationFuture]);
      final response = results[0] as Response<Map<String, dynamic>>;
      final locationName = results[1] as String?;
      final current = response.data?['current'] as Map<String, dynamic>?;
      if (current == null) return null;
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;
      final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;
      final isDay = (current['is_day'] as num?)?.toInt() == 1;
      return RealWeatherSnapshot(
        weatherCode: code,
        windSpeedKmh: wind,
        isDay: isDay,
        fetchedAt: DateTime.now(),
        latitude: coords.latitude,
        longitude: coords.longitude,
        locationName: locationName,
        usedFallbackCoordinates: coords.usedFallback,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveLocationName(
    double latitude,
    double longitude,
  ) async {
    final platform = await _resolveLocationNameFromPlatform(
      latitude,
      longitude,
    );
    if (platform != null && platform.isNotEmpty) return platform;

    final bigData = await _resolveLocationNameFromBigDataCloud(
      latitude,
      longitude,
    );
    if (bigData != null && bigData.isNotEmpty) return bigData;
    return _resolveLocationNameFromNominatim(latitude, longitude);
  }

  /// 系统逆地理编码（iOS/Android 本地），国内城市名通常更稳。
  Future<String?> _resolveLocationNameFromPlatform(
    double latitude,
    double longitude,
  ) async {
    try {
      final geocoder = Geocoding(locale: const Locale('zh', 'CN'));
      final marks = await geocoder.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (marks.isEmpty) return null;
      final mark = marks.first;
      return _composePlaceLabel(
        name: _firstNonEmpty([
          mark.locality,
          mark.subLocality,
          mark.subAdministrativeArea,
          mark.name,
        ]),
        admin3: _firstNonEmpty([mark.subLocality, mark.thoroughfare]),
        admin2: _firstNonEmpty([
          mark.locality,
          mark.subAdministrativeArea,
        ]),
        admin1: mark.administrativeArea,
        country: mark.country,
      );
    } catch (_) {
      return null;
    }
  }

  /// 客户端逆向地理编码，无需 API Key，中文城市名较稳。
  Future<String?> _resolveLocationNameFromBigDataCloud(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'localityLanguage': 'zh',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      final data = response.data;
      if (data == null) return null;
      final adminNames = _adminNamesFromLocalityInfo(data['localityInfo']);
      return _composePlaceLabel(
        name: _firstNonEmpty([
          _stringField(data, 'city'),
          _stringField(data, 'locality'),
          ...adminNames.reversed,
        ]),
        admin3: _firstNonEmpty([
          _stringField(data, 'locality'),
          adminNames.length >= 3 ? adminNames.last : null,
        ]),
        admin2: _firstNonEmpty([
          _stringField(data, 'city'),
          adminNames.length >= 2 ? adminNames[adminNames.length - 1] : null,
          adminNames.length >= 3 ? adminNames[adminNames.length - 2] : null,
        ]),
        admin1: _firstNonEmpty([
          _stringField(data, 'principalSubdivision'),
          adminNames.length >= 2 ? adminNames[1] : null,
          adminNames.isNotEmpty ? adminNames.first : null,
        ]),
        country: _stringField(data, 'countryName'),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveLocationNameFromNominatim(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'jsonv2',
          'accept-language': 'zh-CN,zh',
          'zoom': 12,
          'addressdetails': 1,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
          headers: const {
            'User-Agent': 'StarIsland/1.0 (stday weather location)',
          },
        ),
      );
      final address = response.data?['address'] as Map<String, dynamic>?;
      if (address == null) {
        final display = _stringField(response.data ?? const {}, 'display_name');
        return _clipDisplayName(display);
      }
      return _composePlaceLabel(
        name: _firstNonEmpty([
          _stringField(address, 'city'),
          _stringField(address, 'town'),
          _stringField(address, 'municipality'),
          _stringField(address, 'county'),
          _stringField(address, 'suburb'),
          _stringField(address, 'village'),
        ]),
        admin3: _stringField(address, 'suburb') ??
            _stringField(address, 'district') ??
            _stringField(address, 'city_district'),
        admin2: _stringField(address, 'city') ??
            _stringField(address, 'county'),
        admin1: _stringField(address, 'state') ??
            _stringField(address, 'province'),
        country: _stringField(address, 'country'),
      );
    } catch (_) {
      return null;
    }
  }

  /// BigDataCloud `localityInfo.administrative`：由大到小的行政区名称。
  static List<String> _adminNamesFromLocalityInfo(Object? localityInfo) {
    if (localityInfo is! Map) return const [];
    final administrative = localityInfo['administrative'];
    if (administrative is! List) return const [];
    final names = <String>[];
    for (final item in administrative) {
      if (item is! Map) continue;
      final name = item['name'];
      if (name is! String) continue;
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      // 跳过国家级，避免「中国 · 某市」占满展示。
      if (trimmed == '中国' || trimmed == '中华人民共和国') continue;
      names.add(trimmed);
    }
    return names;
  }

  static String? _composePlaceLabel({
    String? name,
    String? admin3,
    String? admin2,
    String? admin1,
    String? country,
  }) {
    final cityLike = _firstNonEmpty([admin2, admin3, name]);
    final region = _firstNonEmpty([admin1]);
    if (cityLike != null && region != null && region != cityLike) {
      // 直辖市常见「上海市 · 上海市」
      if (region.replaceAll('市', '') == cityLike.replaceAll('市', '')) {
        return cityLike;
      }
      return '$region · $cityLike';
    }
    if (cityLike != null) return cityLike;
    if (region != null) return region;
    final countryName = _firstNonEmpty([country]);
    if (countryName == null ||
        countryName == '中国' ||
        countryName == '中华人民共和国') {
      return null;
    }
    return countryName;
  }

  static String? _clipDisplayName(String? display) {
    if (display == null || display.isEmpty) return null;
    final parts = display
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    if (parts.length == 1) return parts.first;
    return '${parts[1]} · ${parts[0]}';
  }

  static String? _stringField(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    // BigDataCloud localityInfo 可能是嵌套对象，忽略。
    return null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<
      ({
        double latitude,
        double longitude,
        bool usedFallback,
      })> _resolveCoordinates() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (
          latitude: defaultLatitude,
          longitude: defaultLongitude,
          usedFallback: true,
        );
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return (
          latitude: defaultLatitude,
          longitude: defaultLongitude,
          usedFallback: true,
        );
      }
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        return (
          latitude: defaultLatitude,
          longitude: defaultLongitude,
          usedFallback: true,
        );
      }
      return (
        latitude: position.latitude,
        longitude: position.longitude,
        usedFallback: false,
      );
    } catch (_) {
      return (
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        usedFallback: true,
      );
    }
  }
}
