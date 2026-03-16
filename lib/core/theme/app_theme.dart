import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryPurple,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.warmGold,
        error: AppColors.alertRed,
        surface: AppColors.backgroundColor,
        onPrimary: AppColors.starWhite,
        onSecondary: AppColors.deepBlack,
        onError: AppColors.starWhite,
        onSurface: AppColors.deepBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.starWhite,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.starWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      fontFamily: 'Cairo', // Assuming a standard Arabic font like Cairo or Tajawal
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryPurple,
      scaffoldBackgroundColor: AppColors.deepBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        secondary: AppColors.warmGold,
        error: AppColors.error,
        surface: AppColors.deepBlack, // Darker surface
        onPrimary: AppColors.starWhite,
        onSecondary: AppColors.deepBlack,
        onError: AppColors.starWhite,
        onSurface: AppColors.starWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepBlack,
        foregroundColor: AppColors.starWhite,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.starWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      fontFamily: 'Cairo',
    );
  }
}
