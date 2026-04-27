import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';

/// Construit un [ThemeData] Material 3 Expressive à partir d'un [ColorScheme].
/// Aucune dépendance à du state — pur, testable.
ThemeData buildExpressiveTheme({
  required ColorScheme colorScheme,
  required Brightness brightness,
  bool amoled = false,
}) {
  final bool isDark = brightness == Brightness.dark;
  final bool useAmoled = isDark && amoled;
  final Color scaffoldBg = useAmoled ? Colors.black : colorScheme.surface;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBg,
    canvasColor: useAmoled ? Colors.black : null,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    textTheme: _buildExpressiveTextTheme(colorScheme),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      surfaceTintColor: colorScheme.surfaceTint,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: ExpressiveTokens.elevation2,
      centerTitle: false,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        height: 1.2,
        letterSpacing: -0.2,
      ),
    ),

    // Cards expressives — rayon généreux, pas d'élévation par défaut.
    cardTheme: CardThemeData(
      elevation: ExpressiveTokens.elevation0,
      shadowColor: Colors.transparent,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: ExpressiveShapes.card(),
      margin: const EdgeInsets.all(ExpressiveTokens.spacingSm),
      color: colorScheme.surfaceContainerLow,
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: ExpressiveTokens.elevation1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
        shape: const StadiumBorder(),
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: colorScheme.outline, width: 1.2),
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // Floating action button — pill shape M3E
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
      ),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: ExpressiveTokens.elevation2,
      focusElevation: ExpressiveTokens.elevation3,
      hoverElevation: ExpressiveTokens.elevation3,
      highlightElevation: ExpressiveTokens.elevation4,
      iconSize: ExpressiveTokens.iconMd,
    ),

    // SegmentedButton
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        shape: WidgetStateProperty.all(const StadiumBorder()),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    ),

    // IconButton
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
        ),
        padding: const EdgeInsets.all(10),
      ),
    ),

    // Switches
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorScheme.outline;
      }),
      trackOutlineWidth: WidgetStateProperty.all(1.5),
    ),

    // Inputs — surface containerHighest, sans border par défaut, focus accentué.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ExpressiveTokens.spacingLg,
        vertical: ExpressiveTokens.spacing,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    ),

    // BottomSheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: useAmoled ? Colors.black : colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: ExpressiveShapes.bottomSheet,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: useAmoled ? Colors.black : colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: ExpressiveShapes.dialog,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: ExpressiveTokens.elevation2,
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ExpressiveTokens.spacingLg,
        vertical: ExpressiveTokens.spacingSm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
      ),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      thickness: 1,
      space: ExpressiveTokens.spacingLg,
    ),

    // Chips expressifs (pill shape)
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      selectedColor: colorScheme.secondaryContainer,
      shape: const StadiumBorder(),
      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: useAmoled ? Colors.black : colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      ),
      height: 72,
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      trackHeight: 12,
    ),

    // Progress
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
      linearMinHeight: 8,
    ),

    // Page transitions — predictive back sur Android, fade-through partout.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

TextTheme _buildExpressiveTextTheme(ColorScheme colorScheme) {
  final base = colorScheme.onSurface;
  return TextTheme(
    // Display — héro, titres marquants
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      color: colorScheme.primary,
      letterSpacing: -1.2,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: colorScheme.primary,
      letterSpacing: -0.8,
      height: 1.15,
    ),
    displaySmall: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
      letterSpacing: -0.4,
      height: 1.2,
    ),

    // Headline — sections
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: base,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: base,
      letterSpacing: 0,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: base,
      letterSpacing: 0,
      height: 1.4,
    ),

    // Title
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: base,
      letterSpacing: 0,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: base,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: base,
      letterSpacing: 0.1,
      height: 1.4,
    ),

    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: base,
      letterSpacing: 0.1,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: base.withValues(alpha: 0.85),
      letterSpacing: 0.15,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: base.withValues(alpha: 0.7),
      letterSpacing: 0.2,
      height: 1.45,
    ),

    // Label
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: base,
      letterSpacing: 0.2,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: base,
      letterSpacing: 0.4,
      height: 1.35,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: base,
      letterSpacing: 0.5,
      height: 1.4,
    ),
  );
}
