import 'package:flutter/foundation.dart';

/// 对照实验开关。每次只开一个，改完后热重启岛屿页。
///
/// A [freezeMotion]：运动时间停在 0，动态层只画一帧。
/// B [forceFullPaint]：关掉分通道，回到 Flame 整帧绘制。
/// C [pauseDynamicPasses]：保留分通道，但不再 update，也不再重绘动态层。
/// 旧相机行为 [rebakeOnCamera]：缩放、旋转时重新录制静态 Picture。
class WorldRenderControls {
  static bool freezeMotion = false;
  static bool forceFullPaint = false;
  static bool pauseDynamicPasses = false;
  static bool rebakeOnCamera = false;

  /// 装饰图补刷次数。测试里设为 0，避免定时器改写计数。
  static int catchUpTicks = 6;
}

/// 诊断模式才打开。Profile 基准测试保持关闭，避免计数和 [debugPrint] 进帧时间。
///
/// 打开方式：`WorldRenderProbe.enabled = true`。汇总大约每秒一行，带平均值、P95 和最大值。
class WorldRenderProbe {
  static bool enabled = false;
  static bool logSummaries = false;

  static int tickers = 0;
  static int updates = 0;
  static int updateMicros = 0;
  static int pictureRecorders = 0;
  static int outerPictureRecorders = 0;
  static int invalidations = 0;
  static int islandInvalidations = 0;
  static int cameraTransforms = 0;
  static int suppressedFullPaints = 0;
  static int slotVisits = 0;
  static int componentsPainted = 0;

  static final Map<String, int> renders = {};
  static final Map<String, int> renderMicros = {};
  static final List<int> _updateSamples = [];
  static final Map<String, List<int>> _renderSamples = {};

  static final Stopwatch _window = Stopwatch()..start();

  static void reset() {
    tickers = 0;
    updates = 0;
    updateMicros = 0;
    pictureRecorders = 0;
    outerPictureRecorders = 0;
    invalidations = 0;
    islandInvalidations = 0;
    cameraTransforms = 0;
    suppressedFullPaints = 0;
    slotVisits = 0;
    componentsPainted = 0;
    renders.clear();
    renderMicros.clear();
    _updateSamples.clear();
    _renderSamples.clear();
    _window
      ..reset()
      ..start();
  }

  static void noteTicker() {
    if (!enabled) return;
    tickers++;
    _maybeFlush();
  }

  static void noteUpdate(int micros) {
    if (!enabled) return;
    updates++;
    updateMicros += micros;
    _updateSamples.add(micros);
    _maybeFlush();
  }

  static void noteRender(String pass, int micros) {
    if (!enabled) return;
    renders[pass] = (renders[pass] ?? 0) + 1;
    renderMicros[pass] = (renderMicros[pass] ?? 0) + micros;
    _renderSamples.putIfAbsent(pass, () => []).add(micros);
    _maybeFlush();
  }

  static void notePictureRecorder({bool outer = false}) {
    if (!enabled) return;
    pictureRecorders++;
    if (outer) outerPictureRecorders++;
    _maybeFlush();
  }

  static void noteInvalidation({required bool islandOnly}) {
    if (!enabled) return;
    if (islandOnly) {
      islandInvalidations++;
    } else {
      invalidations++;
    }
    _maybeFlush();
  }

  static void noteCameraTransform() {
    if (!enabled) return;
    cameraTransforms++;
    _maybeFlush();
  }

  static void noteSuppressedFullPaint() {
    if (!enabled) return;
    suppressedFullPaints++;
    _maybeFlush();
  }

  static void noteSlotVisit({required bool painted}) {
    if (!enabled) return;
    slotVisits++;
    if (painted) componentsPainted++;
  }

  static void _maybeFlush() {
    if (!logSummaries || _window.elapsedMilliseconds < 1000) return;
    final frames = tickers == 0 ? updates : tickers;
    debugPrint(
      'WorldRender ${frames}f '
      'update ${updates}x ${_sampleText(_updateSamples)} '
      'render ${_passText('backdrop')} '
      '${_passText('backMotion')} '
      '${_passText('island')} '
      '${_passText('frontMotion')} '
      '${_passText('full')} '
      'recorders $pictureRecorders outer $outerPictureRecorders '
      'invalidate $invalidations island $islandInvalidations '
      'camera $cameraTransforms suppressed $suppressedFullPaints '
      'slots $slotVisits painted $componentsPainted',
    );
    reset();
  }

  static String _passText(String pass) {
    final count = renders[pass] ?? 0;
    return '$pass ${count}x ${_sampleText(_renderSamples[pass] ?? const [])}';
  }

  static String _sampleText(List<int> micros) {
    if (micros.isEmpty) return 'avg 0.00 p95 0.00 max 0.00';
    return 'avg ${_ms(_mean(micros))} '
        'p95 ${_ms(percentileUpper(micros, 0.95))} '
        'max ${_ms(micros.reduce((a, b) => a > b ? a : b))}';
  }

  static double _mean(List<int> micros) {
    var sum = 0;
    for (final sample in micros) {
      sum += sample;
    }
    return sum / micros.length;
  }

  static String _ms(num micros) => (micros / 1000).toStringAsFixed(2);

  /// 向上取整的分位。空列表返回 0。[samples] 不必预先排序。
  static int percentileUpper(List<int> samples, double p) {
    if (samples.isEmpty) return 0;
    final sorted = [...samples]..sort();
    final index = ((sorted.length - 1) * p).ceil().clamp(0, sorted.length - 1);
    return sorted[index];
  }
}
