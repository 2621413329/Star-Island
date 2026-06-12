import '../../core/constants/school_classes.dart';

class SchoolClassList {
  const SchoolClassList({
    required this.defaultClass,
    required this.classes,
  });

  final String defaultClass;
  final List<String> classes;

  factory SchoolClassList.fromJson(Map<String, dynamic> json) {
    final raw = json['classes'] as List<dynamic>? ?? [];
    return SchoolClassList(
      defaultClass: json['default_class'] as String? ?? defaultClassName,
      classes: raw.map((e) => '$e').toList(),
    );
  }

  String resolveSelection(String value) {
    final trimmed = value.trim();
    if (classes.contains(trimmed)) return trimmed;
    if (classes.contains(defaultClass)) return defaultClass;
    if (classes.isNotEmpty) return classes.first;
    return defaultClassName;
  }
}
