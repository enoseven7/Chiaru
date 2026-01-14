import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  late int topicId;   // Link to topic

  @Index(caseSensitive: false)
  late String content;

  String title = 'Untitled Note';  // Default title for notes
}
