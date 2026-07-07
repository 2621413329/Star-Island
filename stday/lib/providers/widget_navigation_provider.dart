import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 从桌面小组件进入岛屿详情后，自动展开待办面板。
final pendingTaskDockIslandIdProvider = StateProvider<String?>((_) => null);
