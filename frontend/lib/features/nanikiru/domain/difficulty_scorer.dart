/// Difficulty scoring system for Nanikiru puzzles.
///
/// Evaluates every puzzle on 6 orthogonal dimensions (shanten distance, valid
/// discard count, ukeire complexity, trap attraction, yaku recognition, and
/// time pressure), computes a weighted sum, and maps it to the 800–1600
/// Puzzle Rating scale defined in PRD §B1.3.
///
/// The rating is used both for sorting the puzzle library and for matching
/// puzzles to a player's current ELO band via [targetRange].
import 'package:tilezhan/shared/models/puzzle_model.dart';

/// 6-dimensional Puzzle Rating calculator per PRD §B1.3.
///
/// ## Formula
/// Puzzle_Rating = 800 + Σ(dimension_score × weight × 400)
///
/// ## Dimensions (weights in [_weights])
/// - **shanten** (0.25): higher shanten number = further from tenpai = harder.
/// - **validDiscards** (0.20): fewer correct discard options = harder.
/// - **ukeireComplexity** (0.20): more tile types that improve the hand = harder
///   to identify the optimal line.
/// - **trapAttraction** (0.15): presence of tempting-but-wrong discards.
/// - **yakuRecognition** (0.10): difficulty of spotting the winning yaku.
/// - **timePressure** (0.10): time pressure multiplier (reserved for timed mode).
class DifficultyScorer {
  /// Dimension weights (must sum to 1.0). Tune these to shift the relative
  /// contribution of each dimension to the final Puzzle Rating.
  static const _weights = {
    'shanten': 0.25,
    'validDiscards': 0.20,
    'ukeireComplexity': 0.20,
    'trapAttraction': 0.15,
    'yakuRecognition': 0.10,
    'timePressure': 0.10,
  };

  /// Score a puzzle and return its Puzzle Rating (800-1600).
  static int score(Puzzle puzzle) {
    double total = 0;

    // Shanten: higher = harder
    total += _scoreShanten(puzzle) * _weights['shanten']!;

    // Valid discards: fewer correct options = harder
    total += _scoreValidDiscards(puzzle) * _weights['validDiscards']!;

    // Ukeire complexity: more types = harder to identify
    total += _scoreUkeireComplexity(puzzle) * _weights['ukeireComplexity']!;

    // Trap: placeholder — needs real puzzle data for accurate scoring
    total += 0.5 * _weights['trapAttraction']!;

    // Yaku: placeholder — MVP doesn't track yaku
    total += 0.3 * _weights['yakuRecognition']!;

    // Time pressure: fixed for MVP (no timed mode)
    total += 0.0 * _weights['timePressure']!;

    return 800 + (total * 400).round();
  }

  /// 1-shanten=0, 2-shanten=0.5, 3+=1.0
  static double _scoreShanten(Puzzle p) {
    // Estimate shanten from ukeire count: more ukeire = closer to tenpai = easier
    if (p.ukeireCount >= 20) return 0.0;
    if (p.ukeireCount >= 12) return 0.3;
    if (p.ukeireCount >= 6) return 0.6;
    return 1.0;
  }

  /// Fewer valid discards = harder
  static double _scoreValidDiscards(Puzzle p) {
    // This is an approximation — real scoring needs full discard analysis
    if (p.ukeireCount <= 3) return 1.0;
    if (p.ukeireCount <= 6) return 0.7;
    if (p.ukeireCount <= 10) return 0.4;
    return 0.1;
  }

  /// More ukeire types = more complex
  static double _scoreUkeireComplexity(Puzzle p) {
    if (p.ukeireTypes >= 8) return 1.0;
    if (p.ukeireTypes >= 5) return 0.6;
    if (p.ukeireTypes >= 3) return 0.3;
    return 0.0;
  }

  /// Target difficulty range for user ELO level.
  static int targetRange(int userElo) {
    if (userElo < 900) return 850;
    if (userElo < 1100) return 1000;
    if (userElo < 1300) return 1200;
    return 1400;
  }
}
