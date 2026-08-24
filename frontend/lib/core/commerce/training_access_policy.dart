import 'package:flutter/foundation.dart';

/// Immutable decision model shared by all training gates.
///
/// A release with limits disabled is unlimited for everyone. When limits are
/// enabled, Premium users remain unlimited and free users use the heart gate.
@immutable
class TrainingAccessPolicy {
  const TrainingAccessPolicy({
    required this.limitsEnabled,
    required this.isPremium,
  });

  final bool limitsEnabled;
  final bool isPremium;

  bool get hasUnlimitedTraining => !limitsEnabled || isPremium;

  bool get shouldConsumeHearts => limitsEnabled && !isPremium;

  bool canPlay({required bool hasHearts}) => hasUnlimitedTraining || hasHearts;

  double maxDifficulty({double freeLimit = 800.0}) =>
      hasUnlimitedTraining ? double.infinity : freeLimit;
}
