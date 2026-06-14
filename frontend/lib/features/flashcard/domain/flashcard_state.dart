/// Immutable state model for the flashcard quiz session.
///
/// Tracks the full lifecycle of a card-matching quiz: a queue of [TileModel] cards,
/// the user's progress through the queue, correctness tallies, answer-animation
/// flags, and the mnemonic-reveal toggle.  Designed to be updated exclusively via
/// [FlashcardQuizState.copyWith] so callers always receive a fresh snapshot.
import '../../../shared/models/tile_model.dart';

/// The complete mutable-free state of a single flashcard quiz run.
///
/// Each instance captures a fixed point in time: which card is active, how many
/// answers were right or wrong, whether a mnemonic helper is visible, and the
/// pre-shuffled [options] offered for the current card.  No public setters exist;
/// consumers call [copyWith] to derive the next frame.
class FlashcardQuizState {
  /// The ordered list of cards remaining in the quiz.
  final List<TileModel> queue;

  /// Zero-based index of the card currently presented to the user.
  final int currentIndex;

  /// Running tally of cards answered correctly so far.
  final int correctCount;

  /// Running tally of cards answered incorrectly so far.
  final int wrongCount;

  /// Whether the UI is waiting for the user to pick an answer for the current card.
  final bool isAnswering;

  /// Whether the mnemonic helper panel is currently expanded.
  final bool isShowingMnemonic;

  /// ID of the most-recently correctly-answered card, if any.
  ///
  /// Used by the UI to drive brief success feedback without needing
  /// an extra timer-based flag.
  final String? lastCorrectId;

  /// ID of the most-recently incorrectly-answered card, if any.
  ///
  /// Paired with [lastCorrectId] to drive error-feedback animations.
  final String? lastWrongId;

  /// The card suite (category) the quiz is currently scoped to (`'all'` for
  /// every available card).
  final String suite;
  /// Pre-shuffled options for the current card (4 items).
  final List<TileModel> options;

  /// Creates a const snapshot of the quiz state.
  ///
  /// Every parameter is optional with a sensible default so callers can
  /// construct the initial pre-quiz state as `FlashcardQuizState()`.
  const FlashcardQuizState({
    this.queue = const [],
    this.currentIndex = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.isAnswering = false,
    this.isShowingMnemonic = false,
    this.lastCorrectId,
    this.lastWrongId,
    this.suite = 'all',
    this.options = const [],
  });

  /// The card the user is currently answering, or `null` when the quiz is
  /// finished or the queue is empty.
  TileModel? get currentTile =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  /// Total number of cards in the quiz queue.
  int get totalCount => queue.length;

  /// Whether every card in the queue has been presented.
  bool get isFinished => currentIndex >= totalCount;

  /// Progress through the queue expressed as a fraction in [0, 1].
  double get progress => totalCount > 0 ? currentIndex / totalCount : 0;

  /// Returns a new [FlashcardQuizState] with the given fields replaced.
  ///
  /// Every parameter is optional; omitted parameters keep their current value.
  /// This is the only way to mutate quiz state — no public setters exist.
  FlashcardQuizState copyWith({
    List<TileModel>? queue,
    int? currentIndex,
    int? correctCount,
    int? wrongCount,
    bool? isAnswering,
    bool? isShowingMnemonic,
    String? lastCorrectId,
    String? lastWrongId,
    String? suite,
    List<TileModel>? options,
  }) {
    return FlashcardQuizState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      isAnswering: isAnswering ?? this.isAnswering,
      isShowingMnemonic: isShowingMnemonic ?? this.isShowingMnemonic,
      lastCorrectId: lastCorrectId,
      lastWrongId: lastWrongId,
      suite: suite ?? this.suite,
      options: options ?? this.options,
    );
  }
}
