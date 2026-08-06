/// 语义化版本比较（major.minor.patch）。
class AppVersion {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// 解析 `1.3.1` / `1.3.1+7` / `v1.3`；非法输入返回 null。
  static AppVersion? tryParse(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final withoutBuild = cleaned.split('+').first.trim();
    final withoutPrefix = withoutBuild.startsWith('v') || withoutBuild.startsWith('V')
        ? withoutBuild.substring(1)
        : withoutBuild;
    final parts = withoutPrefix.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final numbers = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part.trim());
      if (value == null || value < 0) return null;
      numbers.add(value);
    }
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return AppVersion(numbers[0], numbers[1], numbers[2]);
  }

  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// 本地版本是否低于最低支持版本（需要强制更新）。
bool requiresForceUpdate({
  required String localVersion,
  required String minSupportedVersion,
}) {
  final local = AppVersion.tryParse(localVersion);
  final min = AppVersion.tryParse(minSupportedVersion);
  if (local == null || min == null) return false;
  return local < min;
}
