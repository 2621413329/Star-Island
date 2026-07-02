import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';

String homeGreetingPeriod(DateTime time) {
  final hour = time.hour;
  if (hour < 6) return '夜深了';
  if (hour < 11) return '早上好';
  if (hour < 14) return '中午好';
  if (hour < 18) return '下午好';
  return '晚上好';
}

class HomeGreeting {
  const HomeGreeting({
    required this.period,
    required this.displayName,
    required this.subtitle,
  });

  final String period;
  final String displayName;
  final String subtitle;
}

final homeGreetingProvider = Provider<HomeGreeting>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final nickname = profile?.nickname?.trim();
  final name = (nickname != null && nickname.isNotEmpty) ? nickname : '星屿';
  final period = homeGreetingPeriod(DateTime.now());
  return HomeGreeting(
    period: period,
    displayName: name,
    subtitle: '今天，有没有一个你想留住的瞬间？',
  );
});
