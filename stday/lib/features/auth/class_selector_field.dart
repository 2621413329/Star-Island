import 'package:flutter/material.dart';

import '../../core/constants/school_classes.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';

/// 登录 / 注册共用的班级下拉。
class ClassSelectorField extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          value: schoolClassOptions.contains(value) ? value : defaultClassName,
          style: itemStyle,
          items: [
            for (final name in schoolClassOptions)
              DropdownMenuItem(value: name, child: Text(name, style: itemStyle)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
