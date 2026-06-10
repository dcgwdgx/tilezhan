import 'package:flutter/material.dart';

/// 8px Grid spacing system per design spec.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Horizontal padding for screen edges
  static const screenH = EdgeInsets.symmetric(horizontal: 20);
  // Card padding
  static const card = EdgeInsets.all(16);
  // Section gap
  static const sectionGap = SizedBox(height: 16);
}
