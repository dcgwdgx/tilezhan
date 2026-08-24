import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/static_yaku_quiz_repository.dart';
import 'yaku_quiz_question.dart';
import 'yaku_quiz_repository.dart';
import 'yaku_quiz_state.dart';

typedef YakuQuizRandomFactory = Random Function(int seed);

Random _seededRandom(int seed) => Random(seed);

final yakuQuizRepositoryProvider = Provider<YakuQuizRepository>(
  (ref) => const StaticYakuQuizRepository(),
);

final yakuQuizRandomFactoryProvider = Provider<YakuQuizRandomFactory>(
  (ref) => _seededRandom,
);

final yakuQuizProvider =
    StateNotifierProvider.autoDispose<YakuQuizNotifier, YakuQuizState>((ref) {
  return YakuQuizNotifier(
    ref.watch(yakuQuizRepositoryProvider),
    randomFactory: ref.watch(yakuQuizRandomFactoryProvider),
  );
});

class YakuQuizNotifier extends StateNotifier<YakuQuizState> {
  final YakuQuizRepository _repository;
  final YakuQuizRandomFactory _randomFactory;

  YakuQuizNotifier(
    this._repository, {
    YakuQuizRandomFactory? randomFactory,
  })  : _randomFactory = randomFactory ?? _seededRandom,
        super(const YakuQuizState());

  /// Starts a deterministic quiz, or one exact question in review mode.
  void start({
    int questionCount = 10,
    int seed = 0,
    String? reviewQuestionId,
  }) {
    final random = _randomFactory(seed);
    late final List<YakuQuizQuestion> selectedQuestions;

    if (reviewQuestionId != null) {
      final reviewQuestion = _repository.findById(reviewQuestionId);
      if (reviewQuestion == null) {
        throw ArgumentError.value(reviewQuestionId, 'reviewQuestionId');
      }
      selectedQuestions = [reviewQuestion];
    } else {
      if (questionCount <= 0) {
        throw ArgumentError.value(questionCount, 'questionCount');
      }
      selectedQuestions = _selectStratified(
        _repository.questions,
        questionCount,
        random,
      );
    }

    if (selectedQuestions.isEmpty) {
      state = const YakuQuizState();
      return;
    }

    final selected = selectedQuestions
        .map((question) => _withShuffledOptions(question, random))
        .toList(growable: false);

    state = YakuQuizState(
      questions: List<YakuQuizQuestion>.unmodifiable(selected),
      phase: YakuQuizPhase.answering,
    );
  }

  List<YakuQuizQuestion> _selectStratified(
    List<YakuQuizQuestion> catalog,
    int questionCount,
    Random random,
  ) {
    final groups = <YakuQuizQuestionKind, List<YakuQuizQuestion>>{
      for (final kind in YakuQuizQuestionKind.values) kind: [],
    };
    for (final question in catalog) {
      groups[question.kind]!.add(question);
    }

    final kinds = YakuQuizQuestionKind.values
        .where((kind) => groups[kind]!.isNotEmpty)
        .toList(growable: false);
    final targetCount = min(questionCount, catalog.length);
    if (targetCount == 0) return const [];

    final allocations = <YakuQuizQuestionKind, int>{
      for (final kind in kinds) kind: 0,
    };
    var remaining = targetCount;

    if (targetCount >= kinds.length) {
      for (final kind in kinds) {
        allocations[kind] = 1;
      }
      remaining -= kinds.length;
    }

    if (remaining > 0) {
      final availableByKind = <YakuQuizQuestionKind, int>{
        for (final kind in kinds)
          kind: groups[kind]!.length - allocations[kind]!,
      };
      final totalAvailable = availableByKind.values.fold<int>(
        0,
        (sum, capacity) => sum + capacity,
      );
      final proportionalCount = remaining;
      final remainders = <({YakuQuizQuestionKind kind, int value})>[];
      var allocated = 0;

      for (final kind in kinds) {
        final available = availableByKind[kind]!;
        final numerator = proportionalCount * available;
        final share = numerator ~/ totalAvailable;
        allocations[kind] = allocations[kind]! + share;
        allocated += share;
        remainders.add((kind: kind, value: numerator % totalAvailable));
      }
      remaining -= allocated;

      remainders.sort((left, right) {
        final byRemainder = right.value.compareTo(left.value);
        return byRemainder != 0
            ? byRemainder
            : left.kind.index.compareTo(right.kind.index);
      });
      for (final entry in remainders) {
        if (remaining == 0) break;
        if (allocations[entry.kind]! < groups[entry.kind]!.length) {
          allocations[entry.kind] = allocations[entry.kind]! + 1;
          remaining--;
        }
      }
    }

    final selected = <YakuQuizQuestion>[];
    for (final kind in kinds) {
      groups[kind]!.shuffle(random);
      selected.addAll(groups[kind]!.take(allocations[kind]!));
    }
    selected.shuffle(random);
    return selected;
  }

  YakuQuizQuestion _withShuffledOptions(
    YakuQuizQuestion question,
    Random random,
  ) {
    final options = List<YakuQuizAnswer>.of(question.options)..shuffle(random);
    return YakuQuizQuestion(
      id: question.id,
      kind: question.kind,
      promptKey: question.promptKey,
      explanationKey: question.explanationKey,
      correctAnswer: question.correctAnswer,
      options: List<YakuQuizAnswer>.unmodifiable(options),
    );
  }

  /// Records at most one answer for the current question.
  YakuQuizSubmission submit(YakuQuizAnswer answer) {
    final question = state.currentQuestion;
    if (state.phase != YakuQuizPhase.answering || question == null) {
      return YakuQuizSubmission(
        wasRecorded: false,
        isCorrect: state.lastAnswerWasCorrect ?? false,
      );
    }
    if (!question.options.contains(answer)) {
      throw ArgumentError.value(answer, 'answer');
    }

    final isCorrect = answer == question.correctAnswer;
    state = YakuQuizState(
      questions: state.questions,
      currentIndex: state.currentIndex,
      phase: YakuQuizPhase.revealed,
      answeredCount: state.answeredCount + 1,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
      selectedAnswer: answer,
      lastAnswerWasCorrect: isCorrect,
    );
    return YakuQuizSubmission(wasRecorded: true, isCorrect: isCorrect);
  }

  /// Advances once from a revealed question; repeated taps are ignored.
  bool next() {
    if (state.phase != YakuQuizPhase.revealed) return false;

    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) {
      state = YakuQuizState(
        questions: state.questions,
        currentIndex: state.questions.length,
        phase: YakuQuizPhase.completed,
        answeredCount: state.answeredCount,
        correctCount: state.correctCount,
      );
      return true;
    }

    state = YakuQuizState(
      questions: state.questions,
      currentIndex: nextIndex,
      phase: YakuQuizPhase.answering,
      answeredCount: state.answeredCount,
      correctCount: state.correctCount,
    );
    return true;
  }
}
