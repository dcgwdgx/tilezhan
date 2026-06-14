/// AppTypography — TileZhan font hierarchy and text style definitions.
///
/// Provides a consistent typographic scale: h1/h2/h3 headings,
/// body/bodySmall for content, caption for metadata, tileChar for
/// mahjong tile rendering, label for badges, and accent for highlights.
/// Font families: Poppins (body), JetBrains Mono (code), Noto Serif SC (tiles).
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Font hierarchy per design spec §2.2.
/// Base: Poppins (body), JetBrains Mono (mono), Noto Serif SC (tile chars).
class AppTypography {
  static const _base = 'Poppins';
  /// Monospace font family for code blocks and technical data.
  static const mono = 'JetBrains Mono';
  /// Serif font family for tile/mahjong character display.
  static const tile = 'Noto Serif SC';

  /// Primary heading for page titles and hero text.
  static const h1 = TextStyle(fontFamily: _base, fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, color: AppColors.jadeWhite);
  /// Secondary heading for section titles.
  static const h2 = TextStyle(fontFamily: _base, fontSize: 24, fontWeight: FontWeight.w600, height: 1.33, color: AppColors.jadeWhite);
  /// Tertiary heading for subsection titles.
  static const h3 = TextStyle(fontFamily: _base, fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.jadeWhite);
  /// Standard body text for paragraphs and general content.
  static const body = TextStyle(fontFamily: _base, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.jadeWhite);
  /// Smaller body text for secondary content and descriptions.
  static const bodySmall = TextStyle(fontFamily: _base, fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, color: AppColors.jadeWhiteDim);
  /// Small caption text for secondary metadata and footnotes.
  static const caption = TextStyle(fontFamily: _base, fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, color: AppColors.jadeWhiteMuted);
  /// Large serif display type for tile/mahjong character rendering.
  static const tileChar = TextStyle(fontFamily: tile, fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.jadeWhite);

  /// Small uppercase-style label for badges, tags, and overlines.
  static const label = TextStyle(fontFamily: _base, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.jadeWhiteMuted);
  /// Highlighted accent text for emphasis and call-to-action elements.
  static const accent = TextStyle(fontFamily: _base, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold);
}
