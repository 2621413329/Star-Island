import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'world_board_camera.dart';
import 'world_paint_pass.dart';
import 'world_render_probe.dart';

/// 主岛详情：天空和岛体各留一张 Picture，和云、浪、小人画在同一层。
///
/// 静止贴图每帧只 replay。点击仍走原来的 [GameWidget]。
class SplitWorldView extends StatefulWidget {
  const SplitWorldView({super.key, required this.game});

  final FlameGame game;

  @override
  State<SplitWorldView> createState() => _SplitWorldViewState();
}

class _SplitWorldViewState extends State<SplitWorldView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final WorldPaintHost _host;
  Duration _lastElapsed = Duration.zero;
  final _backdrop = _RetainedHandle();
  final _island = _RetainedHandle();
  Timer? _catchUp;
  _WorldBoardBox? _board;
  bool _dynamicPrimed = false;

  @override
  void initState() {
    super.initState();
    _host = widget.game as WorldPaintHost;
    _host.suppressFullPaint = true;
    _host.addRetainedFrameListener(_onBackdropDirty);
    _host.addIslandFrameListener(_onIslandDirty);
    _host.addBoardTransformListener(_onBoardTransform);
    _ticker = createTicker(_onTick)..start();
    widget.game.ready().then((_) {
      if (!mounted) return;
      _onBackdropDirty();
      _onIslandDirty();
    });
    // 装饰图异步进入岛面。天空不随这些图变化，只补刷岛面。
    if (WorldRenderControls.catchUpTicks > 0) {
      _catchUp = Timer.periodic(const Duration(milliseconds: 350), (timer) {
        if (!mounted) return;
        _onIslandDirty();
        if (timer.tick >= WorldRenderControls.catchUpTicks) timer.cancel();
      });
    }
  }

  void _onBackdropDirty() {
    _backdrop.dirty = true;
    _board?.markNeedsPaint();
  }

  void _onIslandDirty() {
    _island.dirty = true;
    _board?.markNeedsPaint();
  }

  void _onBoardTransform() {
    _board?.markNeedsPaint();
  }

  void _onTick(Duration elapsed) {
    WorldRenderProbe.noteTicker();
    final dt = (elapsed - _lastElapsed).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    if (!widget.game.isLoaded) return;
    final pause = WorldRenderControls.pauseDynamicPasses;
    final freeze = WorldRenderControls.freezeMotion;
    if (!pause) {
      widget.game.update(freeze ? 0 : dt.clamp(0.0, 0.05));
    }
    final drawDynamic = (!pause && !freeze) || !_dynamicPrimed;
    if (!drawDynamic) return;
    _board?.markNeedsPaint();
    _dynamicPrimed = true;
  }

  @override
  void dispose() {
    _catchUp?.cancel();
    _ticker.dispose();
    _host.removeRetainedFrameListener(_onBackdropDirty);
    _host.removeIslandFrameListener(_onIslandDirty);
    _host.removeBoardTransformListener(_onBoardTransform);
    _host.suppressFullPaint = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Stack(
      fit: StackFit.expand,
      children: [
        _WorldBoardPaint(
          game: game,
          host: _host,
          backdrop: _backdrop,
          island: _island,
          onBox: (box) => _board = box,
        ),
        GameWidget(
          game: game,
          addRepaintBoundary: false,
        ),
      ],
    );
  }
}

class _RetainedHandle {
  bool dirty = true;
  Picture? picture;
}

class _WorldBoardPaint extends LeafRenderObjectWidget {
  const _WorldBoardPaint({
    required this.game,
    required this.host,
    required this.backdrop,
    required this.island,
    required this.onBox,
  });

  final FlameGame game;
  final WorldPaintHost host;
  final _RetainedHandle backdrop;
  final _RetainedHandle island;
  final ValueChanged<_WorldBoardBox> onBox;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final box = _WorldBoardBox(
      game: game,
      host: host,
      backdrop: backdrop,
      island: island,
    );
    onBox(box);
    return box;
  }

  @override
  void updateRenderObject(BuildContext context, _WorldBoardBox renderObject) {
    renderObject
      ..game = game
      ..host = host
      ..backdrop = backdrop
      ..island = island;
    onBox(renderObject);
  }
}

class _WorldBoardBox extends RenderBox {
  _WorldBoardBox({
    required this.game,
    required this.host,
    required this.backdrop,
    required this.island,
  });

  FlameGame game;
  WorldPaintHost host;
  _RetainedHandle backdrop;
  _RetainedHandle island;

  @override
  void dispose() {
    backdrop.picture?.dispose();
    island.picture?.dispose();
    backdrop.picture = null;
    island.picture = null;
    super.dispose();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _drawCached(canvas, backdrop, WorldPaintPass.backdrop);
    _drawLive(canvas, WorldPaintPass.backMotion);
    _drawCached(canvas, island, WorldPaintPass.island);
    _drawLive(canvas, WorldPaintPass.frontMotion);
    canvas.restore();
  }

  void _drawCached(Canvas canvas, _RetainedHandle handle, WorldPaintPass pass) {
    if (handle.dirty || handle.picture == null) {
      WorldRenderProbe.notePictureRecorder(outer: true);
      final recorder = PictureRecorder();
      final recording = Canvas(recorder);
      final previous = host.paintPass;
      host.paintPass = pass;
      if (!WorldRenderControls.rebakeOnCamera) {
        applyInverseBoardCamera(
          recording,
          size,
          host.boardZoom,
          host.boardRotation,
        );
      }
      game.render(recording);
      host.paintPass = previous;
      handle.picture?.dispose();
      handle.picture = recorder.endRecording();
      handle.dirty = false;
    }
    canvas.save();
    if (!WorldRenderControls.rebakeOnCamera) {
      applyBoardCamera(canvas, size, host.boardZoom, host.boardRotation);
    }
    canvas.drawPicture(handle.picture!);
    canvas.restore();
  }

  void _drawLive(Canvas canvas, WorldPaintPass pass) {
    if (!game.isLoaded) return;
    final previous = host.paintPass;
    host.paintPass = pass;
    game.render(canvas);
    host.paintPass = previous;
  }
}
