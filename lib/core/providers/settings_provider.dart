import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyLockBubblePortrait = 'lock_bubble_portrait';
  static const String _keyLowResourceMode = 'low_resource_mode';

  bool _lockBubbleLevelPortrait = true;
  bool _lowResourceMode = false;

  SettingsProvider() {
    _loadPrefs();
  }

  bool get lockBubbleLevelPortrait => _lockBubbleLevelPortrait;
  bool get lowResourceMode => _lowResourceMode;

  Future<void> setLockBubbleLevelPortrait(bool value) async {
    if (_lockBubbleLevelPortrait == value) return;
    _lockBubbleLevelPortrait = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLockBubblePortrait, value);
  }

  Future<void> setLowResourceMode(bool value) async {
    if (_lowResourceMode == value) return;
    _lowResourceMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLowResourceMode, value);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _lockBubbleLevelPortrait =
        prefs.getBool(_keyLockBubblePortrait) ?? _lockBubbleLevelPortrait;
    _lowResourceMode = prefs.getBool(_keyLowResourceMode) ?? _lowResourceMode;
    notifyListeners();
  }
}
