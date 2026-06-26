import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/moment_limits.dart';
import '../../core/speech/speech_input_bridge.dart';
import '../../core/speech/speech_note_input.dart';
import '../../core/speech/speech_note_merge.dart';
import '../../design_system/pressable_feedback.dart';
import 'widgets/speech_dictation_overlay.dart';

class MomentNoteField extends StatefulWidget {
  const MomentNoteField({
    super.key,
    required this.controller,
    required this.hintText,
    this.textAlign = TextAlign.start,
    this.fillColor,
    this.minLines = 4,
    this.maxLines = 10,
    this.enableSpeechInput = true,
  });

  final TextEditingController controller;
  final String hintText;
  final TextAlign textAlign;
  final Color? fillColor;
  final int minLines;
  final int maxLines;
  final bool enableSpeechInput;

  @override
  State<MomentNoteField> createState() => _MomentNoteFieldState();
}

class _MomentNoteFieldState extends State<MomentNoteField> {
  final FocusNode _focusNode = FocusNode();
  late final SpeechNoteInput _speechInput = SpeechNoteInput(
    onText: _onSpeechText,
    onListening: _onSpeechListening,
    onMessage: _showSpeechMessage,
  );
  bool _listening = false;
  bool _holdingSpeech = false;
  bool _transcribing = false;
  bool _suppressLiveTranscript = true;
  String _baseText = '';
  String _sessionSpoken = '';
  int _insertStart = 0;
  int _insertEnd = 0;
  int _holdGeneration = 0;

  @override
  void dispose() {
    _speechInput.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _shouldShowListeningOverlay =>
      _holdingSpeech || _listening || _transcribing;

  void _prepareMicSession() {
    _focusNode.requestFocus();
    final text = widget.controller.text;
    var selection = widget.controller.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: 0);
    }
    widget.controller.value = TextEditingValue(text: text, selection: selection);
    _baseText = text;
    _insertStart = selection.start.clamp(0, text.length);
    _insertEnd = selection.end.clamp(0, text.length);
    _sessionSpoken = '';
  }

  Future<void> _startListening() async {
    if (!SpeechNoteInput.isSupported) {
      _showSpeechMessage('当前平台暂不支持语音转文字，请使用键盘输入');
      return;
    }
    if (_speechInput.isListening || _transcribing) return;

    final generation = ++_holdGeneration;
    _holdingSpeech = true;
    _suppressLiveTranscript = true;
    _prepareMicSession();
    setState(() {});

    final ok = await _speechInput.start(forceStreaming: true);
    if (generation != _holdGeneration) return;

    if (!_holdingSpeech) {
      await _finishTranscription();
      return;
    }
    if (!ok) {
      _holdingSpeech = false;
      _showSpeechMessage('无法启动语音识别，请检查麦克风权限后重试');
      if (mounted) setState(() {});
    }
  }

  Future<void> _stopListening() async {
    if (!_holdingSpeech && !_listening && !_transcribing) return;
    _holdingSpeech = false;
    _holdGeneration++;
    await _finishTranscription();
  }

  Future<void> _finishTranscription() async {
    if (_transcribing) return;
    _transcribing = true;
    if (mounted) setState(() {});

    var spoken = await _speechInput.finishSession();
    if (spoken.trim().isEmpty) {
      spoken = _sessionSpoken.trim();
    }
    if (spoken.isEmpty &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        await SpeechInputBridge.canStartIntentRecognition()) {
      final intentText = await SpeechInputBridge.startIntentRecognition(
        prompt: '请说出要记录的内容',
      );
      spoken = intentText?.trim() ?? '';
    }

    _transcribing = false;
    _suppressLiveTranscript = true;
    _commitSpokenText(spoken);
    if (mounted) setState(() {});
  }

  void _onSpeechText(String spoken, {required bool isFinal}) {
    if (!mounted) return;
    _sessionSpoken = spoken;
    if (!_suppressLiveTranscript) {
      _applySpokenText(spoken);
    }
  }

  void _commitSpokenText(String spoken) {
    final cleaned = spoken.trim();
    if (cleaned.isEmpty) {
      _showSpeechMessage('未识别到语音，请重试');
      return;
    }
    _applySpokenText(cleaned);
  }

  void _onSpeechListening(bool listening) {
    if (!mounted) return;
    setState(() => _listening = listening);
  }

  void _applySpokenText(String spoken) {
    final text = insertSpeechAtSelection(
      existing: _baseText,
      spoken: spoken,
      selectionStart: _insertStart,
      selectionEnd: _insertEnd,
      maxLength: momentNoteMaxLength,
    );
    final cursor = cursorAfterSpeechInsertion(
      existing: _baseText,
      spoken: spoken,
      selectionStart: _insertStart,
      selectionEnd: _insertEnd,
    );
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _baseText = text;
    _insertStart = cursor;
    _insertEnd = cursor;
    if (mounted) setState(() {});
  }

  void _showSpeechMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context) ??
        ScaffoldMessenger.maybeOf(
          Navigator.of(context, rootNavigator: true).context,
        );
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          textAlign: widget.textAlign,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          maxLength: momentNoteMaxLength,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            maxLength,
          }) {
            final limit = maxLength ?? momentNoteMaxLength;
            final ratio = currentLength / limit;
            final color = ratio >= 0.95
                ? const Color(0xFFE8A04C)
                : ratio >= 0.8
                    ? const Color(0xFFB8956A)
                    : const Color(0xFF9A8B7E);
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$currentLength / $limit',
                style: TextStyle(fontSize: 12, color: color),
              ),
            );
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: widget.fillColor,
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            suffixIcon:
                widget.enableSpeechInput ? _buildSpeechSuffix(context) : null,
          ),
        ),
        if (_shouldShowListeningOverlay && widget.enableSpeechInput)
          Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: const SpeechDictationOverlay(),
          ),
      ],
    );
  }

  Widget? _buildSpeechSuffix(BuildContext context) {
    if (!SpeechNoteInput.isSupported) {
      return IconButton(
        tooltip: '当前平台暂不支持语音转文字',
        onPressed: () => _showSpeechMessage(
          '当前平台暂不支持语音转文字，请使用键盘输入',
        ),
        icon: Icon(
          Icons.mic_none_rounded,
          color: Theme.of(context).disabledColor,
        ),
      );
    }
    final active = _listening || _holdingSpeech || _transcribing;
    return Tooltip(
      message: active ? '松开完成语音转文字' : '按住说话',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          unawaited(_startListening());
        },
        onPointerUp: (_) {
          unawaited(_stopListening());
        },
        onPointerCancel: (_) {
          unawaited(_stopListening());
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(
              active ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: active ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

class MomentTagChoice {
  const MomentTagChoice({
    required this.id,
    required this.label,
    required this.color,
    this.emoji,
    this.icon,
    this.asset,
  });

  final String id;
  final String label;
  final Color color;
  final String? emoji;
  final IconData? icon;
  final String? asset;
}

class MomentTagSelector extends StatelessWidget {
  const MomentTagSelector({
    super.key,
    required this.selected,
    required this.options,
    required this.onPick,
    this.alignment = WrapAlignment.start,
    this.storyCardLayout = false,
  });

  final String? selected;
  final List<MomentTagChoice> options;
  final ValueChanged<String> onPick;
  final WrapAlignment alignment;
  final bool storyCardLayout;

  static const double _storyCardGap = 10;
  static const double _iconCellWidth = 76;
  static const double _iconGap = 18;
  static const double _widePhoneBreakpoint = 380;
  static const double _listGap = 14;

  @override
  Widget build(BuildContext context) {
    final useListCards =
        !storyCardLayout && options.any((option) => option.asset != null);
    if (useListCards) {
      return Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            MomentTagListCard(
              option: options[i],
              selected: selected == options[i].id,
              onTap: () => onPick(options[i].id),
            ),
            if (i < options.length - 1) const SizedBox(height: _listGap),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= _widePhoneBreakpoint ? 4 : 3;
        final gap = storyCardLayout ? _storyCardGap : _iconGap;
        final cellWidth = storyCardLayout
            ? (constraints.maxWidth - gap * (columns - 1)) / columns
            : _iconCellWidth;
        final gridWidth = columns * cellWidth + gap * (columns - 1);
        final sidePad = ((constraints.maxWidth - gridWidth) / 2)
            .clamp(0.0, double.infinity);

        final rows = <Widget>[];
        for (var i = 0; i < options.length; i += columns) {
          final end =
              i + columns > options.length ? options.length : i + columns;
          final rowItems = options.sublist(i, end);
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < rowItems.length; j++) ...[
                  if (j > 0) SizedBox(width: gap),
                  SizedBox(
                    width: cellWidth,
                    child: MomentTagButton(
                      option: rowItems[j],
                      selected: selected == rowItems[j].id,
                      onTap: () => onPick(rowItems[j].id),
                      storyCard: storyCardLayout && rowItems[j].asset != null,
                    ),
                  ),
                ],
              ],
            ),
          );
          if (i + columns < options.length) {
            rows.add(const SizedBox(height: 18));
          }
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        );
      },
    );
  }
}

class MomentTagListCard extends StatelessWidget {
  const MomentTagListCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MomentTagChoice option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = option.color;
    final background = Color.lerp(Colors.white, color, 0.10)!;
    final borderColor = selected ? color : color.withValues(alpha: 0.18);
    final textColor = selected ? color : const Color(0xFF5D4E44);

    return PressableFeedback(
      onTap: onTap,
      feedback: PressFeedbackType.selection,
      pressedScale: 0.985,
      selectedScale: selected ? 1.015 : 1,
      semanticLabel: option.label,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: background.withValues(alpha: selected ? 0.98 : 0.90),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: selected ? 0.22 : 0.10),
              blurRadius: selected ? 18 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _MomentTagAssetIcon(option: option, size: 40),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Icon(
              Icons.chevron_right_rounded,
              color: textColor.withValues(alpha: selected ? 0.95 : 0.72),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentTagAssetIcon extends StatelessWidget {
  const _MomentTagAssetIcon({
    required this.option,
    required this.size,
  });

  final MomentTagChoice option;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = option.color;
    if (option.asset == null) {
      return _fallback(color);
    }
    return Image.asset(
      option.asset!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallback(color),
    );
  }

  Widget _fallback(Color color) {
    if (option.icon != null) {
      return Icon(option.icon, color: color, size: size * 0.78);
    }
    return Text(
      option.emoji ?? '•',
      style: TextStyle(fontSize: size * 0.62),
    );
  }
}

class MomentTagButton extends StatefulWidget {
  const MomentTagButton({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    this.storyCard = false,
  });

  final MomentTagChoice option;
  final bool selected;
  final VoidCallback onTap;
  final bool storyCard;

  @override
  State<MomentTagButton> createState() => _MomentTagButtonState();
}

class _MomentTagButtonState extends State<MomentTagButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant MomentTagButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _pulse.forward(from: 0).then((_) => _pulse.reverse());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.option.color;
    final scale = 1.0 + (_pulse.value * 0.12);
    final useStoryCard = widget.storyCard && widget.option.asset != null;

    if (useStoryCard) {
      return PressableFeedback(
        onTap: widget.onTap,
        feedback: PressFeedbackType.selection,
        pressedScale: 0.96,
        selectedScale: widget.selected ? 1.05 * scale : 1,
        semanticLabel: widget.option.label,
        selected: widget.selected,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final frameSize = constraints.maxWidth * 0.88;
                  return Center(
                    child: _MomentTagIconFrame(
                      size: frameSize,
                      color: color,
                      selected: widget.selected,
                      asset: widget.option.asset,
                      icon: widget.option.icon,
                      emoji: widget.option.emoji,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.option.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return PressableFeedback(
      onTap: widget.onTap,
      feedback: PressFeedbackType.selection,
      pressedScale: 0.94,
      selectedScale: widget.selected ? 1.08 * scale : 1,
      semanticLabel: widget.option.label,
      selected: widget.selected,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MomentTagIconFrame(
              size: 62,
              color: color,
              selected: widget.selected,
              asset: widget.option.asset,
              icon: widget.option.icon,
              emoji: widget.option.emoji,
            ),
            const SizedBox(height: 6),
            Text(
              widget.option.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentTagIconFrame extends StatelessWidget {
  const _MomentTagIconFrame({
    required this.size,
    required this.color,
    required this.selected,
    this.asset,
    this.icon,
    this.emoji,
  });

  final double size;
  final Color color;
  final bool selected;
  final String? asset;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.68;
    final emojiSize = size * 0.56;
    final assetSize = size * 0.88;

    Widget inner;
    if (asset != null) {
      inner = Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: Image.asset(
          asset!,
          width: assetSize,
          height: assetSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => icon != null
              ? Icon(icon, size: iconSize, color: color.withValues(alpha: 0.6))
              : Text(emoji ?? '•', style: TextStyle(fontSize: emojiSize)),
        ),
      );
    } else if (icon != null) {
      inner = Icon(
        icon,
        size: iconSize,
        color: selected ? color : const Color(0xFF6E5A4A),
      );
    } else {
      inner = Text(emoji ?? '•', style: TextStyle(fontSize: emojiSize));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : color.withValues(alpha: 0.35),
          width: selected ? 2 : 1,
        ),
      ),
      child: asset != null ? ClipOval(child: inner) : inner,
    );
  }
}
