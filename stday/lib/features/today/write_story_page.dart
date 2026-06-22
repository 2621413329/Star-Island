import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/moment_limits.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/sync/client_event_id.dart';
import '../../core/voice/story_voice_recorder.dart';
import '../../core/voice/voice_file_io_export.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/companion_loading.dart';
import '../../design_system/pressable_feedback.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/mood_status_provider.dart';
import '../../providers/growth_observation_provider.dart';
import '../../providers/story_day_provider.dart';
import 'moment_form_widgets.dart';
import 'moment_photo_section.dart';
import 'widgets/story_voice_bubble.dart';
import 'widgets/story_voice_input_panel.dart';
import 'voice_analysis_poll.dart';
import 'write_story_draft_store.dart';

enum StoryInputMode { text, voice }

List<String> _storyPlaceholders(AppLocalizations l10n) => [
      l10n.storyPlaceholder1,
      l10n.storyPlaceholder2,
      l10n.storyPlaceholder3,
      l10n.storyPlaceholder4,
      l10n.storyPlaceholder5,
    ];

const _collapsedSheetFactor = 0.16;
const _closeDragThreshold = 120.0;
const _maxSheetHeightFactor = 0.88;

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
  bool _collapsed = false;
  double _handleDragOffset = 0;
  String _placeholder = '';
  Timer? _placeholderTimer;
  List<MomentPhotoDraft> _photos = const [];
  final Set<String> _removedPhotoIds = {};
  StoryInputMode _inputMode = StoryInputMode.text;
  String? _uploadStatus;
  VoiceRecordingResult? _pendingVoice;

  static const _onSurface = Color(0xFF3D3229);
  static const _onSurfaceVariant = Color(0xFF8C7B6B);

  bool get _isCollapsed => _collapsed;

  bool get _keyboardVisible => MediaQuery.viewInsetsOf(context).bottom > 0;

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
      final items = _storyPlaceholders(context.l10n);
      setState(() {
        _placeholder = items[Random().nextInt(items.length)];
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final items = _storyPlaceholders(context.l10n);
      setState(() => _placeholder = items.first);
    });
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _scrollController.dispose();
    if (_pendingVoice != null) {
      unawaited(deleteVoiceFile(_pendingVoice!.path));
    }
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
      _noteCtrl.text.trim().isNotEmpty || _photos.isNotEmpty;

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
    final delta = details.primaryDelta ?? 0;
    if (delta <= 0) return;
    setState(() {
      _handleDragOffset += delta;
      if (_handleDragOffset > 48) _collapsed = true;
    });
  }

  void _onHandleDragEnd(DragEndDetails details) {
    if (_submitting) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_handleDragOffset > _closeDragThreshold || velocity > 850) {
      _closeSheet(persistDraft: true);
      return;
    }
    setState(() {
      _handleDragOffset = 0;
      if (velocity < -400) _collapsed = false;
    });
  }

  void _onScrimTap() {
    if (_submitting) return;
    final focusScope = FocusScope.of(context);
    if (focusScope.hasFocus) {
      focusScope.unfocus();
      return;
    }
    _closeSheet(persistDraft: true);
  }

  void _onVoiceRecorded(VoiceRecordingResult recording) {
    final previous = _pendingVoice;
    setState(() => _pendingVoice = recording);
    if (previous != null && previous.path != recording.path) {
      unawaited(deleteVoiceFile(previous.path));
    }
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

  Future<void> _confirmVoiceUpload() async {
    final pending = _pendingVoice;
    if (pending == null || _submitting) return;
    if (widget.editing != null) {
      await _replaceVoice(pending);
    } else {
      await _submitVoice(pending);
    }
  }

  Future<void> _replaceVoice(VoiceRecordingResult recording) async {
    final editing = widget.editing;
    if (_submitting || editing == null || !editing.isVoice) return;
    setState(() {
      _submitting = true;
      _uploadStatus = context.l10n.storyVoiceUploading;
    });
    try {
      final repo = ref.read(appRepositoryProvider);
      final moment = await repo.replaceVoiceMoment(
        id: editing.id,
        filePath: recording.path,
        voiceDuration: recording.durationSec,
      );
      if (mounted) {
        setState(() => _uploadStatus = context.l10n.storyAnalyzing);
      }
      await waitForVoiceMomentAnalysis(ref, moment.id);
      String? photoWarning;
      try {
        await _syncPhotos(moment.id, repo);
      } catch (e) {
        photoWarning = context.l10n.storySavedPhotoUploadFailed(e.toString());
      }
      await deleteVoiceFile(recording.path);
      if (mounted) setState(() => _pendingVoice = null);
      if (!mounted) return;
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodStatusViewProvider);
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
      ref.invalidate(weeklySummaryProvider);
      _syncDailyMoodReportSilently();
      _submittedSuccessfully = true;
      _exitHandled = true;
      if (photoWarning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(photoWarning)),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.storyVoiceSaved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed(e.toString()))),
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

  Future<void> _submitVoice(VoiceRecordingResult recording) async {
    if (_submitting || widget.editing != null) return;
    setState(() {
      _submitting = true;
      _uploadStatus = context.l10n.storyVoiceUploading;
    });
    try {
      final repo = ref.read(appRepositoryProvider);
      final moment = await repo.createVoiceMoment(
        filePath: recording.path,
        voiceDuration: recording.durationSec,
        clientEventId: ClientEventId.next('daily-moment-voice'),
      );
      if (mounted) {
        setState(() => _uploadStatus = context.l10n.storyAnalyzing);
      }
      await waitForVoiceMomentAnalysis(ref, moment.id);
      String? photoWarning;
      try {
        await _syncPhotos(moment.id, repo);
      } catch (e) {
        photoWarning = context.l10n.storySavedPhotoUploadFailed(e.toString());
      }
      await deleteVoiceFile(recording.path);
      if (mounted) setState(() => _pendingVoice = null);
      if (!mounted) return;
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodStatusViewProvider);
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
      ref.invalidate(weeklySummaryProvider);
      _syncDailyMoodReportSilently();
      _submittedSuccessfully = true;
      _exitHandled = true;
      WriteStoryDraftStore.clear();
      if (photoWarning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(photoWarning)),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.storyVoiceSaved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed(e.toString()))),
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
    final note = trimmed.isNotEmpty ? trimmed : context.l10n.storyPhotoOnlyNote;
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
        photoWarning = context.l10n.storySavedPhotoUploadFailed(e.toString());
      }
      if (!mounted) return;
      await ref.read(todayMomentsProvider.notifier).refresh();
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodStatusViewProvider);
      ref.invalidate(moodReportCheckInProvider);
      ref.invalidate(growthSummaryProvider);
      ref.invalidate(weeklySummaryProvider);
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
          SnackBar(content: Text(context.l10n.saveFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final l10n = context.l10n;
    final remote = ref.watch(localeControllerProvider).valueOrNull?.remoteOverrides ?? {};
    String t(String key, String Function() fallback) {
      final value = remote[key];
      if (value != null && value.trim().isNotEmpty) return value;
      return fallback();
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = screenHeight * _maxSheetHeightFactor;
    final collapsedSheetHeight = screenHeight * _collapsedSheetFactor;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor:
          Colors.black.withValues(alpha: _isCollapsed ? 0.12 : 0.35),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _onScrimTap,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: _isCollapsed ? collapsedSheetHeight : null,
                constraints: _isCollapsed
                    ? null
                    : BoxConstraints(maxHeight: maxSheetHeight),
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
                      16 + bottomInset,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        if (!_isCollapsed)
                          Flexible(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: _keyboardVisible,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                child: _buildSheetContent(
                                  palette: palette,
                                  l10n: l10n,
                                  t: t,
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              _hasInput || _pendingVoice != null
                                  ? t('storyContinueWriting',
                                      () => l10n.storyContinueWriting)
                                  : t('storyTitle', () => l10n.storyTitle),
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
            if (_submitting)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.48),
                    child: MoodCompanionLoadingBody(
                      message: _uploadStatus ?? l10n.storyAnalyzing,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetContent({
    required MoodPalette palette,
    required AppLocalizations l10n,
    required String Function(String key, String Function() fallback) t,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('storyTitle', () => l10n.storyTitle),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t('storySubtitle', () => l10n.storySubtitle),
          style: const TextStyle(
            fontSize: 14,
            color: _onSurfaceVariant,
          ),
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
                  _uploadStatus ?? t('storyAnalyzing', () => l10n.storyAnalyzing),
                  style: TextStyle(color: palette.accent),
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
                      ? t('storyTextMode', () => l10n.storyTextMode)
                      : t('storyVoiceMode', () => l10n.storyVoiceMode),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.primary.withValues(alpha: 0.82),
                  ),
                ),
              ),
              if (widget.editing == null && !kIsWeb)
                IconButton(
                  tooltip: _inputMode == StoryInputMode.text
                      ? t('storySwitchToVoice', () => l10n.storySwitchToVoice)
                      : t('storySwitchToText', () => l10n.storySwitchToText),
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
              fillColor: palette.primaryContainer.withValues(alpha: 0.55),
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
                        ? [palette.accent, palette.primary]
                        : [
                            palette.accent.withValues(alpha: 0.35),
                            palette.primary.withValues(alpha: 0.35),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.editing != null
                      ? t('storySaveStory', () => l10n.storySaveStory)
                      : t('storyRecordAndAnalyze',
                          () => l10n.storyRecordAndAnalyze),
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
              onRecorded: _onVoiceRecorded,
              onMessage: (message) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
            ),
            if (_pendingVoice != null) ...[
              const SizedBox(height: 12),
              StoryVoiceBubble(
                key: ValueKey(_pendingVoice!.path),
                localFilePath: _pendingVoice!.path,
                durationSec: _pendingVoice!.durationSec,
                accentColor: palette.accent,
              ),
              const SizedBox(height: 12),
              PressableFeedback(
                onTap: _confirmVoiceUpload,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.accent, palette.primary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    t('storyVoiceSend', () => l10n.storyVoiceSend),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            MomentPhotoSection(
              palette: palette,
              photos: _photos,
              onChanged: _onPhotosChanged,
            ),
            const SizedBox(height: 12),
            Text(
              t('storyVoiceHint', () => l10n.storyVoiceHint),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: palette.primary.withValues(alpha: 0.58),
              ),
            ),
          ] else if (widget.editing?.isVoice == true) ...[
            if (_pendingVoice == null &&
                widget.editing?.voiceUrl != null) ...[
              StoryVoiceBubble(
                key: ValueKey(widget.editing!.voiceUrl),
                voiceUrl: widget.editing!.voiceUrl!,
                durationSec: widget.editing!.voiceDuration ?? 1,
                accentColor: palette.accent,
              ),
              const SizedBox(height: 12),
            ],
            if (!kIsWeb)
              StoryVoiceInputPanel(
                palette: palette,
                enabled: !_submitting,
                onRecorded: _onVoiceRecorded,
                onMessage: (message) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
              ),
            if (_pendingVoice != null) ...[
              const SizedBox(height: 12),
              StoryVoiceBubble(
                key: ValueKey(_pendingVoice!.path),
                localFilePath: _pendingVoice!.path,
                durationSec: _pendingVoice!.durationSec,
                accentColor: palette.accent,
              ),
              const SizedBox(height: 12),
              PressableFeedback(
                onTap: _confirmVoiceUpload,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.accent, palette.primary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    t('storyVoiceSend', () => l10n.storyVoiceSend),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            MomentPhotoSection(
              palette: palette,
              photos: _photos,
              onChanged: _onPhotosChanged,
            ),
            const SizedBox(height: 12),
            Text(
              t('storyVoiceNoRerecord', () => l10n.storyVoiceNoRerecord),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: palette.primary.withValues(alpha: 0.58),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
