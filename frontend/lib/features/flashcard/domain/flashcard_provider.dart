import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/data/tile_repository.dart';
import 'flashcard_state.dart';

final flashcardQuizProvider =
    StateNotifierProvider.autoDispose<FlashcardQuizNotifier, FlashcardQuizState>(
        (ref) => FlashcardQuizNotifier(ref.read(tileRepositoryProvider)));

class FlashcardQuizNotifier extends StateNotifier<FlashcardQuizState> {
  final TileRepository _repo;
  List<TileModel> _allTiles = [];

  FlashcardQuizNotifier(this._repo) : super(const FlashcardQuizState());

  Future<void> initQuiz({String suite = 'all', int count = 10}) async {
    _allTiles = await _repo.loadAllTiles();
    final filtered = suite == 'all'
        ? _allTiles
        : suite == 'honor'
            ? _allTiles
                .where((t) => t.suit == TileSuit.wind || t.suit == TileSuit.dragon)
                .toList()
            : _allTiles.where((t) => t.suit.name == suite).toList();

    final shuffled = List<TileModel>.from(filtered)..shuffle();
    final queue = shuffled.take(min(count, shuffled.length)).toList();

    state = FlashcardQuizState(
      queue: queue,
      currentIndex: 0,
      suite: suite,
    );
  }

  List<TileModel> getDistractors(TileModel correct) {
    return _repo.getDistractors(correct, _allTiles, 3);
  }

  void submitAnswer(bool isCorrect) {
    if (state.isAnswering) return;
    state = state.copyWith(
      isAnswering: true,
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      wrongCount: isCorrect ? state.wrongCount : state.wrongCount + 1,
      lastCorrectId: isCorrect ? state.currentTile?.id : null,
      lastWrongId: isCorrect ? null : state.currentTile?.id,
    );
  }

  void showMnemonic() {
    if (!state.isAnswering) return;
    state = state.copyWith(isShowingMnemonic: true);
  }

  void hideMnemonic() {
    state = state.copyWith(isShowingMnemonic: false);
  }

  void nextCard() {
    if (state.currentIndex + 1 >= state.totalCount) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isAnswering: false,
        isShowingMnemonic: false,
        lastCorrectId: null,
        lastWrongId: null,
      );
    }
  }

  void restart() {
    final shuffled = List<TileModel>.from(state.queue)..shuffle();
    state = FlashcardQuizState(
      queue: shuffled,
      suite: state.suite,
    );
  }
}
