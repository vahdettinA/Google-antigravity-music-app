import 'package:flutter/material.dart';

/// Theme provider for managing app theme state
class ThemeProvider extends ChangeNotifier {
  bool _isGlassTheme = false;

  bool get isGlassTheme => _isGlassTheme;

  /// Toggle between dark and glassmorphism themes
  void toggleTheme() {
    _isGlassTheme = !_isGlassTheme;
    notifyListeners();
  }

  /// Set specific theme
  void setTheme(bool isGlass) {
    _isGlassTheme = isGlass;
    notifyListeners();
  }
}
