import 'package:flutter/material.dart';

import '../../../data/models/polaroid_models.dart';
import 'polaroid_card.dart';
import 'polaroid_skin.dart';

/// 种入之后的显影。不等背面总结，点一下就收好。
class PolaroidShootOverlay extends StatefulWidget {
  const PolaroidShootOverlay({
    super.key,
    required this.card,
    required this.onDone,
    this.scene = PolaroidScene.fallback,
  });

  final PolaroidCardModel card;
  final VoidCallback onDone;
  final PolaroidScene scene;

  @override
  State<PolaroidShootOverlay> createState() => _PolaroidShootOverlayState();
}

class _PolaroidShootOverlayState extends State<PolaroidShootOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    if (_controller.isCompleted) {
      _finish();
      return;
    }
    _controller.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: ColoredBox(
        color: const Color(0x661C1916),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_controller.value);
            return Center(
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: PolaroidFace(
                      card: widget.card,
                      showBack: false,
                      scene: widget.scene,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
