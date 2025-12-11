import 'package:isar/isar.dart';

part 'quiz_question.g.dart';

enum QuizQuestionType {
  text, // open-ended
  multipleChoice,
}

@collection
class QuizQuestion {
  Id id = Isar.autoIncrement;

  @Index()
  late int quizId;

  @Index(caseSensitive: false)
  late String prompt;

  /// For text: the expected answer. For MC: the correct option text.
  String? answer;

  /// Serialized options for MC (stored as a newline-delimited string).
  String? options;

  int correctIndex = -1;

  @enumerated
  QuizQuestionType type = QuizQuestionType.text;

  String? imagePath;
  String? audioPath;
  String? videoPath;
}
