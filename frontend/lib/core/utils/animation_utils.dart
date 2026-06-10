import 'dart:io' show Platform;

/// True when running in Flutter test environment.
bool get isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

/// Returns a duration that is zero in tests, or the given [ms] multiplied by
/// [speedFactor] in production. Use for infinite/repeating decorative animations
/// that would block `pumpAndSettle()`.
Duration safeAnimDuration(double ms, double speedFactor) {
  if (isTestEnvironment) return Duration.zero;
  final clamped = speedFactor.clamp(0.0, 1.0);
  if (clamped == 0.0) return Duration.zero;
  return Duration(milliseconds: (ms * clamped).round());
}
