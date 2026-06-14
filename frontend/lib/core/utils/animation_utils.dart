/// Animation utilities — Bezier curves, easing, sprite-sheet frames, and
/// test-safe animation helpers.
///
/// All duration-producing helpers return [Duration.zero] in the Flutter test
/// environment so that widget tests complete instantly without manual ticking.
/// In production, durations are scaled by a configurable `speedFactor`
/// (0.0–1.0) that lets the caller implement user-facing speed preferences.
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// True when the process is running inside a Flutter test.
///
/// Checks for the `FLUTTER_TEST` environment variable that the framework
/// injects automatically when `flutter test` or `flutter run --test` is used.
bool get isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

/// Returns a test-safe [Duration] from the given [ms] and [speedFactor].
///
/// * In a test environment the result is always [Duration.zero].
/// * Otherwise the duration is `ms * speedFactor` milliseconds, where
///   [speedFactor] is clamped to the range `[0.0, 1.0]`. A factor of 0.0
///   yields [Duration.zero]; a factor of 1.0 yields the full `ms`.
Duration safeAnimDuration(int ms, double speedFactor) {
  if (isTestEnvironment) return Duration.zero;
  final s = speedFactor.clamp(0.0, 1.0);
  if (s == 0.0) return Duration.zero;
  return Duration(milliseconds: (ms * s).round());
}

/// Creates an [AnimationController] whose duration is automatically
/// shortened to zero in tests and scaled by [speed] in production.
///
/// Convenience wrapper around [safeAnimDuration]; see that function for the
/// precise scaling semantics.
AnimationController safeController(TickerProvider vsync, int ms, double speed) {
  return AnimationController(
    vsync: vsync,
    duration: safeAnimDuration(ms, speed),
  );
}
