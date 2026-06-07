import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.jadeDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.vermillion,
        secondary: AppColors.neonGold,
        surface: AppColors.jadeCard,
        error: AppColors.vermillion,
        onPrimary: Colors.white,
        onSecondary: AppColors.jadeDeep,
        onSurface: AppColors.jadeWhite,
      ),
      fontFamily: 'Poppins',

      // AppBar - match prototype dark header
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.jadeDeep,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.jadeWhite,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.jadeWhite,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.jadeCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.neonGold.withValues(alpha: 0.1)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vermillion,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.jadeWhiteDim),
      ),

      // Bottom nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D3D26),
        selectedItemColor: AppColors.neonGold,
        unselectedItemColor: AppColors.jadeWhiteMuted,
        type: BottomNavigationBarType.fixed,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.neonGold,
        linearTrackColor: AppColors.jadeHover,
      ),
    );
  }
}
