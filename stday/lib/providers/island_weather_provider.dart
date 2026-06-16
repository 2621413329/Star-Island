import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/weather/island_weather_service.dart';
import '../core/weather/real_weather_snapshot.dart';

final islandWeatherServiceProvider = Provider<IslandWeatherService>(
  (_) => IslandWeatherService(),
);

/// 当日真实天气；失败时返回 null，岛屿回退为纯心情氛围。
final islandWeatherProvider = FutureProvider<RealWeatherSnapshot?>((ref) async {
  return ref.read(islandWeatherServiceProvider).fetchToday();
});
