import 'dart:math';

import 'defense_catalog.dart';
import 'defense_trainer.dart';

/// The only valid phases in a defense-training session.
enum DefenseTrainingPhase { intro, answering, revealed, completed }

/// One immutable answer recorded by the session.
class DefenseTrainingAnswer {
  const DefenseTrainingAnswer({
    required this.question,
    required this.selectedChoice,
    required this.bestChoice,
  });

  factory DefenseTrainingAnswer.fromEvaluation(
    DefenseAnswerEvaluation evaluation,
  ) =>
      DefenseTrainingAnswer(
        question: evaluation.question,
        selectedChoice: evaluation.selectedChoice,
        bestChoice: evaluation.bestChoice,
      );

  final DefenseQuestion question;
  final DefenseChoice selectedChoice;
  final DefenseChoice bestChoice;

  bool get isCorrect => selectedChoice.id == bestChoice.id;
}

/// Per-topic result shown in the end-of-session breakdown.
class DefenseTopicSummary {
  const DefenseTopicSummary({
    required this.topic,
    required this.correct,
    required this.incorrect,
  });

  final DefenseTopic topic;
  final int correct;
  final int incorrect;

  int get attempts => correct + incorrect;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

/// Immutable state machine for one normal or precision-review session.
class DefenseTrainingState {
  DefenseTrainingState._({
    required List<DefenseQuestion> questions,
    required this.currentIndex,
    required this.phase,
    required List<DefenseTrainingAnswer> answers,
    required this.seed,
    required this.reviewQuestionId,
  })  : questions = List<DefenseQuestion>.unmodifiable(questions),
        answers = List<DefenseTrainingAnswer>.unmodifiable(answers);

  /// Builds a ten-question session with two reproducibly sampled questions
  /// from every taxonomy topic, then reproducibly shuffles questions/options.
  factory DefenseTrainingState.standard({
    required int seed,
    Iterable<DefenseQuestion>? catalog,
    int? questionLimit,
  }) {
    final count = questionLimit ?? standardQuestionCount;
    if (count < 1 || count > standardQuestionCount) {
      throw ArgumentError.value(
        questionLimit,
        'questionLimit',
        'Must be between 1 and $standardQuestionCount.',
      );
    }
    final source = List<DefenseQuestion>.of(
      catalog ?? DefenseQuestionCatalog.questions,
    );
    final random = Random(seed);
    final selected = <DefenseQuestion>[];

    for (final topic in DefenseTopic.values) {
      final candidates = source
          .where((question) => question.topic == topic)
          .toList(growable: true)
        ..shuffle(random);
      if (candidates.length < questionsPerTopic) {
        throw StateError(
          'Defense catalog needs at least $questionsPerTopic questions for '
          '${topic.name}.',
        );
      }
      selected.addAll(candidates.take(questionsPerTopic));
    }

    selected.shuffle(random);
    final shuffled = [
      for (final question in selected)
        _copyWithShuffledChoices(question, random),
    ];
    return DefenseTrainingState._(
      questions: shuffled.take(count).toList(growable: false),
      currentIndex: 0,
      phase: DefenseTrainingPhase.intro,
      answers: const [],
      seed: seed,
      reviewQuestionId: null,
    );
  }

  /// Builds a short, reproducible two-question session for one weak topic.
  factory DefenseTrainingState.focused({
    required DefenseTopic topic,
    required int seed,
    Iterable<DefenseQuestion>? catalog,
    int? questionLimit,
  }) {
    final count = questionLimit ?? questionsPerTopic;
    if (count < 1 || count > questionsPerTopic) {
      throw ArgumentError.value(
        questionLimit,
        'questionLimit',
        'Must be between 1 and $questionsPerTopic.',
      );
    }
    final random = Random(seed);
    final candidates = (catalog ?? DefenseQuestionCatalog.questions)
        .where((question) => question.topic == topic)
        .toList(growable: true)
      ..shuffle(random);
    if (candidates.length < questionsPerTopic) {
      throw StateError(
        'Defense catalog needs at least $questionsPerTopic questions for '
        '${topic.name}.',
      );
    }
    final questions = [
      for (final question in candidates.take(count))
        _copyWithShuffledChoices(question, random),
    ];
    return DefenseTrainingState._(
      questions: questions,
      currentIndex: 0,
      phase: DefenseTrainingPhase.intro,
      answers: const [],
      seed: seed,
      reviewQuestionId: null,
    );
  }

  /// Builds an exact one-question review and deliberately skips the intro.
  factory DefenseTrainingState.review({
    required String reviewQuestionId,
    required int seed,
    Iterable<DefenseQuestion>? catalog,
  }) {
    final matches = (catalog ?? DefenseQuestionCatalog.questions)
        .where((question) => question.id == reviewQuestionId)
        .toList();
    if (matches.length != 1) {
      throw ArgumentError.value(
        reviewQuestionId,
        'reviewQuestionId',
      );
    }
    return DefenseTrainingState._(
      questions: [_copyWithShuffledChoices(matches.single, Random(seed))],
      currentIndex: 0,
      phase: DefenseTrainingPhase.answering,
      answers: const [],
      seed: seed,
      reviewQuestionId: reviewQuestionId,
    );
  }

  static const questionsPerTopic = 2;
  static const standardQuestionCount = 10;

  final List<DefenseQuestion> questions;
  final int currentIndex;
  final DefenseTrainingPhase phase;
  final List<DefenseTrainingAnswer> answers;
  final int seed;
  final String? reviewQuestionId;

  bool get isReview => reviewQuestionId != null;
  int get totalCount => questions.length;
  int get answeredCount => answers.length;
  int get correctCount => answers.where((answer) => answer.isCorrect).length;
  int get incorrectCount => answeredCount - correctCount;
  double get accuracy => answeredCount == 0 ? 0 : correctCount / answeredCount;

  DefenseQuestion? get currentQuestion {
    if (phase == DefenseTrainingPhase.intro ||
        phase == DefenseTrainingPhase.completed ||
        currentIndex < 0 ||
        currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  DefenseTrainingAnswer? get currentAnswer {
    final question = currentQuestion;
    if (question == null) return null;
    for (final answer in answers.reversed) {
      if (answer.question.id == question.id) return answer;
    }
    return null;
  }

  Map<DefenseTopic, DefenseTopicSummary> get topicSummaries {
    final result = <DefenseTopic, DefenseTopicSummary>{};
    for (final topic in DefenseTopic.values) {
      final topicAnswers = answers
          .where((answer) => answer.question.topic == topic)
          .toList(growable: false);
      if (topicAnswers.isEmpty) continue;
      final correct = topicAnswers.where((answer) => answer.isCorrect).length;
      result[topic] = DefenseTopicSummary(
        topic: topic,
        correct: correct,
        incorrect: topicAnswers.length - correct,
      );
    }
    return Map<DefenseTopic, DefenseTopicSummary>.unmodifiable(result);
  }

  DefenseTrainingState begin() {
    if (phase != DefenseTrainingPhase.intro) return this;
    return _copyWith(phase: DefenseTrainingPhase.answering);
  }

  /// Records at most one answer for the current question.
  ///
  /// Calls outside [DefenseTrainingPhase.answering] are harmless no-ops, so a
  /// duplicate tap or animation callback cannot increment session totals.
  DefenseTrainingState submit(String selectedChoiceId) {
    if (phase != DefenseTrainingPhase.answering) return this;
    final question = currentQuestion;
    if (question == null || currentAnswer != null) return this;
    final evaluation = DefenseTrainerEvaluator.evaluate(
      question: question,
      selectedChoiceId: selectedChoiceId,
    );
    return _copyWith(
      phase: DefenseTrainingPhase.revealed,
      answers: [
        ...answers,
        DefenseTrainingAnswer.fromEvaluation(evaluation),
      ],
    );
  }

  DefenseTrainingState next() {
    if (phase != DefenseTrainingPhase.revealed) return this;
    final nextIndex = currentIndex + 1;
    if (nextIndex >= questions.length) {
      return _copyWith(phase: DefenseTrainingPhase.completed);
    }
    return _copyWith(
      currentIndex: nextIndex,
      phase: DefenseTrainingPhase.answering,
    );
  }

  DefenseTrainingState _copyWith({
    int? currentIndex,
    DefenseTrainingPhase? phase,
    List<DefenseTrainingAnswer>? answers,
  }) =>
      DefenseTrainingState._(
        questions: questions,
        currentIndex: currentIndex ?? this.currentIndex,
        phase: phase ?? this.phase,
        answers: answers ?? this.answers,
        seed: seed,
        reviewQuestionId: reviewQuestionId,
      );
}

DefenseQuestion _copyWithShuffledChoices(
  DefenseQuestion question,
  Random random,
) {
  final choices = List<DefenseChoice>.of(question.choices)..shuffle(random);
  return DefenseQuestion(
    id: question.id,
    topic: question.topic,
    targetSeat: question.targetSeat,
    discardsBySeat: question.discardsBySeat,
    additionalPublicVisibleCounts: question.additionalPublicVisibleCounts,
    choices: choices,
    bestChoiceId: question.bestChoiceId,
  );
}
