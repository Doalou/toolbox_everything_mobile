import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyLockBubblePortrait = 'lock_bubble_portrait';
  static const String _keyLowResourceMode = 'low_resource_mode';

  late final SharedPreferences _prefs;
  bool _lockBubbleLevelPortrait = true;
  bool _lowResourceMode = false;

  SettingsProvider(this._prefs) {
    _loadPrefs();
  }

  bool get lockBubbleLevelPortrait => _lockBubbleLevelPortrait;
  bool get lowResourceMode => _lowResourceMode;

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

  void _loadPrefs() {
    _lockBubbleLevelPortrait =
        _prefs.getBool(_keyLockBubblePortrait) ?? _lockBubbleLevelPortrait;
    _lowResourceMode = _prefs.getBool(_keyLowResourceMode) ?? _lowResourceMode;
    notifyListeners();
  }
}
