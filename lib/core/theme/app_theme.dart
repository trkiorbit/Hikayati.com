import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryDeepPurple,
      scaffoldBackgroundColor: AppColors.deepNight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDeepPurple,
        secondary: AppColors.vibrantOrange,
        error: AppColors.error,
        surface: AppColors.surfaceColor,
        onPrimary: AppColors.glassWhite,
        onSecondary: AppColors.glassWhite,
        onError: AppColors.glassWhite,
        onSurface: AppColors.glassWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.glassWhite,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeepPurple,
          foregroundColor: AppColors.glassWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.vibrantOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.vibrantOrange, width: 2),
          foregroundColor: AppColors.vibrantOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.vibrantOrange, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.vibrantOrange, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDeepPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.glassWhite),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      fontFamily: GoogleFonts.cairo().fontFamily,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.glassWhite,
        ),
        headlineMedium: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.glassWhite,
        ),
        titleLarge: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.glassWhite,
        ),
        titleMedium: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.glassWhite,
        ),
        bodyLarge: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.glassWhite,
        ),
        bodyMedium: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.glassWhite,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDeepPurple,
      scaffoldBackgroundColor: AppColors.deepNight,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDeepPurple,
        secondary: AppColors.vibrantOrange,
        error: AppColors.error,
        surface: AppColors.cardSurface,
        onPrimary: AppColors.glassWhite,
        onSecondary: AppColors.glassWhite,
        onError: AppColors.glassWhite,
        onSurface: AppColors.glassWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.glassWhite,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeepPurple,
          foregroundColor: AppColors.glassWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.vibrantOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.vibrantOrange, width: 2),
          foregroundColor: AppColors.vibrantOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.vibrantOrange, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.vibrantOrange, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDeepPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.glassWhite),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      fontFamily: GoogleFonts.cairo().fontFamily,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.glassWhite,
        ),
        headlineMedium: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.glassWhite,
        ),
        titleLarge: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.glassWhite,
        ),
        titleMedium: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.glassWhite,
        ),
        bodyLarge: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.glassWhite,
        ),
        bodyMedium: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.glassWhite,
        ),
      ),
    );
  }
}
