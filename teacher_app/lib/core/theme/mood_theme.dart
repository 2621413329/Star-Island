import 'package:flutter/material.dart';

import 'app_fonts.dart';

class MoodPalette {
  const MoodPalette({
    required this.gradientStart,
    required this.gradientEnd,
    required this.primary,
    required this.primaryContainer,
    required this.card,
    required this.accent,
    required this.glow,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color primary;
  final Color primaryContainer;
  final Color card;
  final Color accent;
  final Color glow;
}

const defaultPalette = MoodPalette(
  gradientStart: Color(0xFFFFF4E8),
  gradientEnd: Color(0xFFFFE7D1),
  primary: Color(0xFFE8A87C),
  primaryContainer: Color(0xFFFFF0E6),
  card: Color(0xFFFFFBF7),
  accent: Color(0xFFD4A574),
  glow: Color(0xFFFFE0C2),
);

ThemeData buildAppTheme(MoodPalette palette) {
  const onSurface = Color(0xFF3D3229);
  const onSurfaceVariant = Color(0xFF8C7B6B);
  return ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily(),
    fontFamilyFallback: appFontFamilyFallback,
    colorScheme: ColorScheme.light(
      primary: palette.primary,
      secondary: palette.accent,
      surface: palette.card,
      onPrimary: Colors.white,
      onSurface: onSurface,
    ),
    scaffoldBackgroundColor: palette.gradientStart,
    textTheme: TextTheme(
      headlineSmall: appTextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      titleMedium: appTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      bodyLarge: appTextStyle(fontSize: 16, color: onSurface, height: 1.5),
      bodyMedium: appTextStyle(fontSize: 14, color: onSurfaceVariant),
      labelLarge: appTextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurfaceVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: appTextStyle(fontSize: 14, color: onSurfaceVariant),
      hintStyle: appTextStyle(fontSize: 14, color: onSurfaceVariant),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: appTextStyle(fontSize: 16, color: onSurface),
    ),
  );
}
