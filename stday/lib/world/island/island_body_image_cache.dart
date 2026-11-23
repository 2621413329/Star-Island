import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../engine/world_state.dart';
import 'island_body_ready_scope.dart';
import 'island_render_key.dart';
import 'island_renderer.dart';
import 'painted_island_asset.dart';
import 'story_island_art.dart';

/// 按 [IslandRenderKey] 把岛体收成位图。屏幕上的岛体直接复用分键 Picture，
/// 第一帧就显示，相同外观不重复栅格化。
class IslandBodyImageCache {
  IslandBodyImageCache._();

  static const maxEntries = 8;
  static const _maxEdge = 1440;

  /// 紧凑岛体的草面、石缘和投影会画出逻辑框。位图按这个比例留边，再居中贴回原位。
  static const horizontalOverflow = 0.22;
  static const verticalOverflow = 0.16;

  static final Map<String, _CachedImage> _images = {};
  static final Map<String, IslandBodyRasterJob> _queue = {};
  static final Map<String, List<void Function(ui.Image? image)>> _waiters = {};
  static bool _scheduled = false;

  static int rasterCount = 0;
  static int hitCount = 0;
  static int evictionCount = 0;

  static ui.Image? peek(String imageKey) {
    final existing = _images.remove(imageKey);
    if (existing == null) return null;
    _images[imageKey] = existing;
    hitCount++;
    return existing.image;
  }

  /// 界面开始持有这张图。仍被持有的图不会被淘汰。
  static void retain(String imageKey) {
    final existing = _images[imageKey];
    if (existing == null) return;
    existing.users++;
  }

  /// 界面不再持有这张图。无人持有且超出容量时才释放像素。
  static void release(String imageKey) {
    final existing = _images[imageKey];
    if (existing == null) return;
    existing.users = math.max(0, existing.users - 1);
    _evictUnused();
  }

  static void request(
    IslandBodyImageRequest request,
    void Function(ui.Image? image) onReady,
  ) {
    final job = request.job;
    final cached = peek(job.imageKey);
    if (cached != null) {
      onReady(cached);
      return;
    }
    _waiters.putIfAbsent(job.imageKey, () => []).add(onReady);
    _queue[job.imageKey] = job;
    _schedule();
  }

  /// 测试或已确认不在 build/paint 阶段时，立即生成并写入缓存。
  static ui.Image rasterSync(IslandBodyImageRequest request) {
    final job = request.job;
    final cached = peek(job.imageKey);
    if (cached != null) return cached;
    return _raster(job);
  }

  static void debugReset() {
    for (final image in _images.values) {
      image.image.dispose();
    }
    _images.clear();
    _queue.clear();
    _waiters.clear();
    _scheduled = false;
    rasterCount = 0;
    hitCount = 0;
    evictionCount = 0;
  }

  static void _schedule() {
    if (_scheduled || _queue.isEmpty) return;
    _scheduled = true;
    // 首页常有循环动画。idle 任务会一直等动画停，岛体就出不来。
    // 用动画优先级让出图插在帧间，一次只画一座，避免和首帧抢同一段时间。
    SchedulerBinding.instance.scheduleTask<void>(() {
      _scheduled = false;
      if (_queue.isEmpty) return;
      final key = _queue.keys.first;
      final job = _queue.remove(key);
      if (job != null) {
        _rasterAsync(job);
      }
    }, Priority.animation);
  }

  static Future<void> _rasterAsync(IslandBodyRasterJob job) async {
    final cached = peek(job.imageKey);
    if (cached != null) {
      _deliver(job.imageKey, cached);
    } else {
      await PaintedIslandAsset.ensureLoaded();
      final plateKey = job.island.plateKey;
      if (plateKey != null && plateKey.isNotEmpty) {
        await StoryIslandArt.ensure(plateKey);
      }
      final picture = _record(job);
      try {
        final image = await picture.toImage(job.pixelWidth, job.pixelHeight);
        picture.dispose();
        _deliver(job.imageKey, _remember(job.imageKey, image));
      } catch (_) {
        picture.dispose();
        _fail(job.imageKey);
      }
    }
    if (_queue.isNotEmpty) _schedule();
  }

  static ui.Image _raster(IslandBodyRasterJob job) {
    final cached = peek(job.imageKey);
    if (cached != null) return cached;
    final picture = _record(job);
    final image = picture.toImageSync(job.pixelWidth, job.pixelHeight);
    picture.dispose();
    return _remember(job.imageKey, image);
  }

  static ui.Picture _record(IslandBodyRasterJob job) {
    final renderer = IslandRenderer(compact: job.compact);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(job.pixelScale)
      ..translate(job.padX, job.padY);
    renderer.render(canvas, job.logicalSize, job.island, job.environment);
    renderer.dispose();
    return recorder.endRecording();
  }

  static ui.Image _remember(String key, ui.Image image) {
    final previous = _images.remove(key);
    if (previous != null) {
      image.dispose();
      _images[key] = previous;
      return previous.image;
    }
    rasterCount++;
    _images[key] = _CachedImage(image);
    _evictUnused();
    return image;
  }

  static void _deliver(String key, ui.Image image) {
    final waiters = _waiters.remove(key);
    if (waiters == null) return;
    for (final waiter in waiters) {
      waiter(image);
    }
  }

  static void _fail(String key) {
    final waiters = _waiters.remove(key);
    if (waiters == null) return;
    for (final waiter in waiters) {
      waiter(null);
    }
  }

  static void _evictUnused() {
    while (_images.length > maxEntries) {
      String? oldestUnused;
      for (final entry in _images.entries) {
        if (entry.value.users == 0) {
          oldestUnused = entry.key;
          break;
        }
      }
      if (oldestUnused == null) return;
      _images.remove(oldestUnused)?.image.dispose();
      evictionCount++;
    }
  }
}

class _CachedImage {
  _CachedImage(this.image);

  final ui.Image image;
  int users = 0;
}

class IslandBodyRasterJob {
  IslandBodyRasterJob({
    required this.imageKey,
    required this.logicalSize,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.pixelScale,
    required this.padX,
    required this.padY,
    required this.island,
    required this.environment,
    required this.compact,
  });

  final String imageKey;
  final Size logicalSize;
  final int pixelWidth;
  final int pixelHeight;
  final double pixelScale;
  final double padX;
  final double padY;
  final IslandState island;
  final MoodEnvironmentState environment;
  final bool compact;
}

/// 按显示尺寸和设备像素比描述一次岛体位图生成。
class IslandBodyImageRequest {
  const IslandBodyImageRequest({
    required this.island,
    required this.environment,
    required this.logicalSize,
    required this.devicePixelRatio,
    this.compact = true,
  });

  final IslandState island;
  final MoodEnvironmentState environment;
  final Size logicalSize;
  final double devicePixelRatio;
  final bool compact;

  IslandBodyRasterJob get job {
    final padX = logicalSize.width * IslandBodyImageCache.horizontalOverflow;
    final padY = logicalSize.height * IslandBodyImageCache.verticalOverflow;
    final framedWidth = logicalSize.width + padX * 2;
    final framedHeight = logicalSize.height + padY * 2;
    final longest = math.max(framedWidth, framedHeight);
    final scale = longest <= 0
        ? 1.0
        : math.min(
            devicePixelRatio.clamp(1.0, 3.0),
            IslandBodyImageCache._maxEdge / longest,
          );
    final pixelWidth = math.max(1, (framedWidth * scale).round());
    final pixelHeight = math.max(1, (framedHeight * scale).round());
    final key = IslandRenderKey.from(
      compact: compact,
      size: logicalSize,
      island: island,
      environment: environment,
    ).imageKey(pixelWidth: pixelWidth, pixelHeight: pixelHeight);
    return IslandBodyRasterJob(
      imageKey: key,
      logicalSize: logicalSize,
      pixelWidth: pixelWidth,
      pixelHeight: pixelHeight,
      pixelScale: scale,
      padX: padX,
      padY: padY,
      island: island,
      environment: environment,
      compact: compact,
    );
  }
}

/// 只贴已经生成好的岛体位图。缺图时排队生成，不在切页这一帧重放矢量。
class IslandBodyView extends StatefulWidget {
  const IslandBodyView({
    super.key,
    required this.island,
    required this.environment,
    required this.width,
    required this.height,
    this.compact = true,
  });

  final IslandState island;
  final MoodEnvironmentState environment;
  final double width;
  final double height;
  final bool compact;

  @override
  State<IslandBodyView> createState() => _IslandBodyViewState();
}

class _IslandBodyViewState extends State<IslandBodyView>
    implements IslandBodyReadyClient {
  ui.Image? _image;
  String? _key;
  String? _pendingKey;
  int _requestId = 0;
  bool _failed = false;
  IslandBodyReadyBoard? _board;

  @override
  bool get imageReady => _image != null || _failed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = IslandBodyReadyScope.maybeOf(context);
    if (!identical(next, _board)) {
      _board?.detach(this);
      _board = next;
      _board?.attach(this);
    }
    _resolve();
  }

  @override
  void didUpdateWidget(IslandBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolve();
  }

  @override
  void dispose() {
    _board?.detach(this);
    _board = null;
    final key = _key;
    if (key != null) IslandBodyImageCache.release(key);
    _key = null;
    super.dispose();
  }

  void _resolve() {
    if (widget.width < 1 || widget.height < 1) return;
    final request = IslandBodyImageRequest(
      island: widget.island,
      environment: widget.environment,
      logicalSize: Size(widget.width, widget.height),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      compact: widget.compact,
    );
    final imageKey = request.job.imageKey;
    if (imageKey == _key && _image != null) return;
    final cached = IslandBodyImageCache.peek(imageKey);
    if (cached != null) {
      _pendingKey = null;
      _failed = false;
      _hold(imageKey, cached);
      _board?.ping();
      return;
    }
    if (imageKey == _pendingKey) return;
    _pendingKey = imageKey;
    _failed = false;
    final requestId = ++_requestId;
    IslandBodyImageCache.request(request, (image) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _pendingKey = null;
        if (image == null) {
          _failed = true;
        } else {
          _failed = false;
          _hold(imageKey, image);
        }
      });
      _board?.ping();
    });
  }

  void _hold(String imageKey, ui.Image image) {
    if (_key == imageKey && identical(_image, image)) return;
    final previous = _key;
    if (previous != null && previous != imageKey) {
      IslandBodyImageCache.release(previous);
    }
    final alreadyHeld = _key == imageKey;
    _key = imageKey;
    _image = image;
    if (!alreadyHeld) IslandBodyImageCache.retain(imageKey);
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final padX = widget.width * IslandBodyImageCache.horizontalOverflow;
    final padY = widget.height * IslandBodyImageCache.verticalOverflow;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: image == null
          ? null
          : OverflowBox(
              alignment: Alignment.center,
              minWidth: 0,
              minHeight: 0,
              maxWidth: widget.width + padX * 2,
              maxHeight: widget.height + padY * 2,
              child: RawImage(
                image: image,
                width: widget.width + padX * 2,
                height: widget.height + padY * 2,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
    );
  }
}
