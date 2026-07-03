/// 主岛建筑纵深透视：Y 越小（越靠后）缩放越小。
class BuildingDepthScale {
  BuildingDepthScale._();

  static const _backY = 0.22;
  static const _frontY = 0.68;
  static const _minScale = 0.85;
  static const _maxScale = 1.0;

  static double forAnchorDy(double dy) {
    final t = ((dy - _backY) / (_frontY - _backY)).clamp(0.0, 1.0);
    return _minScale + t * (_maxScale - _minScale);
  }
}
