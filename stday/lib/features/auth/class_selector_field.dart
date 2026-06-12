import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/school_classes.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/school_class_models.dart';
import '../../providers/school_classes_provider.dart';

/// 登录 / 注册共用的班级下拉（列表来自后端 `school_classes` 表）。
class ClassSelectorField extends ConsumerStatefulWidget {
  const ClassSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.palette = defaultPalette,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final MoodPalette palette;

  @override
  ConsumerState<ClassSelectorField> createState() => _ClassSelectorFieldState();
}

class _ClassSelectorFieldState extends ConsumerState<ClassSelectorField> {
  String? _syncedSelection;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(schoolClassesProvider);
    const textColor = Color(0xFF3D3229);
    final itemStyle = appTextStyle(fontSize: 16, color: textColor);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: '班级',
        filled: true,
        fillColor: widget.palette.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: classesAsync.when(
        loading: () => SizedBox(
          height: 24,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.palette.primary.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '正在加载班级列表…',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.palette.primary.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        error: (error, _) => Row(
          children: [
            Expanded(
              child: Text(
                '班级列表加载失败',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.palette.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(schoolClassesProvider),
              child: const Text('重试'),
            ),
          ],
        ),
        data: (list) => _buildDropdown(list, itemStyle),
      ),
    );
  }

  Widget _buildDropdown(SchoolClassList list, TextStyle itemStyle) {
    final options =
        list.classes.isNotEmpty ? list.classes : schoolClassOptions;
    final selected = list.resolveSelection(widget.value);
    _syncSelection(selected);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selected,
        style: itemStyle,
        items: [
          for (final name in options)
            DropdownMenuItem(value: name, child: Text(name, style: itemStyle)),
        ],
        onChanged: (v) {
          if (v != null) widget.onChanged(v);
        },
      ),
    );
  }

  void _syncSelection(String selected) {
    if (_syncedSelection == selected && selected == widget.value) return;
    _syncedSelection = selected;
    if (selected != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onChanged(selected);
      });
    }
  }
}
