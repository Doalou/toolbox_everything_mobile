import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyLockBubblePortrait = 'lock_bubble_portrait';

  bool _lockBubbleLevelPortrait = true;

  SettingsProvider() {
    _loadPrefs();
  }

  bool get lockBubbleLevelPortrait => _lockBubbleLevelPortrait;

  Future<void> setLockBubbleLevelPortrait(bool value) async {
    if (_lockBubbleLevelPortrait == value) return;
    _lockBubbleLevelPortrait = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLockBubblePortrait, value);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _lockBubbleLevelPortrait =
        prefs.getBool(_keyLockBubblePortrait) ?? _lockBubbleLevelPortrait;
    notifyListeners();
  }
}
