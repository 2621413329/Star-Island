import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../world/engine/world_state.dart';
import '../island_3d_game.dart';
import '../island_3d_support.dart';

/// 3D 岛屿视口（Android / iOS / macOS）。
class Island3DViewport extends StatefulWidget {
  const Island3DViewport({
    super.key,
    required this.worldState,
    required this.companionStyle,
    this.compact = false,
    this.scale = 1.0,
    this.onLoadFailed,
  });

  final WorldState worldState;
  final String companionStyle;
  final bool compact;
  final double scale;
  final VoidCallback? onLoadFailed;

  @override
  State<Island3DViewport> createState() => Island3DViewportState();
}

class Island3DViewportState extends State<Island3DViewport> {
  late Island3DGame _game;

  @override
  void initState() {
    super.initState();
    _game = Island3DGame(
      initialState: widget.worldState,
      companionStyle: widget.companionStyle,
      compact: widget.compact,
    );
  }

  void _handleLoadFailed(Object error) {
    Island3DSupport.disableAfterFailure();
    widget.onLoadFailed?.call();
    debugPrint('Island3DViewport load failed: $error');
  }

  @override
  void didUpdateWidget(covariant Island3DViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worldState != widget.worldState) {
      _game.applyWorldState(widget.worldState);
    }
    if (oldWidget.compact != widget.compact ||
        oldWidget.companionStyle != widget.companionStyle) {
      _game = Island3DGame(
        initialState: widget.worldState,
        companionStyle: widget.companionStyle,
        compact: widget.compact,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: widget.scale,
      alignment: Alignment.topCenter,
      child: RepaintBoundary(
        child: GameWidget(
          game: _game,
          errorBuilder: (context, error) {
            _handleLoadFailed(error);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
