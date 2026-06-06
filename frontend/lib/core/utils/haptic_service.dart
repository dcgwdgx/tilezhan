import 'package:flutter/services.dart';

class HapticService {
  static void lightTap() => HapticFeedback.lightImpact();
  static void mediumTap() => HapticFeedback.mediumImpact();
  static void heavyTap() => HapticFeedback.heavyImpact();

  static void correctAnswer() => lightTap();
  static void wrongAnswer() {
    heavyTap();
    Future.delayed(const Duration(milliseconds: 100), heavyTap);
  }
  static void discardSlash() => mediumTap();
}
