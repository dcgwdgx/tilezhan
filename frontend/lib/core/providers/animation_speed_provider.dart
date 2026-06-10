import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global animation speed factor.
/// - 1.0: full animations (default, beginner-friendly)
/// - 0.2: fast skim (expert mode)
/// - 0.0: instant (no animations)
final animationSpeedProvider = StateProvider<double>((ref) => 1.0);

/// Convenience provider — applies speed factor to a base duration.
Duration applySpeed(double baseMs, double factor) {
  final clamped = factor.clamp(0.0, 1.0);
  if (clamped == 0.0) return Duration.zero;
  return Duration(milliseconds: (baseMs * clamped).round());
}
