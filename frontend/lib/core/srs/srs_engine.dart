/// SM-2 spaced repetition algorithm.
/// Matches backend app/domain/services/srs_service.py exactly.
class SrsEngine {
  /// quality: 0-5 (0=blackout, 3=hesitant, 5=perfect)
  /// Returns (newEf, newReps, newInterval)
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
