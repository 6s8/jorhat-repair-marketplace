import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData getTheme([Color? seedColor]) {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headingTextTheme = GoogleFonts.poppinsTextTheme();

    final textTheme = baseTextTheme.copyWith(
      displayLarge: headingTextTheme.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
        height: 1.25,
        letterSpacing: -0.5,
      ),
      headlineLarge: headingTextTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
        height: 1.3,
      ),
      headlineMedium: headingTextTheme.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
        height: 1.35,
      ),
      headlineSmall: headingTextTheme.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.4,
      ),
      titleLarge: headingTextTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.4,
      ),
      titleMedium: headingTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.4,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        color: AppColors.text,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.text,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: AppColors.textMuted,
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor ?? AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.text,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme([Color? seedColor]) {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final headingTextTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    const darkBg = AppColors.darkBackground;
    const darkSurface = AppColors.darkSurface;
    const darkText = Color(0xFFF8FAFC);
    const darkTextMuted = AppColors.darkTextMuted;

    final textTheme = baseTextTheme.copyWith(
      displayLarge: headingTextTheme.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      headlineMedium: headingTextTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      titleLarge: headingTextTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        color: darkText,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: darkText,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: darkTextMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: seedColor ?? AppColors.primary,
        primary: const Color(0xFF38BDF8),
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: darkSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.text,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
    );
  }
}
