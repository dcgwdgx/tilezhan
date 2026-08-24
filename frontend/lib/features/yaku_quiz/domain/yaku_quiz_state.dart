import 'yaku_quiz_question.dart';

enum YakuQuizPhase { answering, revealed, completed }

class YakuQuizState {
  final List<YakuQuizQuestion> questions;
  final int currentIndex;
  final YakuQuizPhase phase;
  final int answeredCount;
  final int correctCount;
  final YakuQuizAnswer? selectedAnswer;
  final bool? lastAnswerWasCorrect;

  const YakuQuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.phase = YakuQuizPhase.completed,
    this.answeredCount = 0,
    this.correctCount = 0,
    this.selectedAnswer,
    this.lastAnswerWasCorrect,
  });

  YakuQuizQuestion? get currentQuestion =>
      phase != YakuQuizPhase.completed && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  int get totalCount => questions.length;

  int get wrongCount => answeredCount - correctCount;

  double get accuracy => answeredCount == 0 ? 0 : correctCount / answeredCount;
}

class YakuQuizSubmission {
  final bool wasRecorded;
  final bool isCorrect;

  const YakuQuizSubmission({
    required this.wasRecorded,
    required this.isCorrect,
  });
}
