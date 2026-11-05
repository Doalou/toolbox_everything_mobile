import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';

/// Thème Material 3 Expressive (M3E) pour Toolbox Everything Mobile :
/// palettes tonales vibrantes, formes généreuses (pilules & squircles),
/// hiérarchie typographique expressive et support du mode Noir AMOLED.
ThemeData buildExpressiveTheme({
  required ColorScheme colorScheme,
  required Brightness brightness,
  bool amoled = false,
}) {
  final isDark = brightness == Brightness.dark;
  final useAmoled = isDark && amoled;

  final scaffoldBg = useAmoled
      ? Colors.black
      : colorScheme.surfaceContainerLowest;
  final cardSurface = useAmoled ? const Color(0xFF0A0B0F) : colorScheme.surface;
  final lowSurface = useAmoled
      ? const Color(0xFF111218)
      : colorScheme.surfaceContainerLow;
  final midSurface = useAmoled
      ? const Color(0xFF171922)
      : colorScheme.surfaceContainer;
  final highSurface = useAmoled
      ? const Color(0xFF1F222E)
      : colorScheme.surfaceContainerHigh;

  final expressiveScheme = colorScheme.copyWith(
    surface: cardSurface,
    surfaceContainerLowest: scaffoldBg,
    surfaceContainerLow: lowSurface,
    surfaceContainer: midSurface,
    surfaceContainerHigh: highSurface,
  );

  final textTheme = _expressiveTextTheme(expressiveScheme);
  final pillShape = const StadiumBorder();
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
  );
  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ExpressiveShapes.largeIncreased),
    side: BorderSide(
      color: expressiveScheme.outlineVariant.withValues(alpha: 0.55),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: expressiveScheme,
    scaffoldBackgroundColor: scaffoldBg,
    canvasColor: scaffoldBg,
    fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica', 'Arial'],
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      foregroundColor: expressiveScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      color: expressiveScheme.surface,
      margin: const EdgeInsets.all(8),
      shape: cardShape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: pillShape,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(56, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        backgroundColor: expressiveScheme.secondaryContainer,
        foregroundColor: expressiveScheme.onSecondaryContainer,
        shape: pillShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(56, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: pillShape,
        side: BorderSide(color: expressiveScheme.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: pillShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      focusElevation: 3,
      hoverElevation: 3,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.largeIncreased),
      ),
      backgroundColor: expressiveScheme.primaryContainer,
      foregroundColor: expressiveScheme.onPrimaryContainer,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: pillShape),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 40)),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: WidgetStatePropertyAll(
          BorderSide(color: expressiveScheme.outlineVariant),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return expressiveScheme.secondaryContainer;
          }
          return expressiveScheme.surfaceContainerLow;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return expressiveScheme.onSecondaryContainer;
          }
          return expressiveScheme.onSurfaceVariant;
        }),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: expressiveScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
        borderSide: BorderSide(color: expressiveScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
        borderSide: BorderSide(color: expressiveScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
        borderSide: BorderSide(color: expressiveScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
        borderSide: BorderSide(color: expressiveScheme.error, width: 1.5),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(
        expressiveScheme.surfaceContainerHigh,
      ),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStatePropertyAll(
        BorderSide(color: expressiveScheme.outlineVariant),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 3,
      backgroundColor: expressiveScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: ExpressiveShapes.dialog,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 0,
      modalElevation: 3,
      backgroundColor: expressiveScheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: ExpressiveShapes.bottomSheet,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 2,
      shape: pillShape,
      backgroundColor: expressiveScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: expressiveScheme.onInverseSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: 48,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: controlShape,
    ),
    chipTheme: ChipThemeData(
      shape: pillShape,
      side: BorderSide(color: expressiveScheme.outlineVariant),
      backgroundColor: expressiveScheme.surfaceContainerLow,
      selectedColor: expressiveScheme.secondaryContainer,
      secondarySelectedColor: expressiveScheme.secondaryContainer,
      checkmarkColor: expressiveScheme.onSecondaryContainer,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        color: expressiveScheme.onSurface,
      ),
      secondaryLabelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        color: expressiveScheme.onSecondaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: DividerThemeData(
      color: expressiveScheme.outlineVariant.withValues(alpha: 0.6),
      thickness: 1,
      space: 20,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: expressiveScheme.primary,
      linearTrackColor: expressiveScheme.surfaceContainerHighest,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(999),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: expressiveScheme.primary,
      inactiveTrackColor: expressiveScheme.surfaceContainerHighest,
      thumbColor: expressiveScheme.primary,
      overlayColor: expressiveScheme.primary.withValues(alpha: 0.14),
      trackHeight: 8,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return expressiveScheme.onPrimary;
        }
        return expressiveScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return expressiveScheme.primary;
        }
        return expressiveScheme.surfaceContainerHighest;
      }),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: expressiveScheme.outlineVariant.withValues(alpha: 0.4),
      labelColor: expressiveScheme.primary,
      unselectedLabelColor: expressiveScheme.onSurfaceVariant,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Alias conservé pour la compatibilité des appels existants.
ThemeData buildEditorialTheme({
  required ColorScheme colorScheme,
  required Brightness brightness,
  bool amoled = false,
}) => buildExpressiveTheme(
  colorScheme: colorScheme,
  brightness: brightness,
  amoled: amoled,
);

TextTheme _expressiveTextTheme(ColorScheme scheme) {
  final ink = scheme.onSurface;
  TextStyle display(double size, double height, {double spacing = -0.6}) =>
      TextStyle(
        fontFamily: 'Fraunces',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: spacing,
        height: height,
      );

  return TextTheme(
    displayLarge: display(38, 1.02, spacing: -0.7),
    displayMedium: display(30, 1.06, spacing: -0.6),
    displaySmall: display(25, 1.10, spacing: -0.4),
    headlineLarge: display(23, 1.14, spacing: -0.35),
    headlineMedium: display(20, 1.16, spacing: -0.25),
    headlineSmall: display(18, 1.20, spacing: -0.2),
    titleLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: ink,
      letterSpacing: -0.2,
      height: 1.24,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.28,
    ),
    titleSmall: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.28,
    ),
    bodyLarge: TextStyle(fontSize: 15, color: ink, height: 1.48),
    bodyMedium: TextStyle(fontSize: 13.5, color: ink, height: 1.45),
    bodySmall: TextStyle(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
      height: 1.38,
    ),
    labelLarge: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: ink,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontFamily: 'monospace',
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.5,
    ),
  );
}
