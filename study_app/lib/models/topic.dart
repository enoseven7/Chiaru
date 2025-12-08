import 'package:isar/isar.dart';

part 'topic.g.dart';

@collection
class Topic {
  Id id = Isar.autoIncrement;

  late int subjectId; // Link to subject
  late String name;
}
