import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/story_day_provider.dart';

/// 语音日常 AI 分析进行中时，定时刷新列表直至 `speech_status` 完成。
Future<DailyMomentModel> waitForVoiceMomentAnalysis(
  WidgetRef ref,
  String momentId, {
  Duration interval = const Duration(seconds: 2),
  int maxAttempts = 30,
}) async {
  final repo = ref.read(appRepositoryProvider);
  DailyMomentModel? latest;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final moments = await repo.listTodayMoments();
    for (final moment in moments) {
      if (moment.id != momentId) continue;
      latest = moment;
      final status = moment.speechStatus;
      if (status != null && status != 'pending') {
        return moment;
      }
      break;
    }
    if (attempt < maxAttempts - 1) {
      await Future.delayed(interval);
    }
  }
  if (latest != null) return latest;
  throw StateError('Voice moment $momentId not found');
}

bool voiceMomentAnalysisPending(DailyMomentModel moment) {
  return moment.isVoice &&
      (moment.speechStatus == null || moment.speechStatus == 'pending');
}

/// 语音日常 AI 分析进行中时，定时刷新列表直至 `speech_status` 完成。
class VoiceAnalysisPollHost extends ConsumerStatefulWidget {
  const VoiceAnalysisPollHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceAnalysisPollHost> createState() =>
      _VoiceAnalysisPollHostState();
}

class _VoiceAnalysisPollHostState extends ConsumerState<VoiceAnalysisPollHost> {
  Timer? _timer;
  int _pollCount = 0;

  bool _hasPendingVoiceAnalysis(List<DailyMomentModel> moments) {
    return moments.any(voiceMomentAnalysisPending);
  }

  void _syncPolling(List<DailyMomentModel> moments) {
    if (!_hasPendingVoiceAnalysis(moments)) {
      _timer?.cancel();
      _timer = null;
      _pollCount = 0;
      return;
    }
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _pollCount += 1;
      await ref.read(todayMomentsProvider.notifier).refresh();
      await ref.read(storyDayViewProvider.notifier).refresh();
      if (_pollCount >= 20) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<DailyMomentModel>>>(todayMomentsProvider,
        (previous, next) {
      final moments = next.valueOrNull;
      if (moments != null) _syncPolling(moments);
    });
    final moments = ref.watch(todayMomentsProvider).valueOrNull;
    if (moments != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncPolling(moments);
      });
    }
    return widget.child;
  }
}
