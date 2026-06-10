import '../../../shared/models/tile_model.dart';

class FlashcardQuizState {
  final List<TileModel> queue;
  final int currentIndex;
  final int correctCount;
  final int wrongCount;
  final bool isAnswering;
  final bool isShowingMnemonic;
  final String? lastCorrectId;
  final String? lastWrongId;
  final String suite;
  /// Pre-shuffled options for the current card (4 items).
  final List<TileModel> options;

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

  TileModel? get currentTile =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  int get totalCount => queue.length;
  bool get isFinished => currentIndex >= totalCount;
  double get progress => totalCount > 0 ? currentIndex / totalCount : 0;

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
