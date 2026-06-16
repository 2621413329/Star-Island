import 'package:flutter/material.dart';

import '../../../core/models/reminder_record.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../design_system/island_decorations.dart';
import 'reminder_icon_preview.dart';

/// 添加 / 编辑提醒的底部表单。
Future<ReminderRecord?> showReminderEditorSheet({
  required BuildContext context,
  required MoodPalette palette,
  required List<String> iconAssets,
  required String defaultIcon,
  ReminderRecord? initial,
}) {
  return showModalBottomSheet<ReminderRecord>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReminderEditorSheet(
      palette: palette,
      iconAssets: iconAssets,
      defaultIcon: defaultIcon,
      initial: initial,
    ),
  );
}

class _ReminderEditorSheet extends StatefulWidget {
  const _ReminderEditorSheet({
    required this.palette,
    required this.iconAssets,
    required this.defaultIcon,
    this.initial,
  });

  final MoodPalette palette;
  final List<String> iconAssets;
  final String defaultIcon;
  final ReminderRecord? initial;

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late final TextEditingController _textController;
  late TimeOfDay _time;
  late String _iconAsset;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _textController = TextEditingController(text: initial?.text ?? '');
    _time = _parseTime(initial?.time ?? '08:00');
    _iconAsset = initial?.iconAsset ?? widget.defaultIcon;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    final h = int.tryParse(parts.elementAtOrNull(0) ?? '');
    final m = int.tryParse(parts.elementAtOrNull(1) ?? '');
    if (h == null || m == null) return const TimeOfDay(hour: 8, minute: 0);
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: '选择提醒时间',
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入提醒文案')),
      );
      return;
    }
    final record = ReminderRecord(
      id: widget.initial?.id ?? ReminderRecord.newReminderId(),
      time: _formatTime(_time),
      text: text,
      iconAsset: _iconAsset,
      enabled: widget.initial?.enabled ?? true,
    );
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.primary.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? '编辑提醒' : '添加提醒',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              _PreviewCard(
                palette: palette,
                time: _formatTime(_time),
                text: _textController.text.isEmpty
                    ? '提醒文案预览'
                    : _textController.text,
                iconAsset: _iconAsset,
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('提示时间'),
                trailing: TextButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(_formatTime(_time)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLength: 80,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '提示文本',
                  hintText: '例如：今天最值得记录的一件事是什么？',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text(
                '选择图标',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.primary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              if (widget.iconAssets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '图标库暂无资源，请将 PNG/SVG 放入 assets/images/companion/times/',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: palette.primary.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: widget.iconAssets.length,
                  itemBuilder: (context, index) {
                    final asset = widget.iconAssets[index];
                    final selected = asset == _iconAsset;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onTap: () => setState(() => _iconAsset = asset),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.accent.withValues(alpha: 0.14)
                                : palette.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? palette.accent
                                  : palette.primary.withValues(alpha: 0.12),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: ReminderIconPreview(
                            assetPath: asset,
                            size: 32,
                            color: selected ? palette.accent : palette.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: palette.accent,
                ),
                child: Text(_isEditing ? '保存修改' : '添加提醒'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.palette,
    required this.time,
    required this.text,
    required this.iconAsset,
  });

  final MoodPalette palette;
  final String time;
  final String text;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(10),
            child: ReminderIconPreview(
              assetPath: iconAsset,
              size: 32,
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: palette.primary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _ListElementOrNull on List<String> {
  String? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
