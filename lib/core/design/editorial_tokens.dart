import 'package:material_ui/material_ui.dart';
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
  static const mutedLight = Color(0xFF5A5C6A);
  static const lineLight = Color(0xFFE2DFEC);
  static const lineStrongLight = Color(0xFFD0CCE0);

  static const paperDark = Color(0xFF0F1016);
  static const surfaceDark = Color(0xFF181922);
  static const surfaceAltDark = Color(0xFF212330);
  static const surfaceSunkenDark = Color(0xFF13141C);
  static const inkDark = Color(0xFFF3F2F8);
  static const mutedDark = Color(0xFFA0A2B2);
  static const lineDark = Color(0xFF2B2D3C);
  static const lineStrongDark = Color(0xFF3B3E52);

  static const accentLight = ExpressivePalette.violetVibrant;
  static const accentDark = Color(0xFF94A8FF);
  static const brandPinkDark = Color(0xFFF493CB);
  static const errorLight = Color(0xFFD1442F);
  static const errorDark = Color(0xFFF48975);

  static ColorScheme expressiveSeedScheme(Color seed, Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.expressive,
      );

  static ColorScheme scheme(Brightness brightness, {Color? accent}) {
    final isDark = brightness == Brightness.dark;
    final seed = accent ?? accentLight;
    final generated = expressiveSeedScheme(seed, brightness);

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

  static const duration = Duration(milliseconds: 220);
}
