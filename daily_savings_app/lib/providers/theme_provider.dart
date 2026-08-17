import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_initialTheme());

  static ThemeMode _initialTheme() {
    final savedMode = LocalStorageService.getThemeMode();
    return savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  bool get isDarkMode => state == ThemeMode.dark;

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      LocalStorageService.saveThemeMode('light');
    } else {
      state = ThemeMode.dark;
      LocalStorageService.saveThemeMode('dark');
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    LocalStorageService.saveThemeMode(mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
