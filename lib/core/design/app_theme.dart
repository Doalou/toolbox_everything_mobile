import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';

/// Thème éditorial partagé avec Toolbox Everything Web, adapté aux contrôles
/// et conventions de navigation natives Flutter.
ThemeData buildEditorialTheme({
  required ColorScheme colorScheme,
  required Brightness brightness,
  bool amoled = false,
}) {
  final isDark = brightness == Brightness.dark;
  final useAmoled = isDark && amoled;
  final paper = useAmoled
      ? Colors.black
      : isDark
      ? EditorialPalette.paperDark
      : EditorialPalette.paperLight;
  final surface = isDark
      ? EditorialPalette.surfaceDark
      : EditorialPalette.surfaceLight;
  final line = isDark ? EditorialPalette.lineDark : EditorialPalette.lineLight;
  final lineStrong = isDark
      ? EditorialPalette.lineStrongDark
      : EditorialPalette.lineStrongLight;
  final editorialScheme = colorScheme.copyWith(
    surface: useAmoled ? Colors.black : surface,
    onSurface: isDark ? EditorialPalette.inkDark : EditorialPalette.inkLight,
    onSurfaceVariant: isDark
        ? EditorialPalette.mutedDark
        : EditorialPalette.mutedLight,
    surfaceContainerLowest: paper,
    surfaceContainerLow: useAmoled
        ? const Color(0xFF08090B)
        : isDark
        ? EditorialPalette.surfaceSunkenDark
        : EditorialPalette.surfaceSunkenLight,
    surfaceContainer: isDark
        ? EditorialPalette.surfaceAltDark
        : EditorialPalette.surfaceAltLight,
    surfaceContainerHigh: isDark
        ? EditorialPalette.surfaceAltDark
        : EditorialPalette.surfaceAltLight,
    surfaceContainerHighest: line,
    outline: lineStrong,
    outlineVariant: line,
    error: isDark ? EditorialPalette.errorDark : EditorialPalette.errorLight,
  );
  final textTheme = _editorialTextTheme(editorialScheme);
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(EditorialTokens.radiusMd),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: editorialScheme,
    scaffoldBackgroundColor: paper,
    canvasColor: paper,
    fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica', 'Arial'],
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: editorialScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w600,
      ),
      shape: Border(bottom: BorderSide(color: line)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      color: editorialScheme.surface,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusLg),
        side: BorderSide(color: lineStrong),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: controlShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        shape: controlShape,
        side: BorderSide(color: lineStrong),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: controlShape,
        side: BorderSide(color: lineStrong),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: controlShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 1,
      focusElevation: 1,
      hoverElevation: 1,
      highlightElevation: 1,
      shape: controlShape,
      backgroundColor: editorialScheme.primary,
      foregroundColor: editorialScheme.onPrimary,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        shape: controlShape,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        shape: WidgetStatePropertyAll(controlShape),
        side: WidgetStatePropertyAll(BorderSide(color: lineStrong)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: editorialScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusMd),
        borderSide: BorderSide(color: lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusMd),
        borderSide: BorderSide(color: lineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusMd),
        borderSide: BorderSide(color: editorialScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusMd),
        borderSide: BorderSide(color: editorialScheme.error),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(editorialScheme.surface),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStatePropertyAll(BorderSide(color: lineStrong)),
      shape: WidgetStatePropertyAll(controlShape),
    ),
    dialogTheme: DialogThemeData(
      elevation: 2,
      backgroundColor: editorialScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusXl),
        side: BorderSide(color: lineStrong),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 0,
      modalElevation: 2,
      backgroundColor: editorialScheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: ExpressiveShapes.bottomSheet,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 1,
      shape: controlShape,
      backgroundColor: editorialScheme.inverseSurface,
      contentTextStyle: TextStyle(color: editorialScheme.onInverseSurface),
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: 48,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: controlShape,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusSm),
      ),
      side: BorderSide(color: lineStrong),
      backgroundColor: editorialScheme.surfaceContainerLow,
      selectedColor: editorialScheme.primary.withValues(alpha: 0.12),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 20),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: editorialScheme.primary,
      linearTrackColor: line,
      linearMinHeight: 5,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: editorialScheme.primary,
      inactiveTrackColor: line,
      thumbColor: editorialScheme.primary,
      trackHeight: 5,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Nom historique conservé pour la compatibilité des appels internes.
ThemeData buildExpressiveTheme({
  required ColorScheme colorScheme,
  required Brightness brightness,
  bool amoled = false,
}) => buildEditorialTheme(
  colorScheme: colorScheme,
  brightness: brightness,
  amoled: amoled,
);

TextTheme _editorialTextTheme(ColorScheme scheme) {
  final ink = scheme.onSurface;
  TextStyle display(double size, double height) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: ink,
    letterSpacing: -0.7,
    height: height,
  );

  return TextTheme(
    displayLarge: display(48, 0.96),
    displayMedium: display(38, 1.0),
    displaySmall: display(30, 1.05),
    headlineLarge: display(28, 1.08),
    headlineMedium: display(24, 1.12),
    headlineSmall: display(21, 1.15),
    titleLarge: display(19, 1.2),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.3,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.3,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: ink, height: 1.55),
    bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
    bodySmall: TextStyle(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: ink,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontFamily: 'monospace',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.8,
    ),
  );
}
