import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/school_classes.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../providers/school_classes_provider.dart';

/// 登录 / 注册共用的班级下拉（列表来自后端 school_classes 表）。
class ClassSelectorField extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(schoolClassesProvider);
    final options = classesAsync.maybeWhen(
      data: (list) =>
          list.classes.isNotEmpty ? list.classes : schoolClassOptions,
      orElse: () => schoolClassOptions,
    );
    final selected = options.contains(value)
        ? value
        : (options.isNotEmpty ? options.first : defaultClassName);

    const textColor = Color(0xFF3D3229);
    final itemStyle = appTextStyle(fontSize: 16, color: textColor);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '班级',
        filled: true,
        fillColor: palette.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected,
          style: itemStyle,
          items: [
            for (final name in options)
              DropdownMenuItem(value: name, child: Text(name, style: itemStyle)),
          ],
          onChanged: classesAsync.isLoading
              ? null
              : (v) {
                  if (v != null) onChanged(v);
                },
        ),
      ),
    );
  }
}
