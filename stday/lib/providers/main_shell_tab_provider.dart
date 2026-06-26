import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 底部导航当前 Tab（0=岛屿），用于离屏时暂停 Flame 引擎。
final mainShellTabIndexProvider = StateProvider<int>((ref) => 0);
