import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'world_board_camera.dart';
import 'world_paint_pass.dart';
import 'world_render_probe.dart';

/// 主岛详情：天空、海面、云和岛体画在同一层，由外层取景器一起缩放。
///
/// 静止贴图每帧只 replay。点击在取景器里换算回缩放前的坐标，和贴图用同一套。
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
  _RenderBoardZoom? _zoom;
  bool _dynamicPrimed = false;
  final Map<int, Offset> _pointerDown = {};
  final Map<int, Offset> _pointers = {};
  bool _pinch = false;
  bool _blockPan = false;
  int? _pinchA;
  int? _pinchB;
  double? _span0;
  double _zoom0 = 1;
  Offset? _worldFocal;

  static const _minZoom = 0.68;
  static const _maxZoom = 3.0;

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
    final box = _zoom;
    if (box == null) return;
    box
      ..zoom = _host.boardZoom == 0 ? 1.0 : _host.boardZoom
      ..pan = _host.boardPan;
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
    final zoom = _host.boardZoom == 0 ? 1.0 : _host.boardZoom;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFD6ECFA)),
        _BoardZoom(
          zoom: zoom,
          pan: _host.boardPan,
          onBox: (box) => _zoom = box,
          child: Stack(
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
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown[event.pointer] = event.localPosition;
    _pointers[event.pointer] = event.localPosition;
    if (_pinchA == null && _pointers.length >= 2) _beginPinch();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (_pinchA != null &&
        _pinchB != null &&
        _pointers.containsKey(_pinchA) &&
        _pointers.containsKey(_pinchB) &&
        _span0 != null &&
        _worldFocal != null) {
      final a = _pointers[_pinchA]!;
      final b = _pointers[_pinchB]!;
      final span = math.max(1.0, (a - b).distance);
      final zoom = (_zoom0 * span / _span0!).clamp(_minZoom, _maxZoom);
      final size = _viewportSize();
      _host.setBoardTransform(
        zoom: zoom,
        pan: _limitPan(
          panForAnchoredZoom(
            worldFocal: _worldFocal!,
            screenFocal: (a + b) / 2,
            size: size,
            zoom: zoom,
          ),
          zoom,
          size,
        ),
      );
      return;
    }
    if (_blockPan || _pointers.length != 1) return;
    final zoom = _currentZoom;
    if ((zoom - 1).abs() <= 0.04) return;
    final size = _viewportSize();
    _host.setBoardTransform(
      zoom: zoom,
      pan: _limitPan(_host.boardPan + event.delta, zoom, size),
    );
  }

  void _beginPinch() {
    final ids = _pointers.keys.take(2).toList();
    _pinchA = ids[0];
    _pinchB = ids[1];
    final a = _pointers[_pinchA]!;
    final b = _pointers[_pinchB]!;
    _span0 = math.max(1.0, (a - b).distance);
    _zoom0 = _currentZoom;
    final size = _viewportSize();
    _worldFocal = mapInverseBoardCameraPoint(
      zoomedPoint: (a + b) / 2,
      size: size,
      zoom: _zoom0,
      rotation: 0,
      pan: _host.boardPan,
    );
    _pinch = true;
    _blockPan = true;
  }

  double get _currentZoom => _host.boardZoom == 0 ? 1 : _host.boardZoom;

  Size _viewportSize() {
    final box = _zoom;
    if (box != null && box.hasSize && !box.size.isEmpty) return box.size;
    return const Size(390, 844);
  }

  Offset _limitPan(Offset pan, double zoom, Size size) {
    final slackX = size.width * (zoom - 1).abs() / 2;
    final slackY = size.height * (zoom - 1).abs() / 2;
    return Offset(
      pan.dx.clamp(-slackX, slackX),
      pan.dy.clamp(-slackY, slackY),
    );
  }

  void _releasePinchPointers(int pointer) {
    if (pointer != _pinchA && pointer != _pinchB && _pointers.length >= 2) {
      return;
    }
    _pinchA = null;
    _pinchB = null;
    _span0 = null;
    _worldFocal = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDown.remove(event.pointer);
    _pointers.remove(event.pointer);
    _releasePinchPointers(event.pointer);
    if (_pointerDown.isEmpty) {
      _pinch = false;
      _blockPan = false;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final origin = _pointerDown.remove(event.pointer);
    _pointers.remove(event.pointer);
    _releasePinchPointers(event.pointer);
    final pinching = _pinch;
    if (_pointerDown.isEmpty) {
      _pinch = false;
      _blockPan = false;
    }
    if (origin == null || pinching) return;
    if ((event.localPosition - origin).distance > 18) return;
    final box = _zoom;
    if (box == null || !box.hasSize) return;
    final gameSize = widget.game.size;
    if (gameSize.x <= 0 || gameSize.y <= 0) return;
    final neutral = mapInverseBoardCameraPoint(
      zoomedPoint: event.localPosition,
      size: box.size,
      zoom: box.zoom,
      rotation: _host.boardRotation,
      pan: box.pan,
    );
    final sx = box.size.width <= 0 ? 1.0 : gameSize.x / box.size.width;
    final sy = box.size.height <= 0 ? 1.0 : gameSize.y / box.size.height;
    _host.handleScreenTap(Offset(neutral.dx * sx, neutral.dy * sy));
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
    host.withNeutralViewfinder(() {
      _ensurePicture(backdrop, WorldPaintPass.backdrop);
      canvas.drawPicture(backdrop.picture!);
      _drawLive(canvas, WorldPaintPass.backMotion);
      _ensurePicture(island, WorldPaintPass.island);
      canvas.drawPicture(island.picture!);
      _drawLive(canvas, WorldPaintPass.frontMotion);
    });
    canvas.restore();
  }

  /// 贴图按不缩放的画面录下。整幅画面由外层取景器一起缩放。
  void _ensurePicture(_RetainedHandle handle, WorldPaintPass pass) {
    if (!handle.dirty && handle.picture != null) return;
    WorldRenderProbe.notePictureRecorder(outer: true);
    final recorder = PictureRecorder();
    final recording = Canvas(recorder);
    final previous = host.paintPass;
    host.paintPass = pass;
    game.render(recording);
    host.paintPass = previous;
    handle.picture?.dispose();
    handle.picture = recorder.endRecording();
    handle.dirty = false;
  }

  void _drawLive(Canvas canvas, WorldPaintPass pass) {
    if (!game.isLoaded) return;
    final previous = host.paintPass;
    host.paintPass = pass;
    game.render(canvas);
    host.paintPass = previous;
  }
}

/// 把天空、海面、云和岛体绕画面中心一起缩放。点击在这里换回缩放前的坐标。
class _BoardZoom extends SingleChildRenderObjectWidget {
  const _BoardZoom({
    required this.zoom,
    required this.pan,
    required this.onBox,
    required super.child,
  });

  final double zoom;
  final Offset pan;
  final ValueChanged<_RenderBoardZoom> onBox;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final box = _RenderBoardZoom(zoom: zoom, pan: pan);
    onBox(box);
    return box;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderBoardZoom renderObject) {
    renderObject
      ..zoom = zoom
      ..pan = pan;
    onBox(renderObject);
  }
}

class _RenderBoardZoom extends RenderProxyBox {
  _RenderBoardZoom({required double zoom, required Offset pan})
      : _zoom = zoom,
        _pan = pan;

  double _zoom;
  Offset _pan;

  double get zoom => _zoom;
  Offset get pan => _pan;

  set zoom(double value) {
    if (_zoom == value) return;
    _zoom = value;
    markNeedsPaint();
  }

  set pan(Offset value) {
    if (_pan == value) return;
    _pan = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    applyBoardCamera(canvas, size, _zoom, 0, pan: _pan);
    canvas.translate(-offset.dx, -offset.dy);
    super.paint(context, offset);
    canvas.restore();
  }
}
