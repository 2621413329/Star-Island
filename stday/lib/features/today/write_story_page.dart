import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/moment_limits.dart';
import '../../core/sync/client_event_id.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/pressable_feedback.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/mood_status_provider.dart';
import '../../providers/story_day_provider.dart';
import 'moment_form_widgets.dart';

const _placeholders = [
  '今天发生了什么？',
  '有什么值得记录的事情？',
  '今天最大的收获是什么？',
  '今天遇到了什么挑战？',
  '有什么想法想留下来？',
];

const _guidePrompts = [
  '今天最开心的事情',
  '今天最大的挑战',
  '今天学到了什么',
  '今天完成了什么',
  '今天有什么感悟',
];

Future<bool?> showWriteStoryPage(
  BuildContext context,
  WidgetRef ref, {
  DailyMomentModel? editing,
}) {
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => WriteStoryPage(editing: editing),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        );
      },
    ),
  );
}

class WriteStoryPage extends ConsumerStatefulWidget {
  const WriteStoryPage({super.key, this.editing});

  final DailyMomentModel? editing;

  @override
  ConsumerState<WriteStoryPage> createState() => _WriteStoryPageState();
}

class _WriteStoryPageState extends ConsumerState<WriteStoryPage> {
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String _placeholder = _placeholders.first;
  Timer? _placeholderTimer;

  static const _onSurface = Color(0xFF3D3229);
  static const _onSurfaceVariant = Color(0xFF8C7B6B);

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing?.note != null) {
      _noteCtrl.text = editing!.note!;
    }
    _noteCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _placeholderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _noteCtrl.text.isNotEmpty) return;
      setState(() {
        _placeholder = _placeholders[Random().nextInt(_placeholders.length)];
      });
    });
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _noteCtrl.text.trim().length >= 4 &&
      _noteCtrl.text.trim().length <= momentNoteMaxLength;

  bool get _showGuide => _noteCtrl.text.trim().length < 12;

  Future<void> _applyGuide(String prompt) async {
    final current = _noteCtrl.text.trim();
    final seed = current.isEmpty ? '$prompt：' : '$current\n$prompt：';
    _noteCtrl.text = seed;
    _noteCtrl.selection = TextSelection.collapsed(offset: seed.length);
  }

  void _syncDailyMoodReportSilently() {
    unawaited(
      ref.read(appRepositoryProvider).uploadDailyMoodReport().then((_) {
        ref.invalidate(moodReportCheckInProvider);
        ref.invalidate(moodStatusViewProvider);
        ref.invalidate(growthSummaryProvider);
      }).catchError((_) {}),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final note = _noteCtrl.text.trim();
    setState(() => _submitting = true);
    try {
      final repo = ref.read(appRepositoryProvider);
      if (widget.editing != null) {
        await repo.updateMoment(id: widget.editing!.id, note: note);
      } else {
        await repo.createMoment(
          note: note,
          clientEventId: ClientEventId.next('daily-moment'),
        );
      }
      if (!mounted) return;
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodStatusViewProvider);
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
      _syncDailyMoodReportSilently();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _submitting ? null : () => Navigator.of(context).maybePop(),
              child: Container(color: Colors.transparent),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: palette.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                elevation: 12,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '今天发生了什么？',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '记录今天值得记住的一件事',
                        style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      if (_submitting)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: palette.accent),
                              const SizedBox(height: 12),
                              Text(
                                '小星正在理解你的故事…',
                                style: TextStyle(color: palette.accent),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        MomentNoteField(
                          controller: _noteCtrl,
                          hintText: _placeholder,
                          minLines: 6,
                          maxLines: 12,
                          fillColor: palette.primaryContainer.withValues(alpha: 0.55),
                        ),
                        if (_showGuide) ...[
                          const SizedBox(height: 14),
                          const Text(
                            '不知道写什么？',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final prompt in _guidePrompts)
                                PressableFeedback(
                                  onTap: () => _applyGuide(prompt),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: palette.accent.withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: Text(
                                      prompt,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.accent.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 18),
                        PressableFeedback(
                          onTap: _canSubmit ? _submit : null,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _canSubmit
                                    ? [palette.accent, palette.primary]
                                    : [
                                        palette.accent.withValues(alpha: 0.35),
                                        palette.primary.withValues(alpha: 0.35),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.editing != null ? '保存故事' : '记录并分析',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
