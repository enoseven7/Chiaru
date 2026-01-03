import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';

import '../main.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../models/note.dart';
import '../models/quiz.dart';
import '../models/quiz_question.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../models/teach_settings.dart';
import '../models/topic.dart';

class ExportService {
  Future<String> exportAll() async {
    final data = await _collectData();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = _timestamp();
    final file = File('${dir.path}/study_export_$stamp.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
    return file.path;
  }

  Future<Map<String, dynamic>> _collectData() async {
    final subjects = await isar.subjects.where().anyId().build().findAll();
    final topics = await isar.topics.where().anyId().build().findAll();
    final notes = await isar.notes.where().anyId().build().findAll();
    final decks = await isar.flashcardDecks.where().anyId().build().findAll();
    final cards = await isar.flashcards.where().anyId().build().findAll();
    final quizzes = await isar.quizs.where().anyId().build().findAll();
    final questions = await isar.quizQuestions.where().anyId().build().findAll();
    final tasks = await isar.tasks.where().anyId().build().findAll();
    final teach = await isar.teachSettings.get(0);

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'subjects': subjects.map(_subjectToJson).toList(),
      'topics': topics.map(_topicToJson).toList(),
      'notes': notes.map(_noteToJson).toList(),
      'flashcardDecks': decks.map(_deckToJson).toList(),
      'flashcards': cards.map(_cardToJson).toList(),
      'quizzes': quizzes.map(_quizToJson).toList(),
      'quizQuestions': questions.map(_questionToJson).toList(),
      'tasks': tasks.map(_taskToJson).toList(),
      'teachSettings': teach == null ? null : _teachSettingsToJson(teach),
    };
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Map<String, dynamic> _subjectToJson(Subject s) => {
        'id': s.id,
        'name': s.name,
      };

  Map<String, dynamic> _topicToJson(Topic t) => {
        'id': t.id,
        'subjectId': t.subjectId,
        'name': t.name,
      };

  Map<String, dynamic> _noteToJson(Note n) => {
        'id': n.id,
        'topicId': n.topicId,
        'content': n.content,
      };

  Map<String, dynamic> _deckToJson(FlashcardDeck d) => {
        'id': d.id,
        'topicId': d.topicId,
        'name': d.name,
      };

  Map<String, dynamic> _cardToJson(Flashcard c) => {
        'id': c.id,
        'deckId': c.deckId,
        'front': c.front,
        'back': c.back,
        'lastReviewed': c.lastReviewed,
        'dueAt': c.dueAt,
        'intervalDays': c.intervalDays,
        'easeFactor': c.easeFactor,
        'repetitions': c.repetitions,
        'lapses': c.lapses,
        'imagePath': c.imagePath,
        'audioPath': c.audioPath,
        'imageOnFront': c.imageOnFront,
        'audioOnFront': c.audioOnFront,
      };

  Map<String, dynamic> _quizToJson(Quiz q) => {
        'id': q.id,
        'topicId': q.topicId,
        'title': q.title,
        'description': q.description,
        'immediateFeedback': q.immediateFeedback,
        'countdown': q.countdown,
        'timeLimitSeconds': q.timeLimitSeconds,
      };

  Map<String, dynamic> _questionToJson(QuizQuestion q) => {
        'id': q.id,
        'quizId': q.quizId,
        'prompt': q.prompt,
        'answer': q.answer,
        'options': q.options,
        'correctIndex': q.correctIndex,
        'type': q.type.name,
        'imagePath': q.imagePath,
        'audioPath': q.audioPath,
        'videoPath': q.videoPath,
      };

  Map<String, dynamic> _taskToJson(Task t) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'dueAt': t.dueAt?.toIso8601String(),
        'isCompleted': t.isCompleted,
        'subjectId': t.subjectId,
        'topicId': t.topicId,
        'priority': t.priority.name,
        'reminderEnabled': t.reminderEnabled,
        'reminderMinutesBefore': t.reminderMinutesBefore,
        'recurrence': t.recurrence.name,
        'recurrenceIntervalDays': t.recurrenceIntervalDays,
        'recurrenceEndsAt': t.recurrenceEndsAt?.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _teachSettingsToJson(TeachSettings s) => {
        'id': s.id,
        'apiKey': s.apiKey,
        'cloudProvider': s.cloudProvider,
        'cloudModel': s.cloudModel,
        'cloudEndpoint': s.cloudEndpoint,
      };
}

final exportService = ExportService();
