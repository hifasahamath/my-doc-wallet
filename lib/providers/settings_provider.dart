import 'package:flutter/material.dart';

import 'package:my_doc_wallet/services/security_service.dart';

/// User preferences (theme mode, auto-lock).
class SettingsProvider extends ChangeNotifier {
  final SecurityService _security;

  ThemeMode _themeMode = ThemeMode.system;
  int _autoLockSeconds = 60;

  SettingsProvider(this._security);

  ThemeMode get themeMode => _themeMode;
  int get autoLockSeconds => _autoLockSeconds;

  Future<void> loadSettings() async {
    final mode = await _security.getThemeMode();
    _themeMode = _parseThem(mode);
    _autoLockSeconds = await _security.getAutoLockSeconds();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _security.setThemeMode(mode.name);
    notifyListeners();
  }

  Future<void> setAutoLockSeconds(int seconds) async {
    _autoLockSeconds = seconds;
    await _security.setAutoLockSeconds(seconds);
    notifyListeners();
  }

  ThemeMode _parseThem(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
