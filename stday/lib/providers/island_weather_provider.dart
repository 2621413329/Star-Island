import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/weather/island_weather_service.dart';
import '../core/weather/real_weather_snapshot.dart';

final islandWeatherServiceProvider = Provider<IslandWeatherService>(
  (_) => IslandWeatherService(),
);

/// 为 false 时不触发 GPS/网络；首屏稳定后再开启。
final islandWeatherFetchEnabledProvider = StateProvider<bool>((ref) => false);

/// 当日真实天气；失败时返回 null，岛屿回退为纯心情氛围。
final islandWeatherProvider = FutureProvider<RealWeatherSnapshot?>((ref) async {
  if (!ref.watch(islandWeatherFetchEnabledProvider)) {
    return null;
  }
  return ref.read(islandWeatherServiceProvider).fetchToday();
});

/// 延迟开启天气拉取（GPS + Open-Meteo），移出首屏关键路径。
void scheduleDeferredIslandWeatherFetch(
  WidgetRef ref, {
  Duration delay = const Duration(milliseconds: 800),
}) {
  Future<void>.delayed(delay, () {
    ref.read(islandWeatherFetchEnabledProvider.notifier).state = true;
  });
}

/// 下拉刷新等场景：立即拉取天气。
void enableIslandWeatherFetch(WidgetRef ref) {
  ref.read(islandWeatherFetchEnabledProvider.notifier).state = true;
}
