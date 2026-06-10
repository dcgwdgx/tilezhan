import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Font hierarchy per design spec §2.2.
/// Base: Poppins (body), JetBrains Mono (mono), Noto Serif SC (tile chars).
class AppTypography {
  static const _base = 'Poppins';
  static const mono = 'JetBrains Mono';
  static const tile = 'Noto Serif SC';

  static const h1 = TextStyle(fontFamily: _base, fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, color: AppColors.jadeWhite);
  static const h2 = TextStyle(fontFamily: _base, fontSize: 24, fontWeight: FontWeight.w600, height: 1.33, color: AppColors.jadeWhite);
  static const h3 = TextStyle(fontFamily: _base, fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.jadeWhite);
  static const body = TextStyle(fontFamily: _base, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.jadeWhite);
  static const bodySmall = TextStyle(fontFamily: _base, fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, color: AppColors.jadeWhiteDim);
  static const caption = TextStyle(fontFamily: _base, fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, color: AppColors.jadeWhiteMuted);
  static const tileChar = TextStyle(fontFamily: tile, fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.jadeWhite);

  static const label = TextStyle(fontFamily: _base, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.jadeWhiteMuted);
  static const accent = TextStyle(fontFamily: _base, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold);
}
