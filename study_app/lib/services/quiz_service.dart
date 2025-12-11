import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../models/quiz.dart';
import '../models/quiz_question.dart';

class QuizService {
  Future<List<Quiz>> getQuizzesByTopic(int topicId) async {
    return await isar.collection<Quiz>().filter().topicIdEqualTo(topicId).findAll();
  }

  Future<int> createQuiz({
    required int topicId,
    required String title,
    String? description,
    bool immediateFeedback = true,
    bool countdown = false,
    int timeLimitSeconds = 0,
  }) async {
    final quiz = Quiz()
      ..topicId = topicId
      ..title = title
      ..description = description
      ..immediateFeedback = immediateFeedback
      ..countdown = countdown
      ..timeLimitSeconds = timeLimitSeconds;
    return await isar.writeTxn(() async => isar.collection<Quiz>().put(quiz));
  }

  Future<void> updateQuiz(Quiz quiz) async {
    await isar.writeTxn(() async => isar.collection<Quiz>().put(quiz));
  }

  Future<void> deleteQuiz(int quizId) async {
    await isar.writeTxn(() async {
      await isar.collection<QuizQuestion>().filter().quizIdEqualTo(quizId).deleteAll();
      await isar.collection<Quiz>().delete(quizId);
    });
  }

  Future<List<QuizQuestion>> getQuestions(int quizId) async {
    return await isar.collection<QuizQuestion>().filter().quizIdEqualTo(quizId).findAll();
  }

  Future<int> addQuestion({
    required int quizId,
    required String prompt,
    QuizQuestionType type = QuizQuestionType.text,
    String? answer,
    List<String>? options,
    int correctIndex = -1,
    String? imagePath,
    String? audioPath,
    String? videoPath,
  }) async {
    final q = QuizQuestion()
      ..quizId = quizId
      ..prompt = prompt
      ..type = type
      ..answer = answer
      ..options = options?.join('\n')
      ..correctIndex = correctIndex
      ..imagePath = imagePath
      ..audioPath = audioPath
      ..videoPath = videoPath;
    return await isar.writeTxn(() async => isar.quizQuestions.put(q));
  }

  Future<void> updateQuestion(QuizQuestion question) async {
    await isar.writeTxn(() async => isar.collection<QuizQuestion>().put(question));
  }

  Future<void> deleteQuestion(int id) async {
    await isar.writeTxn(() async => isar.collection<QuizQuestion>().delete(id));
  }

  Future<Map<String, dynamic>> exportQuiz(int quizId) async {
    final quiz = await isar.collection<Quiz>().get(quizId);
    if (quiz == null) return {};
    final questions = await getQuestions(quizId);

    final serialized = <Map<String, dynamic>>[];
    for (final q in questions) {
      serialized.add(await _serializeQuestion(q));
    }

    return {
      'version': 1,
      'quiz': {
        'title': quiz.title,
        'description': quiz.description,
        'immediateFeedback': quiz.immediateFeedback,
        'countdown': quiz.countdown,
        'timeLimitSeconds': quiz.timeLimitSeconds,
        'topicId': quiz.topicId,
      },
      'questions': serialized,
    };
  }

  Future<int> importQuiz(int topicId, Map<String, dynamic> data) async {
    final qz = data['quiz'] as Map<String, dynamic>? ?? {};
    final title = (qz['title'] as String?) ?? 'Imported Quiz';
    final description = qz['description'] as String?;
    final immediate = qz['immediateFeedback'] as bool? ?? true;
    final countdown = qz['countdown'] as bool? ?? false;
    final limit = qz['timeLimitSeconds'] as int? ?? 0;

    final quizId = await createQuiz(
      topicId: topicId,
      title: title,
      description: description,
      immediateFeedback: immediate,
      countdown: countdown,
      timeLimitSeconds: limit,
    );

    final questions = data['questions'] as List<dynamic>? ?? [];
    for (final raw in questions) {
      if (raw is! Map<String, dynamic>) continue;
      final restored = await _deserializeQuestion(raw, quizId);
      await isar.writeTxn(() async => isar.quizQuestions.put(restored));
    }
    return quizId;
  }

  Future<Map<String, dynamic>> _serializeQuestion(QuizQuestion q) async {
    Future<Map<String, String?>> encodeFile(String? path) async {
      if (path == null) return {'data': null, 'name': null};
      final file = File(path);
      if (!await file.exists()) return {'data': null, 'name': null};
      return {
        'data': base64Encode(await file.readAsBytes()),
        'name': file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : null,
      };
    }

    final img = await encodeFile(q.imagePath);
    final aud = await encodeFile(q.audioPath);
    final vid = await encodeFile(q.videoPath);

    return {
      'prompt': q.prompt,
      'answer': q.answer,
      'options': q.options?.split('\n'),
      'correctIndex': q.correctIndex,
      'type': q.type.name,
      'image': img,
      'audio': aud,
      'video': vid,
    };
  }

  Future<QuizQuestion> _deserializeQuestion(Map<String, dynamic> raw, int quizId) async {
    final q = QuizQuestion()
      ..quizId = quizId
      ..prompt = (raw['prompt'] ?? '').toString()
      ..answer = raw['answer'] as String?
      ..options = (raw['options'] as List<dynamic>?)?.map((e) => e.toString()).join('\n')
      ..correctIndex = (raw['correctIndex'] as int?) ?? -1
      ..type = QuizQuestionType.values.firstWhere(
        (e) => e.name == raw['type'],
        orElse: () => QuizQuestionType.text,
      );

    q.imagePath = await _restoreFile(raw['image']);
    q.audioPath = await _restoreFile(raw['audio']);
    q.videoPath = await _restoreFile(raw['video']);
    return q;
  }

  Future<String?> _restoreFile(dynamic blob) async {
    if (blob is! Map) return null;
    final data = blob['data'] as String?;
    final name = (blob['name'] as String?) ?? 'media';
    if (data == null || data.isEmpty) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${dir.path}/quiz_media');
      if (!mediaDir.existsSync()) {
        await mediaDir.create(recursive: true);
      }
      final file = File('${mediaDir.path}/$name');
      await file.writeAsBytes(base64Decode(data));
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

final quizService = QuizService();
