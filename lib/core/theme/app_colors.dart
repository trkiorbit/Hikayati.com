import 'package:flutter/material.dart';

class AppColors {
  // Final Visual Identity Colors (2026-04-15)
  static const Color primaryDeepPurple = Color(0xFF2D0B5A);   // بنفسجي ملكي داكن (الأساسي)
  static const Color vibrantOrange = Color(0xFFFF8C00);       // برتقالي حيوي (الثانوي)
  static const Color warmGold = Color(0xFFFFD700);            // ذهبي دافئ (التمييز)
  static const Color deepNight = Color(0xFF0D0D1A);           // خلفية ليلية
  static const Color glassWhite = Color(0xFFF5F0FF);         // نص أبيض دافئ

  // Legacy aliases for backward compatibility (to be removed later)
  static const Color primary = primaryDeepPurple;
  static const Color secondary = vibrantOrange;
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);

  // بنفسجي فاتح — للنصوص البنفسجية على خلفيات داكنة
  static const Color purpleGlow = Color(0xFF9B72CF);

  // Background and Surface Colors (Derived for UI needs)
  static const Color backgroundColor = deepNight;
  static const Color surfaceColor = Color(0xFF151024);  // سطح داكن متناسق
  static const Color cardSurface = Color(0xFF1A122A);
  static const Color appBarBackground = Color(0xFF1A122A);

  // Alias — used in some screens (same as deepNight)
  static const Color deepBlack = deepNight;
}
