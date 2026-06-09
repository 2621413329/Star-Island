import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/moment_limits.dart';
import '../../core/speech/speech_note_input.dart';
import '../../design_system/pressable_feedback.dart';

class MomentNoteField extends StatefulWidget {
  const MomentNoteField({
    super.key,
    required this.controller,
    required this.hintText,
    this.textAlign = TextAlign.start,
    this.fillColor,
    this.minLines = 4,
    this.maxLines = 10,
  });

  final TextEditingController controller;
  final String hintText;
  final TextAlign textAlign;
  final Color? fillColor;
  final int minLines;
  final int maxLines;

  @override
  State<MomentNoteField> createState() => _MomentNoteFieldState();
}

class _MomentNoteFieldState extends State<MomentNoteField> {
  late final SpeechNoteInput _speechInput = SpeechNoteInput(
    onText: _onSpeechText,
    onListening: _onSpeechListening,
    onMessage: _showSpeechMessage,
  );
  bool _listening = false;
  bool _holdingSpeech = false;
  String _speechPrefix = '';
  String _speechSuffix = '';

  @override
  void dispose() {
    _speechInput.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!SpeechNoteInput.isSupported) {
      _showSpeechMessage('当前平台暂不支持语音转文字，请使用键盘输入');
      return;
    }
    if (_speechInput.isListening) return;
    _holdingSpeech = true;
    _captureSpeechInsertionBounds();
    await _speechInput.start(forceStreaming: true);
    if (!_holdingSpeech) {
      await _speechInput.stop();
    }
  }

  Future<void> _stopListening() async {
    _holdingSpeech = false;
    await _speechInput.stop();
  }

  void _captureSpeechInsertionBounds() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start =
        selection.isValid ? selection.start.clamp(0, text.length) : text.length;
    final end =
        selection.isValid ? selection.end.clamp(0, text.length) : text.length;
    final safeStart = start <= end ? start : end;
    final safeEnd = start <= end ? end : start;
    _speechPrefix = text.substring(0, safeStart);
    _speechSuffix = text.substring(safeEnd);
  }

  void _onSpeechText(String spoken, {required bool isFinal}) {
    if (!mounted) return;
    _applySpokenText(spoken, moveCursorToEnd: isFinal);
  }

  void _onSpeechListening(bool listening) {
    if (!mounted) return;
    setState(() => _listening = listening);
  }

  void _applySpokenText(String spoken, {required bool moveCursorToEnd}) {
    final text = _clipToLimit('$_speechPrefix$spoken$_speechSuffix');
    final cursorOffset = moveCursorToEnd
        ? text.length
        : (_speechPrefix.length + spoken.length).clamp(0, text.length);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  void _showSpeechMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context) ??
        ScaffoldMessenger.maybeOf(
          Navigator.of(context, rootNavigator: true).context,
        );
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _clipToLimit(String value) {
    if (value.length <= momentNoteMaxLength) return value;
    return value.substring(0, momentNoteMaxLength);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
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
        suffixIcon: SpeechNoteInput.isSupported
            ? Tooltip(
                message: _listening ? '松开停止语音转文字' : '按住说话',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => unawaited(_startListening()),
                  onTapUp: (_) => unawaited(_stopListening()),
                  onTapCancel: () => unawaited(_stopListening()),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _listening
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              )
            : IconButton(
                tooltip: '当前平台暂不支持语音转文字',
                onPressed: () => _showSpeechMessage(
                  '当前平台暂不支持语音转文字，请使用键盘输入',
                ),
                icon: Icon(
                  Icons.mic_none_rounded,
                  color: Theme.of(context).disabledColor,
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
  });

  final String id;
  final String label;
  final Color color;
  final String? emoji;
  final IconData? icon;
}

class MomentTagSelector extends StatelessWidget {
  const MomentTagSelector({
    super.key,
    required this.selected,
    required this.options,
    required this.onPick,
    this.alignment = WrapAlignment.center,
  });

  final String? selected;
  final List<MomentTagChoice> options;
  final ValueChanged<String> onPick;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      alignment: alignment,
      runAlignment: alignment,
      children: options
          .map(
            (option) => MomentTagButton(
              option: option,
              selected: selected == option.id,
              onTap: () => onPick(option.id),
            ),
          )
          .toList(),
    );
  }
}

class MomentTagButton extends StatefulWidget {
  const MomentTagButton({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MomentTagChoice option;
  final bool selected;
  final VoidCallback onTap;

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
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected
                    ? color.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: color,
                  width: widget.selected ? 3 : 1.5,
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.32),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: widget.option.icon != null
                  ? Icon(widget.option.icon, color: color, size: 30)
                  : Text(
                      widget.option.emoji ?? '•',
                      style: const TextStyle(fontSize: 26),
                    ),
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
