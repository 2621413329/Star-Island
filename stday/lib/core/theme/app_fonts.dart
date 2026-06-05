import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 统一中文界面字体，避免 Windows 上 Roboto 缺字导致同一段文字混用多种字体（粗细不一）。
String? appFontFamily() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
      return 'Microsoft YaHei UI';
    case TargetPlatform.macOS:
    case TargetPlatform.iOS:
      return 'PingFang SC';
    case TargetPlatform.linux:
      return 'Noto Sans CJK SC';
    case TargetPlatform.android:
      return null;
    default:
      return null;
  }
}

const List<String> appFontFamilyFallback = [
  'Microsoft YaHei UI',
  'Microsoft YaHei',
  'PingFang SC',
  'Noto Sans CJK SC',
  'sans-serif',
];

TextStyle appTextStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: appFontFamily(),
    fontFamilyFallback: appFontFamilyFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
