import 'package:flutter/material.dart';

import '../../../world/engine/world_state.dart';

/// Web/debug fallback for platforms where Flame 3D cannot be compiled.
class Island3DViewport extends StatelessWidget {
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
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onLoadFailed?.call());
    return const SizedBox.shrink();
  }
}
