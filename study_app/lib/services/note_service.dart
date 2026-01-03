import 'package:isar/isar.dart';

import '../main.dart';
import '../models/note.dart';


class NoteService {
  Future<List<Note>> getNotesForTopic(int topicId) async {
    return await isar.notes
        .filter()
        .topicIdEqualTo(topicId)
        .sortByContent()
        .findAll();
  }

  Future<int> addNote(int topicId, String content) async {
    final note = Note()
      ..topicId = topicId
      ..content = content;

    return await isar.writeTxn(() async {
      return await isar.notes.put(note);
    });
  }

  Future<void> updateNote(Note note) async {
    await isar.writeTxn(() async {
      await isar.notes.put(note);
    });
  }

  Future<void> deleteNote(int id) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
  }
}

final noteService = NoteService();
