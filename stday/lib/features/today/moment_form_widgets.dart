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
  OverlayEntry? _listeningBannerEntry;

  @override
  void dispose() {
    _hideListeningBanner();
    _speechInput.dispose();
    super.dispose();
  }

  bool get _shouldShowListeningBanner => _holdingSpeech || _listening;

  void _syncListeningBanner() {
    if (_shouldShowListeningBanner) {
      _showListeningBanner();
    } else {
      _hideListeningBanner();
    }
  }

  void _showListeningBanner() {
    if (_listeningBannerEntry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _listeningBannerEntry = OverlayEntry(
      builder: (ctx) => const Stack(
        children: [
          _SpeechListeningTopBanner(),
        ],
      ),
    );
    overlay.insert(_listeningBannerEntry!);
  }

  void _hideListeningBanner() {
    _listeningBannerEntry?.remove();
    _listeningBannerEntry = null;
  }

  Future<void> _startListening() async {
    debugPrint('=== START LISTENING ===');
    debugPrint('isSupported=${SpeechNoteInput.isSupported}');
    if (!SpeechNoteInput.isSupported) {
      _showSpeechMessage('当前平台暂不支持语音转文字，请使用键盘输入');
      return;
    }
    if (_speechInput.isListening) {
      debugPrint('already listening, skip start');
      return;
    }
    _holdingSpeech = true;
    _captureSpeechInsertionBounds();
    _syncListeningBanner();
    final ok = await _speechInput.start(forceStreaming: true);
    debugPrint('speech start result=$ok');
    if (!_holdingSpeech) {
      await _speechInput.stop();
    }
  }

  Future<void> _stopListening() async {
    debugPrint('=== STOP LISTENING ===');
    _holdingSpeech = false;
    _syncListeningBanner();
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
    debugPrint('set listening ${listening ? 'true' : 'false'}');
    setState(() => _listening = listening);
    _syncListeningBanner();
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
                // Listener 走原始指针事件，避免 TextField suffixIcon 内 GestureDetector 被手势竞技场拦截。
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    debugPrint('=== MIC POINTER DOWN ===');
                    unawaited(_startListening());
                  },
                  onPointerUp: (_) {
                    debugPrint('=== MIC POINTER UP ===');
                    unawaited(_stopListening());
                  },
                  onPointerCancel: (_) {
                    debugPrint('=== MIC POINTER CANCEL ===');
                    unawaited(_stopListening());
                  },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _listening
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
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

class _SpeechListeningTopBanner extends StatefulWidget {
  const _SpeechListeningTopBanner();

  @override
  State<_SpeechListeningTopBanner> createState() =>
      _SpeechListeningTopBannerState();
}

class _SpeechListeningTopBannerState extends State<_SpeechListeningTopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final primary = Theme.of(context).colorScheme.primary;

    return Positioned(
      top: top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F2).withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_rounded, size: 20, color: primary),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            '正在语音识别中，松开按钮结束语音转文字',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A3F36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
