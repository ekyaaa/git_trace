import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Theme mode options
enum AppThemeMode {
  light,
  dark,
  system,
}

/// State notifier for theme mode
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.dark) {
    _loadTheme();
  }

  static const String _key = AppConstants.prefKeyThemeMode;

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 1; // Default to dark (index 1)
    if (index < AppThemeMode.values.length) {
      state = AppThemeMode.values[index];
    }
  }

  /// Save theme preference
  Future<void> _saveTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    final newMode = state == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    state = newMode;
    _saveTheme(newMode);
  }

  /// Set specific theme mode
  void setThemeMode(AppThemeMode mode) {
    state = mode;
    _saveTheme(mode);
  }

  /// Convert AppThemeMode to Flutter's ThemeMode
  ThemeMode get flutterThemeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Check if currently in dark mode
  bool get isDark => state == AppThemeMode.dark;
}

/// Provider for theme mode
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Provider that returns Flutter's ThemeMode
final flutterThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(themeModeProvider);
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});
