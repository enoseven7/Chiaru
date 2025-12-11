import 'package:isar/isar.dart';

part 'quiz.g.dart';

@collection
class Quiz {
  Id id = Isar.autoIncrement;

  @Index()
  late int topicId;

  @Index(caseSensitive: false)
  late String title;

  String? description;

  /// Whether to show correctness immediately after each question.
  bool immediateFeedback = true;

  /// If true, use countdown; otherwise, count up.
  bool countdown = false;

  /// Seconds for countdown (only if countdown is true). 0 = no limit.
  int timeLimitSeconds = 0;
}
