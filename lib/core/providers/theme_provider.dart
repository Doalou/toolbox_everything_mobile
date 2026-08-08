import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/design/app_theme.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';

class ThemeProvider with ChangeNotifier {
  static const _prefUseDynamic = 'pref_use_dynamic_color';
  static const _prefSeedColor = 'pref_seed_color';
  static const _prefThemeMode = 'pref_theme_mode';
  static const _prefAmoled = 'pref_amoled_black';
  static const _prefAdvanced = 'pref_advanced_appearance';

  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = EditorialPalette.accentLight;
  bool _useDynamicColor = false;
  bool _useAmoledBlack = false;
  bool _advancedCustomization = false;

  ThemeProvider([SharedPreferences? prefs]) {
    if (prefs == null) {
      _init();
    } else {
      _prefs = prefs;
      _hydrateFromPrefs();
    }
  }

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;
  bool get useAmoledBlack => _useAmoledBlack;
  bool get advancedCustomization => _advancedCustomization;

  ThemeData get lightTheme => _createTheme(Brightness.light);
  ThemeData get darkTheme => _createTheme(Brightness.dark);

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _saveThemeMode(mode);
    notifyListeners();
  }

  void setSeedColor(Color color) {
    if (_seedColor == color && !_useDynamicColor && _advancedCustomization) {
      return;
    }
    _seedColor = color;
    _advancedCustomization = true;
    _useDynamicColor = false;
    _saveSeedColor(color);
    _saveAdvanced(true);
    _saveUseDynamic(false);
    notifyListeners();
  }

  void setUseDynamicColor(bool enabled) {
    if (_useDynamicColor == enabled) return;
    _useDynamicColor = enabled;
    if (enabled) {
      _advancedCustomization = true;
      _saveAdvanced(true);
    }
    _saveUseDynamic(enabled);
    notifyListeners();
  }

  void setAdvancedCustomization(bool enabled) {
    if (_advancedCustomization == enabled) return;
    _advancedCustomization = enabled;
    if (!enabled) {
      _useDynamicColor = false;
      _seedColor = EditorialPalette.accentLight;
      _saveUseDynamic(false);
      _saveSeedColor(_seedColor);
    }
    _saveAdvanced(enabled);
    notifyListeners();
  }

  void setUseAmoledBlack(bool enabled) {
    if (_useAmoledBlack == enabled) return;
    _useAmoledBlack = enabled;
    _saveAmoled(enabled);
    notifyListeners();
  }

  void resetAppearance() {
    _themeMode = ThemeMode.system;
    _seedColor = EditorialPalette.accentLight;
    _useDynamicColor = false;
    _useAmoledBlack = false;
    _advancedCustomization = false;
    _saveThemeMode(_themeMode);
    _saveSeedColor(_seedColor);
    _saveUseDynamic(false);
    _saveAmoled(false);
    _saveAdvanced(false);
    notifyListeners();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _hydrateFromPrefs();
  }

  void _hydrateFromPrefs() {
    _useDynamicColor = _prefs?.getBool(_prefUseDynamic) ?? false;
    _useAmoledBlack = _prefs?.getBool(_prefAmoled) ?? false;
    final storedSeed = _prefs?.getInt(_prefSeedColor);
    if (storedSeed != null) _seedColor = Color(storedSeed);

    final storedAdvanced = _prefs?.getBool(_prefAdvanced);
    _advancedCustomization =
        storedAdvanced ??
        (_useDynamicColor ||
            (storedSeed != null &&
                storedSeed != ExpressivePalette.violetVibrant.toARGB32()));

    switch (_prefs?.getString(_prefThemeMode)) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'dark':
        _themeMode = ThemeMode.dark;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<SharedPreferences> _preferences() async =>
      _prefs ?? await SharedPreferences.getInstance();

  Future<void> _saveUseDynamic(bool value) async =>
      (await _preferences()).setBool(_prefUseDynamic, value);

  Future<void> _saveSeedColor(Color color) async =>
      (await _preferences()).setInt(_prefSeedColor, color.toARGB32());

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    await (await _preferences()).setString(_prefThemeMode, value);
  }

  Future<void> _saveAmoled(bool value) async =>
      (await _preferences()).setBool(_prefAmoled, value);

  Future<void> _saveAdvanced(bool value) async =>
      (await _preferences()).setBool(_prefAdvanced, value);

  ThemeData _createTheme(Brightness brightness) {
    final scheme = EditorialPalette.scheme(
      brightness,
      accent: _advancedCustomization ? _seedColor : null,
    );
    return createThemeFromScheme(scheme, brightness);
  }

  ThemeData createThemeFromScheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) => buildEditorialTheme(
    colorScheme: colorScheme,
    brightness: brightness,
    amoled: _useAmoledBlack,
  );
}
