/// SM-2 spaced repetition algorithm for TileZhan.
///
/// This library provides the core SRS calculation used by the flashcard
/// review system. It is stateless by design — the caller owns all
/// per-card state and passes it in on each invocation, making the engine
/// trivially testable and backend-syncable.

/// SM-2 (SuperMemo 2) spaced repetition algorithm engine.
///
/// Implements the classic SM-2 algorithm for computing review schedules
/// based on ease factor (EF), repetition count, and recall quality.
/// The output tuple — (newEf, newReps, newInterval) — drives the
/// front-end SRS card queue and is persisted via the backend API.
///
/// Mirrors the backend implementation at
/// `app/domain/services/srs_service.py` exactly.
class SrsEngine {
  /// Compute the next SRS state from a single review attempt.
  ///
  /// [ef] — current ease factor (typically starts at 2.5).
  /// [reps] — consecutive successful reviews before this attempt.
  /// [interval] — current interval in days.
  /// [quality] — self-assessed recall quality, 0–5:
  ///   * 0 — complete blackout
  ///   * 1 — wrong answer; correct one remembered upon seeing it
  ///   * 2 — wrong answer; correct one seemed easy to recall
  ///   * 3 — correct answer, recalled with serious difficulty
  ///   * 4 — correct answer after a moment of hesitation
  ///   * 5 — perfect, effortless recall
  ///
  /// Returns `(newEf, newReps, newInterval)` where:
  ///   * `newEf` — updated ease factor (clamped to >= 1.3).
  ///   * `newReps` — reset to 0 on failure, otherwise incremented.
  ///   * `newInterval` — next review interval in days.
  static (double, int, int) calculate(
    double ef, int reps, int interval, int quality,
  ) {
    if (quality < 3) {
      // Failed recall — reset reps, keep EF
      return (ef, 0, 1);
    }
    // Successful
    double newEf = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    newEf = newEf < 1.3 ? 1.3 : newEf;
    final newReps = reps + 1;
    int newInterval;
    if (newReps == 1) {
      newInterval = 1;
    } else if (newReps == 2) {
      newInterval = 6;
    } else {
      newInterval = (interval * newEf).round();
    }
    return (newEf, newReps, newInterval);
  }
}
