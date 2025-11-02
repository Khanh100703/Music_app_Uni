import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DefaultLoopMode { off, one, all }

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._internal();

  static final AppSettingsController instance = AppSettingsController._internal();

  static const _keyThemeMode = 'settings.themeMode';
  static const _keyPrimaryColor = 'settings.primaryColor';
  static const _keyLoopMode = 'settings.loopMode';
  static const _keyAutoPlay = 'settings.autoPlayNext';
  static const _keyMiniPlayer = 'settings.miniPlayer';

  final List<MaterialColor> availablePrimaryColors = const <MaterialColor>[
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.brown,
  ];

  late SharedPreferences _prefs;
  bool _initialized = false;

  ThemeMode _themeMode = ThemeMode.system;
  MaterialColor _primaryColor = Colors.deepPurple;
  DefaultLoopMode _defaultLoopMode = DefaultLoopMode.off;
  bool _autoPlayNext = true;
  bool _miniPlayerEnabled = true;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
    _initialized = true;
  }

  void _loadFromPrefs() {
    final themeModeName = _prefs.getString(_keyThemeMode);
    if (themeModeName != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => describeEnum(m) == themeModeName,
        orElse: () => ThemeMode.system,
      );
    }

    final primaryColorValue = _prefs.getInt(_keyPrimaryColor);
    if (primaryColorValue != null) {
      _primaryColor = _colorFromValue(primaryColorValue);
    }

    final loopModeName = _prefs.getString(_keyLoopMode);
    if (loopModeName != null) {
      _defaultLoopMode = DefaultLoopMode.values.firstWhere(
        (mode) => describeEnum(mode) == loopModeName,
        orElse: () => DefaultLoopMode.off,
      );
    }

    _autoPlayNext = _prefs.getBool(_keyAutoPlay) ?? true;
    _miniPlayerEnabled = _prefs.getBool(_keyMiniPlayer) ?? true;
  }

  Future<void> _save(String key, Object? value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, jsonEncode(value));
    }
  }

  ThemeMode get themeMode => _themeMode;
  MaterialColor get primaryColor => _primaryColor;
  DefaultLoopMode get defaultLoopMode => _defaultLoopMode;
  bool get autoPlayNext => _autoPlayNext;
  bool get miniPlayerEnabled => _miniPlayerEnabled;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _save(_keyThemeMode, describeEnum(mode));
    notifyListeners();
  }

  void setPrimaryColor(MaterialColor color) {
    if (_primaryColor == color) return;
    _primaryColor = color;
    _save(_keyPrimaryColor, color.value);
    notifyListeners();
  }

  void setDefaultLoopMode(DefaultLoopMode mode) {
    if (_defaultLoopMode == mode) return;
    _defaultLoopMode = mode;
    _save(_keyLoopMode, describeEnum(mode));
    notifyListeners();
  }

  void setAutoPlayNext(bool value) {
    if (_autoPlayNext == value) return;
    _autoPlayNext = value;
    _save(_keyAutoPlay, value);
    notifyListeners();
  }

  void setMiniPlayerEnabled(bool value) {
    if (_miniPlayerEnabled == value) return;
    _miniPlayerEnabled = value;
    _save(_keyMiniPlayer, value);
    notifyListeners();
  }

  Future<void> reset() async {
    _themeMode = ThemeMode.system;
    _primaryColor = Colors.deepPurple;
    _defaultLoopMode = DefaultLoopMode.off;
    _autoPlayNext = true;
    _miniPlayerEnabled = true;

    await Future.wait(<Future<void>>[
      _prefs.remove(_keyThemeMode),
      _prefs.remove(_keyPrimaryColor),
      _prefs.remove(_keyLoopMode),
      _prefs.remove(_keyAutoPlay),
      _prefs.remove(_keyMiniPlayer),
    ]);
    notifyListeners();
  }

  MaterialColor _colorFromValue(int value) {
    return availablePrimaryColors.firstWhere(
      (color) => color.value == value,
      orElse: () => Colors.deepPurple,
    );
  }
}
