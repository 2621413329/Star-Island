import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/moment_limits.dart';
import '../../core/sync/client_event_id.dart';
import '../../core/voice/story_voice_recorder.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/pressable_feedback.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/mood_status_provider.dart';
import '../../providers/story_day_provider.dart';
import 'moment_form_widgets.dart';
import 'moment_photo_section.dart';
import 'widgets/story_voice_bubble.dart';
import 'widgets/story_voice_input_panel.dart';
import 'write_story_draft_store.dart';

enum StoryInputMode { text, voice }

const _placeholders = [
  '今天发生了什么？',
  '有什么值得记录的事情？',
  '今天最大的收获是什么？',
  '今天遇到了什么挑战？',
  '有什么想法想留下来？',
];

const _expandedSheetFactor = 0.78;
const _collapsedSheetFactor = 0.16;
const _closeSheetFactor = 0.1;

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
  final _scrollController = ScrollController();
  bool _submitting = false;
  bool _exitHandled = false;
  bool _submittedSuccessfully = false;
  double _sheetFactor = _expandedSheetFactor;
  String _placeholder = _placeholders.first;
  Timer? _placeholderTimer;
  List<MomentPhotoDraft> _photos = const [];
  final Set<String> _removedPhotoIds = {};
  StoryInputMode _inputMode = StoryInputMode.text;
  String? _uploadStatus;

  static const _onSurface = Color(0xFF3D3229);
  static const _onSurfaceVariant = Color(0xFF8C7B6B);

  bool get _isCollapsed => _sheetFactor <= _collapsedSheetFactor + 0.04;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing?.note != null) {
      _noteCtrl.text = editing!.note!;
    }
    if (editing?.isVoice == true) {
      _inputMode = StoryInputMode.voice;
    }
    if (editing != null) {
      _photos = editing.photos.map(MomentPhotoDraft.fromModel).toList();
    } else {
      final draft = WriteStoryDraftStore.peek();
      if (draft != null) {
        _noteCtrl.text = draft.note;
        _photos = draft.photos;
      }
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
    _scrollController.dispose();
    if (!_exitHandled &&
        !_submittedSuccessfully &&
        widget.editing == null &&
        !_submitting) {
      _persistDraftIfNeeded();
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _hasInput =>
      _inputMode == StoryInputMode.voice ||
      _noteCtrl.text.trim().isNotEmpty ||
      _photos.isNotEmpty;

  bool get _canSubmit =>
      !_submitting &&
      _inputMode == StoryInputMode.text &&
      _hasInput &&
      _noteCtrl.text.trim().length <= momentNoteMaxLength;

  void _persistDraftIfNeeded() {
    if (widget.editing != null) return;
    if (_hasInput) {
      WriteStoryDraftStore.save(note: _noteCtrl.text, photos: _photos);
    } else {
      WriteStoryDraftStore.clear();
    }
  }

  void _closeSheet({bool persistDraft = true}) {
    if (_exitHandled || !mounted) return;
    _exitHandled = true;
    if (persistDraft && widget.editing == null) {
      _persistDraftIfNeeded();
    }
    Navigator.of(context).maybePop();
  }

  void _onHandleDragUpdate(DragUpdateDetails details) {
    if (_submitting) return;
    final screenH = MediaQuery.sizeOf(context).height;
    setState(() {
      _sheetFactor = (_sheetFactor - (details.primaryDelta ?? 0) / screenH)
          .clamp(0.0, 0.92);
    });
  }

  void _onHandleDragEnd(DragEndDetails details) {
    if (_submitting) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_sheetFactor < _closeSheetFactor || velocity > 850) {
      _closeSheet(persistDraft: true);
      return;
    }
    setState(() {
      _sheetFactor = _sheetFactor < 0.45
          ? _collapsedSheetFactor
          : _expandedSheetFactor;
    });
  }

  void _onScrimTap() {
    if (_submitting) return;
    if (!_isCollapsed) {
      setState(() => _sheetFactor = _collapsedSheetFactor);
      return;
    }
    _closeSheet(persistDraft: true);
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

  void _onPhotosChanged(List<MomentPhotoDraft> next) {
    final removedRemote = _photos
        .where((p) => !p.isLocal && p.id != null)
        .where((p) => !next.any((n) => n.id == p.id))
        .map((p) => p.id!);
    setState(() {
      _removedPhotoIds.addAll(removedRemote);
      _photos = next;
    });
  }

  Future<void> _syncPhotos(String momentId, AppRepository repo) async {
    for (final photoId in _removedPhotoIds) {
      await repo.deleteMomentPhoto(momentId: momentId, photoId: photoId);
    }
    for (final draft in _photos.where((p) => p.isLocal)) {
      await repo.uploadMomentPhoto(momentId: momentId, file: draft.file!);
    }
  }

  Future<void> _submitVoice(VoiceRecordingResult recording) async {
    if (_submitting || widget.editing != null) return;
    setState(() {
      _submitting = true;
      _uploadStatus = '录音上传中...';
    });
    try {
      final repo = ref.read(appRepositoryProvider);
      await repo.createVoiceMoment(
        file: recording.file,
        voiceDuration: recording.durationSec,
        clientEventId: ClientEventId.next('daily-moment-voice'),
      );
      if (!mounted) return;
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodStatusViewProvider);
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
      _syncDailyMoodReportSilently();
      _submittedSuccessfully = true;
      _exitHandled = true;
      WriteStoryDraftStore.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音记录已保存')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadStatus = null;
        });
      }
    }
  }

  Future<void> _toggleInputMode() async {
    if (_submitting || widget.editing != null) return;
    if (_inputMode == StoryInputMode.voice) {
      setState(() => _inputMode = StoryInputMode.text);
      return;
    }
    final recorder = StoryVoiceRecorder();
    final granted = await recorder.ensurePermission(
      onMessage: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
    await recorder.dispose();
    if (!granted || !mounted) return;
    setState(() => _inputMode = StoryInputMode.voice);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final trimmed = _noteCtrl.text.trim();
    final note = trimmed.isNotEmpty ? trimmed : '（照片记录）';
    setState(() => _submitting = true);
    try {
      final repo = ref.read(appRepositoryProvider);
      late final DailyMomentModel moment;
      if (widget.editing != null) {
        moment = await repo.updateMoment(id: widget.editing!.id, note: note);
      } else {
        moment = await repo.createMoment(
          note: note,
          clientEventId: ClientEventId.next('daily-moment'),
        );
      }
      String? photoWarning;
      try {
        await _syncPhotos(moment.id, repo);
      } catch (e) {
        photoWarning = '故事已保存，但照片上传失败：$e';
      }
      if (!mounted) return;
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodStatusViewProvider);
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
      _syncDailyMoodReportSilently();
      _submittedSuccessfully = true;
      _exitHandled = true;
      WriteStoryDraftStore.clear();
      _noteCtrl.clear();
      _photos = const [];
      if (photoWarning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(photoWarning)),
        );
      }
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
    final sheetHeight = MediaQuery.sizeOf(context).height * _sheetFactor;

    return Scaffold(
      backgroundColor:
          Colors.black.withValues(alpha: _isCollapsed ? 0.12 : 0.35),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _onScrimTap,
                child: Container(color: Colors.transparent),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: sheetHeight,
                width: double.infinity,
                child: Material(
                  color: palette.card,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  elevation: 12,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: _onHandleDragUpdate,
                          onVerticalDragEnd: _onHandleDragEnd,
                          child: Center(
                            child: Container(
                              width: 72,
                              height: 32,
                              alignment: Alignment.center,
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      palette.accent.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isCollapsed) ...[
                          Expanded(
                            child: ListView(
                              controller: _scrollController,
                              children: [
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                if (_submitting)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 28),
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(
                                            color: palette.accent),
                                        const SizedBox(height: 12),
                                        Text(
                                          _uploadStatus ??
                                              '小星正在理解你的故事…',
                                          style:
                                              TextStyle(color: palette.accent),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _inputMode == StoryInputMode.text
                                              ? '文字记录'
                                              : '语音记录',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: palette.primary
                                                .withValues(alpha: 0.82),
                                          ),
                                        ),
                                      ),
                                      if (widget.editing == null && !kIsWeb)
                                        IconButton(
                                          tooltip: _inputMode ==
                                                  StoryInputMode.text
                                              ? '切换到语音'
                                              : '切换到文字',
                                          onPressed: _toggleInputMode,
                                          icon: Icon(
                                            _inputMode == StoryInputMode.text
                                                ? Icons.mic_none_rounded
                                                : Icons.keyboard_outlined,
                                            color: palette.accent,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_inputMode == StoryInputMode.text) ...[
                                    MomentNoteField(
                                      controller: _noteCtrl,
                                      hintText: _placeholder,
                                      minLines: 6,
                                      maxLines: 12,
                                      enableSpeechInput: false,
                                      fillColor: palette.primaryContainer
                                          .withValues(alpha: 0.55),
                                    ),
                                    const SizedBox(height: 16),
                                    MomentPhotoSection(
                                      palette: palette,
                                      photos: _photos,
                                      onChanged: _onPhotosChanged,
                                    ),
                                    const SizedBox(height: 18),
                                    PressableFeedback(
                                      onTap: _canSubmit ? _submit : null,
                                      child: Container(
                                        height: 52,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _canSubmit
                                                ? [
                                                    palette.accent,
                                                    palette.primary
                                                  ]
                                                : [
                                                    palette.accent.withValues(
                                                        alpha: 0.35),
                                                    palette.primary.withValues(
                                                        alpha: 0.35),
                                                  ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          widget.editing != null
                                              ? '保存故事'
                                              : '记录并分析',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else if (widget.editing == null) ...[
                                    StoryVoiceInputPanel(
                                      palette: palette,
                                      enabled: !_submitting,
                                      onRecorded: _submitVoice,
                                      onMessage: (message) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '按住说话，松开发送；上滑取消',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.primary
                                            .withValues(alpha: 0.58),
                                      ),
                                    ),
                                  ] else if (widget.editing?.isVoice == true &&
                                      widget.editing?.voiceUrl != null) ...[
                                    StoryVoiceBubble(
                                      voiceUrl: widget.editing!.voiceUrl!,
                                      durationSec:
                                          widget.editing!.voiceDuration ?? 1,
                                      accentColor: palette.accent,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '语音故事暂不支持重新录制，可删除后新建',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.primary
                                            .withValues(alpha: 0.58),
                                      ),
                                    ),
                                  ],
                              ],
                            ),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              _hasInput ? '继续记录今天的故事…' : '今天发生了什么？',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: palette.primary.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                      ],
                    ),
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
