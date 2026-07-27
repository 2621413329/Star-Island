/// 来自 Open-Meteo 的当日实况天气快照。
class RealWeatherSnapshot {
  const RealWeatherSnapshot({
    required this.weatherCode,
    required this.windSpeedKmh,
    required this.isDay,
    required this.fetchedAt,
    this.latitude,
    this.longitude,
    this.locationName,
    this.usedFallbackCoordinates = false,
  });

  /// WMO 天气码，见 Open-Meteo 文档。
  final int weatherCode;

  final double windSpeedKmh;
  final bool isDay;
  final DateTime fetchedAt;
  final double? latitude;
  final double? longitude;

  /// 反查得到的所在地名称（城市/区县等）。
  final String? locationName;

  /// GPS 未授权/失败时使用了默认坐标，不应展示为用户真实位置。
  final bool usedFallbackCoordinates;

  bool get isFresh {
    final age = DateTime.now().difference(fetchedAt);
    return age.inHours < 3;
  }
}
