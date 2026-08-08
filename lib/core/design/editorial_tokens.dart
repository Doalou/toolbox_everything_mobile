import 'package:flutter/material.dart';

/// Couleurs issues du design éditorial de Toolbox Everything Web.
class EditorialPalette {
  EditorialPalette._();

  static const paperLight = Color(0xFFF3F3F0);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceAltLight = Color(0xFFECEAE4);
  static const surfaceSunkenLight = Color(0xFFF6F5F1);
  static const inkLight = Color(0xFF17181C);
  static const inkSoftLight = Color(0xFF33353C);
  static const mutedLight = Color(0xFF5C6068);
  static const lineLight = Color(0xFFE4E3DC);
  static const lineStrongLight = Color(0xFFD3D2C8);

  static const paperDark = Color(0xFF0E0F13);
  static const surfaceDark = Color(0xFF16181D);
  static const surfaceAltDark = Color(0xFF1E2027);
  static const surfaceSunkenDark = Color(0xFF121319);
  static const inkDark = Color(0xFFF2F1EC);
  static const inkSoftDark = Color(0xFFD6D5CF);
  static const mutedDark = Color(0xFFA4A8B0);
  static const lineDark = Color(0xFF2A2C34);
  static const lineStrongDark = Color(0xFF3A3D47);

  static const accentLight = Color(0xFF2544D8);
  static const accentDark = Color(0xFF7D97FF);
  static const brandBlueLight = Color(0xFF5C6FF4);
  static const brandBlueDark = Color(0xFF8FA1FF);
  static const brandPinkLight = Color(0xFFCF4B99);
  static const brandPinkDark = Color(0xFFF08DCC);
  static const brandVioletLight = Color(0xFF905FCB);
  static const brandVioletDark = Color(0xFFBB98E8);
  static const successLight = Color(0xFF0F9D70);
  static const successDark = Color(0xFF4FD0A3);
  static const warningLight = Color(0xFFC67C11);
  static const warningDark = Color(0xFFE6B45C);
  static const errorLight = Color(0xFFD1442F);
  static const errorDark = Color(0xFFF0836E);

  static ColorScheme scheme(Brightness brightness, {Color? accent}) {
    final isDark = brightness == Brightness.dark;
    final primary = accent ?? (isDark ? accentDark : accentLight);
    final generated = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final onPrimary =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0E0F13);

    return generated.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      surface: isDark ? surfaceDark : surfaceLight,
      onSurface: isDark ? inkDark : inkLight,
      onSurfaceVariant: isDark ? mutedDark : mutedLight,
      surfaceContainerLowest: isDark ? paperDark : paperLight,
      surfaceContainerLow: isDark ? surfaceSunkenDark : surfaceSunkenLight,
      surfaceContainer: isDark ? surfaceAltDark : surfaceAltLight,
      surfaceContainerHigh: isDark ? surfaceAltDark : surfaceAltLight,
      surfaceContainerHighest: isDark ? lineDark : lineLight,
      outline: isDark ? lineStrongDark : lineStrongLight,
      outlineVariant: isDark ? lineDark : lineLight,
      error: isDark ? errorDark : errorLight,
    );
  }
}

class EditorialTokens {
  EditorialTokens._();

  static const radiusXs = 5.0;
  static const radiusSm = 7.0;
  static const radiusMd = 10.0;
  static const radiusLg = 14.0;
  static const radiusXl = 18.0;

  static const durationFast = Duration(milliseconds: 120);
  static const duration = Duration(milliseconds: 180);
}
