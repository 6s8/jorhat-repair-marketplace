import 'package:flutter/material.dart';

/// Central theme configuration for clean architectural setup.
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F52BA),
        primary: const Color(0xFF0F52BA),
        secondary: const Color(0xFF00A86B),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: const Color(0xFF0F52BA),
      ),
    );
  }
}
