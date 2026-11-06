import 'package:flutter/material.dart';

/// نظام ثيمات موحد يدعم الوضعين الفاتح والداكن مع دعم RTL للغة العربية.
class AppTheme {
  AppTheme._();

  // ── ألوانksen básica (Material 3) ──
  static const Color _primaryDark = Color(0xFF6200EE);
  static const Color _primaryLight = Color(0xFF7B6BF0);
  static const Color _surfaceDark = Color(0xFF121212);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _backgroundDark = Color(0xFF0A0A0A);
  static const Color _backgroundLight = Color(0xFFF5F5F5);

  /// ثيم الوضع الفاتح
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        primaryContainer: Color(0xFFE8EAF6),
        secondary: Color(0xFF03DAC6),
        secondaryContainer: Color(0xFFE0F7FA),
        surface: _surfaceLight,
        background: _backgroundLight,
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: const BorderSide(color: _primaryLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        color: _surfaceLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  /// ثيم الوضع الداكن
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        primaryContainer: Color(0xFF3700B3),
        secondary: Color(0xFF03DAC6),
        secondaryContainer: Color(0xFF018786),
        surface: _surfaceDark,
        background: _backgroundDark,
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.grey.shade300,
        onBackground: Colors.grey.shade300,
        onError: Colors.black,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          side: const BorderSide(color: _primaryDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        color: _surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  /// ottenere thème actuel selon le mode sombre
  static ThemeData getTheme(bool isDark) {
    return isDark ? darkTheme() : lightTheme();
  }
}
