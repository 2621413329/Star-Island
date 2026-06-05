import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/mood_theme.dart';
import '../../design_system/island_ui.dart';

const _quickNotes = [
  '已与学生当面沟通，情绪较平稳',
  '已联系家长了解情况',
  '已转介心理老师跟进',
  '持续观察，暂未发现异常',
];

/// 移动端底部弹层：填写危险信号关注内容。
Future<String?> showRiskFollowNoteSheet(
  BuildContext context, {
  String? initialNote,
  String? studentName,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _RiskFollowSheet(
      initialNote: initialNote,
      studentName: studentName,
    ),
  );
}

class _RiskFollowSheet extends StatefulWidget {
  const _RiskFollowSheet({this.initialNote, this.studentName});

  final String? initialNote;
  final String? studentName;

  @override
  State<_RiskFollowSheet> createState() => _RiskFollowSheetState();
}

class _RiskFollowSheetState extends State<_RiskFollowSheet> {
  static const palette = defaultPalette;
  late final TextEditingController _ctrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _appendQuick(String text) {
    final cur = _ctrl.text.trim();
    _ctrl.text = cur.isEmpty ? text : '$cur\n$text';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  palette.primary.withValues(alpha: 0.85),
                                  palette.accent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '标记已关注',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                if (widget.studentName != null &&
                                    widget.studentName!.isNotEmpty)
                                  Text(
                                    widget.studentName!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: palette.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: palette.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '记录本次跟进情况，便于日后查阅。内容选填，标记后该条不再计入待关注。',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.brown.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '快捷填入',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickNotes.map((t) {
                          return ActionChip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: palette.primaryContainer,
                            side: BorderSide(
                              color: palette.accent.withValues(alpha: 0.25),
                            ),
                            onPressed: () => _appendQuick(t),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        maxLines: 6,
                        minLines: 4,
                        maxLength: 2000,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: '例如：已与小明沟通，建议家长陪同…',
                          hintStyle: TextStyle(
                            color: Colors.brown.shade200,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: palette.primaryContainer.withValues(alpha: 0.45),
                          counterStyle: const TextStyle(fontSize: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: palette.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: palette.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: IslandPrimaryAction(
                        label: '确认已关注',
                        palette: palette,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 重新激活待关注 — 移动端确认条。
Future<bool> showRiskReactivateSheet(BuildContext context) async {
  const palette = defaultPalette;
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: IslandGlassCard(
          palette: palette,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '重新激活待关注？',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                '该条危险信号将重新出现在待关注列表，底部角标会 +1。',
                style: TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF8C7B6B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IslandPrimaryAction(
                      label: '确认激活',
                      palette: palette,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}
