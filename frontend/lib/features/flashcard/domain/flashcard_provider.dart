import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/data/tile_repository.dart';
import '../../../core/providers/tile_data_provider.dart';
import 'flashcard_state.dart';

final flashcardQuizProvider =
    StateNotifierProvider.autoDispose<FlashcardQuizNotifier, FlashcardQuizState>(
        (ref) => FlashcardQuizNotifier(ref.read(tileRepositoryProvider)));

class FlashcardQuizNotifier extends StateNotifier<FlashcardQuizState> {
  final TileRepository _repo;
  List<TileModel> _allTiles = [];

  FlashcardQuizNotifier(this._repo) : super(const FlashcardQuizState());

  /// Pre-shuffle options for the given tile so they don't flicker on rebuild.
  List<TileModel> _buildOptions(TileModel correct) {
    final distractors = _repo.getDistractors(correct, _allTiles, 3);
    final opts = [...distractors, correct]..shuffle();
    return opts;
  }

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

    final options = queue.isNotEmpty ? _buildOptions(queue[0]) : <TileModel>[];

    state = FlashcardQuizState(
      queue: queue,
      currentIndex: 0,
      suite: suite,
      options: options,
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
    final nextIdx = state.currentIndex + 1;
    if (nextIdx >= state.totalCount) {
      state = state.copyWith(currentIndex: nextIdx);
    } else {
      final nextOptions = _buildOptions(state.queue[nextIdx]);
      state = state.copyWith(
        currentIndex: nextIdx,
        isAnswering: false,
        isShowingMnemonic: false,
        lastCorrectId: null,
        lastWrongId: null,
        options: nextOptions,
      );
    }
  }

  void restart() {
    final shuffled = List<TileModel>.from(state.queue)..shuffle();
    final options =
        shuffled.isNotEmpty ? _buildOptions(shuffled[0]) : <TileModel>[];
    state = FlashcardQuizState(
      queue: shuffled,
      suite: state.suite,
      options: options,
    );
  }
}
