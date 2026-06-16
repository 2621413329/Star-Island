import 'package:dio/dio.dart';
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
      final response = await _dio.get<Map<String, dynamic>>(
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
      );
    } catch (_) {
      return null;
    }
  }

  Future<({double latitude, double longitude})> _resolveCoordinates() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (latitude: defaultLatitude, longitude: defaultLongitude);
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return (latitude: defaultLatitude, longitude: defaultLongitude);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return (latitude: defaultLatitude, longitude: defaultLongitude);
    }
  }
}
