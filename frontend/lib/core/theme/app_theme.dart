import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static TextTheme get _textTheme {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 4, color: AppColors.jadeWhite),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.neonGold),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.jadeWhite),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.jadeWhite),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite),
      bodyMedium: TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim),
      bodySmall: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold),
      labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.jadeWhiteMuted),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteMuted),
    );
  }

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
      textTheme: _textTheme,

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

      // Cards — elevated with gold accent border
      cardTheme: CardThemeData(
        color: AppColors.jadeCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: const BorderSide(color: AppColors.jadeHover, width: 1),
        ),
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
