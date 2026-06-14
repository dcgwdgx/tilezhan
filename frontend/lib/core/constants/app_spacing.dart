/// AppSpacing 间距系统 — 8px Grid spacing constants (xs/sm/md/lg/xl/xxl).
///
/// All spacing values follow an 8px grid baseline, ensuring consistent
/// vertical rhythm and horizontal alignment across the entire app.
/// Also provides common EdgeInsets and SizedBox presets for screen edges,
/// cards, and section gaps.
import 'package:flutter/material.dart';

/// 8px Grid spacing system per design spec.
///
/// Usage: `AppSpacing.md` → 16.0, `AppSpacing.screenH` → EdgeInsets(20), etc.
class AppSpacing {
  /// Extra small spacing — 4px (half grid unit).
  static const double xs = 4;
  /// Small spacing — 8px (1 grid unit).
  static const double sm = 8;
  /// Medium spacing — 16px (2 grid units).
  static const double md = 16;
  /// Large spacing — 24px (3 grid units).
  static const double lg = 24;
  /// Extra large spacing — 32px (4 grid units).
  static const double xl = 32;
  /// Extra extra large spacing — 48px (6 grid units).
  static const double xxl = 48;

  /// Horizontal padding for screen edges — EdgeInsets.symmetric(horizontal: 20).
  static const screenH = EdgeInsets.symmetric(horizontal: 20);
  /// Card inner padding — EdgeInsets.all(16).
  static const card = EdgeInsets.all(16);
  /// Section gap spacer — SizedBox(height: 16).
  static const sectionGap = SizedBox(height: 16);
}
