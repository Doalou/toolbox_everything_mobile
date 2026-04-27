import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/design/app_theme.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';

/// Provider du thème : gère les préférences utilisateur (mode, seed, dynamic, AMOLED)
/// et délègue la construction du [ThemeData] à [buildExpressiveTheme].
class ThemeProvider with ChangeNotifier {
  static const String _prefUseDynamic = 'pref_use_dynamic_color';
  static const String _prefSeedColor = 'pref_seed_color';
  static const String _prefThemeMode = 'pref_theme_mode';
  static const String _prefAmoled = 'pref_amoled_black';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = ExpressivePalette.seeds.first;
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
    _useDynamicColor = _prefs?.getBool(_prefUseDynamic) ?? _useDynamicColor;
    _useAmoledBlack = _prefs?.getBool(_prefAmoled) ?? _useAmoledBlack;
    final intSeed = _prefs?.getInt(_prefSeedColor);
    if (intSeed != null) {
      _seedColor = Color(intSeed);
    }
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
    await p.setInt(_prefSeedColor, color.toARGB32());
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
    return createThemeFromScheme(colorScheme, brightness);
  }

  /// Construit un thème à partir d'un [ColorScheme] donné (ex. dynamic color OS).
  ThemeData createThemeFromScheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    return buildExpressiveTheme(
      colorScheme: colorScheme,
      brightness: brightness,
      amoled: _useAmoledBlack,
    );
  }
}
