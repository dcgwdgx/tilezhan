import 'yaku_quiz_question.dart';

abstract interface class YakuQuizRepository {
  List<YakuQuizQuestion> get questions;

  YakuQuizQuestion? findById(String id);
}
