import 'dart:async';

import 'package:flutter/widgets.dart';

/// 一块岛体位图是否已经可以贴上屏幕。
abstract class IslandBodyReadyClient {
  bool get imageReady;
}

/// 收集当前预览里每一座岛的出图进度。通知延后到当前 build 之后。
class IslandBodyReadyBoard extends ChangeNotifier {
  final Set<IslandBodyReadyClient> _clients = {};
  bool _scheduled = false;
  bool _disposed = false;

  void attach(IslandBodyReadyClient client) {
    if (_disposed) return;
    _clients.add(client);
    ping();
  }

  void detach(IslandBodyReadyClient client) {
    if (_disposed) return;
    _clients.remove(client);
    ping();
  }

  void ping() {
    if (_disposed || _scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (_disposed || !hasListeners) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// 至少有一座岛，且每一座都已经画完或确认失败。
  bool get settled =>
      _clients.isNotEmpty && _clients.every((client) => client.imageReady);
}

class IslandBodyReadyScope extends InheritedWidget {
  const IslandBodyReadyScope({
    super.key,
    required this.board,
    required super.child,
  });

  final IslandBodyReadyBoard board;

  static IslandBodyReadyBoard? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<IslandBodyReadyScope>();
    return scope?.board;
  }

  @override
  bool updateShouldNotify(IslandBodyReadyScope oldWidget) =>
      board != oldWidget.board;
}
