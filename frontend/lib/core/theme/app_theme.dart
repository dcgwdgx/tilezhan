import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// AppTheme — global visual theme for the TileZhan app.
///
/// Provides a cohesive [ThemeData] built from [AppColors] and [AppTypography],
/// covering ColorScheme, typography, and component-level overrides for
/// AppBar, cards, buttons, bottom nav, and progress indicators.
/// The dark cyber-brush-and-ink aesthetic (赛博国风) is the single supported
/// brightness; all surfaces use the jade-deep palette with vermillion and
/// neon-gold accents.

class AppTheme {
  /// The single [ThemeData] instance used app-wide.
  ///
  /// Always dark brightness. Colors are drawn from [AppColors];
  /// [AppTypography] is applied via the global [fontFamily] and per-widget
  /// [textStyle] overrides. Callers should access this through Riverpod
  /// or `Theme.of(context)` — not by holding a reference to the getter result.
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
          borderRadius: BorderRadius.all(Radius.circular(16)),
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
