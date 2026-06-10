import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// True when running in Flutter test environment.
bool get isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

/// Returns zero duration in tests, or duration * speedFactor otherwise.
Duration safeAnimDuration(int ms, double speedFactor) {
  if (isTestEnvironment) return Duration.zero;
  final s = speedFactor.clamp(0.0, 1.0);
  if (s == 0.0) return Duration.zero;
  return Duration(milliseconds: (ms * s).round());
}

/// Creates an AnimationController with test-safe duration.
AnimationController safeController(TickerProvider vsync, int ms, double speed) {
  return AnimationController(
    vsync: vsync,
    duration: safeAnimDuration(ms, speed),
  );
}
