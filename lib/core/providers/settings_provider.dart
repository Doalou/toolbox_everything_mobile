import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyLockBubblePortrait = 'lock_bubble_portrait';
  static const String _keyLowResourceMode = 'low_resource_mode';
  static const String _keyHaptics = 'haptics_enabled';

  late final SharedPreferences _prefs;
  bool _lockBubbleLevelPortrait = true;
  bool _lowResourceMode = false;
  bool _hapticsEnabled = true;

  SettingsProvider(this._prefs) {
    _loadPrefs();
  }

  bool get lockBubbleLevelPortrait => _lockBubbleLevelPortrait;
  bool get lowResourceMode => _lowResourceMode;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> setLockBubbleLevelPortrait(bool value) async {
    if (_lockBubbleLevelPortrait == value) return;
    _lockBubbleLevelPortrait = value;
    notifyListeners();
    await _prefs.setBool(_keyLockBubblePortrait, value);
  }

  Future<void> setLowResourceMode(bool value) async {
    if (_lowResourceMode == value) return;
    _lowResourceMode = value;
    notifyListeners();
    await _prefs.setBool(_keyLowResourceMode, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_keyHaptics, value);
  }

  void _loadPrefs() {
    _lockBubbleLevelPortrait =
        _prefs.getBool(_keyLockBubblePortrait) ?? _lockBubbleLevelPortrait;
    _lowResourceMode = _prefs.getBool(_keyLowResourceMode) ?? _lowResourceMode;
    _hapticsEnabled = _prefs.getBool(_keyHaptics) ?? _hapticsEnabled;
    notifyListeners();
  }
}
