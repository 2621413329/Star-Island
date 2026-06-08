import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/constants/moment_limits.dart';
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
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  late String _speechPrefix;
  late String _speechSuffix;

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    _speechReady = _speechReady ||
        await _speech.initialize(
          onStatus: _handleSpeechStatus,
          onError: (_) {
            if (mounted) setState(() => _listening = false);
          },
        );
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法使用语音输入，请检查麦克风权限')),
      );
      return;
    }

    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    _speechPrefix = text.substring(0, start);
    _speechSuffix = text.substring(end);

    setState(() => _listening = true);
    await _speech.listen(
      onResult: _handleSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: 'zh_CN',
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _listening = false);
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    final spoken = result.recognizedWords.trim();
    final text = _clipToLimit('$_speechPrefix$spoken$_speechSuffix');
    final cursorOffset = (_speechPrefix.length + spoken.length).clamp(
      0,
      text.length,
    );
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
    if (result.finalResult && mounted) {
      setState(() => _listening = false);
    }
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
        suffixIcon: IconButton(
          tooltip: _listening ? '停止语音输入' : '语音输入',
          onPressed: _toggleListening,
          icon: Icon(
            _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: _listening ? Theme.of(context).colorScheme.primary : null,
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
                fontWeight:
                    widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
