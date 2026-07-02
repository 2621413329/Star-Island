import 'package:flutter/material.dart';

/// 首页 Dreamy Island 局部色板（不替换全局 moodPalette）。
abstract final class HomeTheme {
  static const primary = Color(0xFF5EA9FF);
  static const background = Color(0xFFF5F9FF);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7B8A9A);
  static const oceanTop = Color(0xFFB8DCFF);
  static const oceanBottom = Color(0xFF8EC5FF);
  static const cardRadius = 28.0;
  static const cardShadow = BoxShadow(
    color: Color(0x145EA9FF),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}
