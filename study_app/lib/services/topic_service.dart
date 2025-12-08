import 'package:isar/isar.dart';

import '../main.dart';
import '../models/topic.dart';


class TopicService {
  Future<List<Topic>> getTopicsForSubject(int subjectId) async {
    return await isar.topics
        .filter()
        .subjectIdEqualTo(subjectId)
        .sortByName()
        .findAll();
  }

  Future<void> addTopic(int subjectId, String name) async {
    final topic = Topic()
      ..name = name
      ..subjectId = subjectId;

    await isar.writeTxn(() async {
      await isar.topics.put(topic);
    });
  }

  Future<void> deleteTopic(int id) async {
    await isar.writeTxn(() async {
      await isar.topics.delete(id);
    });
  }

  Future<void> updateTopic(Topic topic) async {
    await isar.writeTxn(() async {
      await isar.topics.put(topic);
    });
  }
}

final topicService = TopicService();
