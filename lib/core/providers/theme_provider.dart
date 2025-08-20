import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';

class ThemeProvider with ChangeNotifier {
  static const String _prefUseDynamic = 'pref_use_dynamic_color';
  static const String _prefSeedColor = 'pref_seed_color';
  static const String _prefThemeMode = 'pref_theme_mode';
  static const String _prefAmoled = 'pref_amoled_black';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = AppConstants
      .expressiveColors
      .first; // Utilise la première couleur expressive
  bool _useDynamicColor = false;
  bool _useAmoledBlack = false;

  ThemeProvider([SharedPreferences? prefs]) {
    if (prefs != null) {
      _prefs = prefs;
      _hydrateFromPrefs();
    } else {
      _init();
    }
  }

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;
  bool get useAmoledBlack => _useAmoledBlack;

  ThemeData get lightTheme => _createTheme(Brightness.light);
  ThemeData get darkTheme => _createTheme(Brightness.dark);

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemeMode(mode);
      notifyListeners();
    }
  }

  void setSeedColor(Color color) {
    if (_seedColor != color) {
      _seedColor = color;
      _saveSeedColor(color);
      notifyListeners();
    }
  }

  void setUseDynamicColor(bool enabled) {
    if (_useDynamicColor != enabled) {
      _useDynamicColor = enabled;
      _saveUseDynamic(enabled);
      notifyListeners();
    }
  }

  void setUseAmoledBlack(bool enabled) {
    if (_useAmoledBlack != enabled) {
      _useAmoledBlack = enabled;
      _saveAmoled(enabled);
      notifyListeners();
    }
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _hydrateFromPrefs();
  }

  void _hydrateFromPrefs() {
    // Charger dynamic color
    _useDynamicColor = _prefs?.getBool(_prefUseDynamic) ?? _useDynamicColor;
    _useAmoledBlack = _prefs?.getBool(_prefAmoled) ?? _useAmoledBlack;
    // Charger seed color
    final intSeed = _prefs?.getInt(_prefSeedColor);
    if (intSeed != null) {
      _seedColor = Color(intSeed);
    }
    // Charger theme mode
    final mode = _prefs?.getString(_prefThemeMode);
    if (mode != null) {
      switch (mode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
    notifyListeners();
  }

  Future<void> _saveUseDynamic(bool value) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setBool(_prefUseDynamic, value);
  }

  Future<void> _saveSeedColor(Color color) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setInt(_prefSeedColor, color.value);
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final v = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await p.setString(_prefThemeMode, v);
  }

  Future<void> _saveAmoled(bool value) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setBool(_prefAmoled, value);
  }

  ThemeData _createTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.expressive,
    );

    final bool isDark = brightness == Brightness.dark;
    final bool amoled = isDark && _useAmoledBlack;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: amoled ? Colors.black : colorScheme.surface,
      canvasColor: amoled ? Colors.black : null,
      visualDensity: VisualDensity.standard,

      // Typography moderne et lisible
      textTheme: _createModernTextTheme(colorScheme, brightness == Brightness.dark),

      // AppBar M3
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: false,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light // icônes claires sur status bar sombre
            : SystemUiOverlayStyle.dark, // icônes sombres sur status bar claire
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          height: 1.2,
        ),
      ),

      // Cards M3
      cardTheme: CardThemeData(
        elevation: AppConstants.cardElevation,
        shadowColor: Colors.transparent,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.smallPadding),
      ),

      // Buttons M3
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppConstants.buttonElevation,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          ),
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // SegmentedButton M3
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)),
          ),
        ),
      ),

      // IconButtons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Switches
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.largePadding,
          vertical: AppConstants.defaultPadding,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ),

      // BottomSheet & Dialogs
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: amoled ? Colors.black : colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.largePadding)),
        ),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: amoled ? Colors.black : colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largePadding),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius)),
        behavior: SnackBarBehavior.floating,
      ),

      // Lists & Dividers
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.largePadding,
          vertical: AppConstants.smallPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        ),
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        subtitleTextStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        thickness: 1,
        space: AppConstants.largePadding,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius)),
        labelStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500),
      ),

      // NavigationBar (si utilisé)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: amoled ? Colors.black : colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
      ),
    );
  }

  TextTheme _createModernTextTheme(ColorScheme colorScheme, bool isDark) {
    final baseColor = colorScheme.onSurface;

    return TextTheme(
      // Display styles - pour les titres héroïques
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: colorScheme.primary,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
        letterSpacing: -0.2,
        height: 1.3,
      ),

      // Headline styles - pour les titres de sections
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.0,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.0,
        height: 1.4,
      ),

      // Title styles - pour les titres de cards
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.0,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Body styles - pour le contenu
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor.withValues(alpha: 0.8),
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: baseColor.withValues(alpha: 0.7),
        letterSpacing: 0.2,
        height: 1.4,
      ),

      // Label styles - pour les boutons et labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.2,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.2,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.2,
        height: 1.4,
      ),
    );
  }
}
