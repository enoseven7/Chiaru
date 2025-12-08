import 'package:isar/isar.dart';
import '../main.dart';
import '../models/subject.dart';

class SubjectService {
  /// Returns all subjects sorted alphabetically.
  Future<List<Subject>> getSubjects() async {
    return await isar.subjects.where().sortByName().findAll();
  }

  /// Adds a new subject.
  Future<void> addSubject(String name) async {
    final subject = Subject()..name = name;

    await isar.writeTxn(() async {
      await isar.subjects.put(subject);
    });
  }

  /// Deletes a subject by id.
  Future<void> deleteSubject(int id) async {
    await isar.writeTxn(() async {
      await isar.subjects.delete(id);
    });
  }

  /// Updates an existing subject.
  Future<void> updateSubject(Subject subject) async {
    await isar.writeTxn(() async {
      await isar.subjects.put(subject);
    });
  }
}

final subjectService = SubjectService(); // Global instance
