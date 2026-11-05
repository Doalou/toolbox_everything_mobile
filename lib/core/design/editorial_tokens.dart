import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';

/// Palette et jetons unifiés avec le système Material 3 Expressive.
/// Le nom [EditorialPalette] / [EditorialTokens] est conservé pour la
/// compatibilité avec l'ensemble des écrans et tests existants.
class EditorialPalette {
  EditorialPalette._();

  static const paperLight = Color(0xFFF6F5FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceAltLight = Color(0xFFEDEAF6);
  static const surfaceSunkenLight = Color(0xFFF2F0F9);
  static const inkLight = Color(0xFF16161E);
  static const inkSoftLight = Color(0xFF2E2F3A);
  static const mutedLight = Color(0xFF5A5C6A);
  static const lineLight = Color(0xFFE2DFEC);
  static const lineStrongLight = Color(0xFFD0CCE0);

  static const paperDark = Color(0xFF0F1016);
  static const surfaceDark = Color(0xFF181922);
  static const surfaceAltDark = Color(0xFF212330);
  static const surfaceSunkenDark = Color(0xFF13141C);
  static const inkDark = Color(0xFFF3F2F8);
  static const inkSoftDark = Color(0xFFD7D5E2);
  static const mutedDark = Color(0xFFA0A2B2);
  static const lineDark = Color(0xFF2B2D3C);
  static const lineStrongDark = Color(0xFF3B3E52);

  static const accentLight = ExpressivePalette.violetVibrant;
  static const accentDark = Color(0xFF94A8FF);
  static const brandBlueLight = Color(0xFF4F63F0);
  static const brandBlueDark = Color(0xFF94A8FF);
  static const brandPinkLight = Color(0xFFCF4B99);
  static const brandPinkDark = Color(0xFFF493CB);
  static const brandVioletLight = Color(0xFF8350C8);
  static const brandVioletDark = Color(0xFFC5A3F5);
  static const successLight = Color(0xFF0F9D70);
  static const successDark = Color(0xFF52D6A8);
  static const warningLight = Color(0xFFC67C11);
  static const warningDark = Color(0xFFF0B95E);
  static const errorLight = Color(0xFFD1442F);
  static const errorDark = Color(0xFFF48975);

  static ColorScheme scheme(Brightness brightness, {Color? accent}) {
    final isDark = brightness == Brightness.dark;
    final seed = accent ?? accentLight;
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    if (accent != null) {
      return generated;
    }

    final primary = isDark ? accentDark : accentLight;
    final onPrimary =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F1016);

    return generated.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      surface: isDark ? surfaceDark : surfaceLight,
      onSurface: isDark ? inkDark : inkLight,
      onSurfaceVariant: isDark ? mutedDark : mutedLight,
      surfaceContainerLowest: isDark ? paperDark : paperLight,
      surfaceContainerLow: isDark ? surfaceSunkenDark : surfaceSunkenLight,
      surfaceContainer: isDark ? surfaceAltDark : surfaceAltLight,
      surfaceContainerHigh: isDark
          ? const Color(0xFF282A3A)
          : const Color(0xFFE6E2F2),
      surfaceContainerHighest: isDark ? lineDark : lineLight,
      outline: isDark ? lineStrongDark : lineStrongLight,
      outlineVariant: isDark ? lineDark : lineLight,
      error: isDark ? errorDark : errorLight,
    );
  }
}

class EditorialTokens {
  EditorialTokens._();

  static const radiusXs = ExpressiveShapes.extraSmall;
  static const radiusSm = ExpressiveShapes.small;
  static const radiusMd = ExpressiveShapes.medium;
  static const radiusLg = ExpressiveShapes.large;
  static const radiusXl = ExpressiveShapes.largeIncreased;

  static const durationFast = Duration(milliseconds: 140);
  static const duration = Duration(milliseconds: 220);
}
