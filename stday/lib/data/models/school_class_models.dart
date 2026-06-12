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
      defaultClass: json['default_class'] as String? ?? '测试班',
      classes: raw.map((e) => '$e').toList(),
    );
  }
}
