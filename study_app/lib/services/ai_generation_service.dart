import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/teach_settings.dart';
import '../services/teach_service.dart';
import '../services/flashcard_service.dart';
import '../services/quiz_service.dart';
import '../models/quiz_question.dart';

class AiGenerationService {
  Future<String> _callModel({
    required TeachSettings settings,
    required String prompt,
    int? maxTokens,
  }) async {
    final provider = settings.cloudProvider.isEmpty ? 'openai' : settings.cloudProvider;
    final apiKey = settings.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw Exception("API key missing. Set it in Settings > AI.");
    }
    final model = settings.cloudModel.isEmpty ? 'gpt-4o-mini' : settings.cloudModel;
    switch (provider) {
      case 'openai':
        final uri = Uri.parse(
          settings.cloudEndpoint.isNotEmpty
              ? settings.cloudEndpoint
              : 'https://api.openai.com/v1/chat/completions',
        );
        final resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': 'You are a concise study helper.'},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.4,
            if (maxTokens != null) 'max_tokens': maxTokens,
          }),
        );
        if (resp.statusCode >= 400) {
          throw Exception("Cloud request failed (${resp.statusCode}): ${resp.body}");
        }
        final data = jsonDecode(resp.body);
        final choice = data['choices']?[0]?['message']?['content'] ?? '';
        return choice.toString().trim();
      case 'anthropic':
        final uri = Uri.parse('https://api.anthropic.com/v1/messages');
        final resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': maxTokens ?? 512,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        );
        if (resp.statusCode >= 400) {
          throw Exception("Cloud request failed (${resp.statusCode}): ${resp.body}");
        }
        final data = jsonDecode(resp.body);
        final text = (data['content'] is List && data['content'].isNotEmpty)
            ? (data['content'][0]['text'] ?? '').toString()
            : '';
        return text.trim();
      default:
        throw Exception("Unsupported provider: $provider");
    }
  }

  Future<String> _readPdf(String path) async {
    final file = File(path);
    if (!await file.exists()) return "";
    try {
      final bytes = await file.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();
      return text;
    } catch (_) {
      return "";
    }
  }

  String extractNoteText(String rawContent) {
    try {
      if (rawContent.trim().isEmpty) return "";
      final doc = quill.Document.fromJson(jsonDecode(rawContent));
      return doc.toPlainText().trim();
    } catch (_) {
      return rawContent;
    }
  }

  int estimateTokens(String text, {int perItem = 80, int itemCount = 0}) {
    final base = (text.length / 4).ceil();
    return base + perItem * itemCount;
  }

  Map<String, dynamic>? _extractJsonMap(String response, String expectedKey) {
    Map<String, dynamic>? tryDecode(String text) {
      try {
        final parsed = jsonDecode(text);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {}
      return null;
    }

    // Try direct parse
    final direct = tryDecode(response);
    if (direct != null && direct.containsKey(expectedKey)) return direct;

    // Strip code fences if present
    final fenceRegex = RegExp(r'```(?:json)?(.*?)```', dotAll: true);
    final fenceMatch = fenceRegex.firstMatch(response);
    if (fenceMatch != null) {
      final inner = fenceMatch.group(1)?.trim() ?? '';
      final parsed = tryDecode(inner);
      if (parsed != null && parsed.containsKey(expectedKey)) return parsed;
    }

    // Grab the first JSON object substring
    final objectRegex = RegExp(r'\{.*\}', dotAll: true);
    final objMatch = objectRegex.firstMatch(response);
    if (objMatch != null) {
      final parsed = tryDecode(objMatch.group(0)!);
      if (parsed != null && parsed.containsKey(expectedKey)) return parsed;
    }

    return null;
  }

  Future<int> generateFlashcards({
    required int topicId,
    required String title,
    String? description,
    String? notes,
    List<String> pdfPaths = const [],
    int maxCards = 10,
    int? tokenLimit,
  }) async {
    final settings = await teachService.loadSettings();
    final pdfTexts = <String>[];
    for (final p in pdfPaths) {
      try {
        final t = await _readPdf(p);
        if (t.isNotEmpty) pdfTexts.add(t);
      } catch (_) {}
    }
    final source = [
      "Title: $title",
      if ((description ?? '').isNotEmpty) "Description: $description",
      if ((notes ?? '').isNotEmpty) "Notes: $notes",
      if (pdfTexts.isNotEmpty) "PDF excerpts:\n${pdfTexts.join('\n---\n')}",
    ].join("\n\n");

    final prompt = """
Generate concise flashcards in JSON for study.
Max cards: $maxCards.
Keep per-card text brief, one idea per card. Do not invent facts.
Return JSON only in this shape:
{"cards":[{"front":"...","back":"..."}]}

Input material:
$source
""";

    final response = await _callModel(
      settings: settings,
      prompt: prompt,
      maxTokens: tokenLimit,
    );

    final parsed = _extractJsonMap(response, 'cards');
    if (parsed == null) {
      throw Exception("Could not parse AI response into cards.");
    }
    final cards = (parsed['cards'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .take(maxCards)
        .toList();
    if (cards.isEmpty) {
      throw Exception("No cards generated by AI.");
    }

    final deckName = title.isEmpty ? "AI Deck" : title;
    final deckId = await flashcardService.createDeck(topicId, deckName);
    int created = 0;
    for (final c in cards) {
      final front = (c['front'] ?? '').toString().trim();
      final back = (c['back'] ?? '').toString().trim();
      if (front.isEmpty || back.isEmpty) continue;
      await flashcardService.createFlashcard(deckId, front, back);
      created++;
    }
    return created;
  }

  Future<int> generateQuiz({
    required int topicId,
    required String title,
    String? description,
    String? notes,
    List<String> pdfPaths = const [],
    int maxQuestions = 8,
    int? tokenLimit,
  }) async {
    final settings = await teachService.loadSettings();
    final pdfTexts = <String>[];
    for (final p in pdfPaths) {
      try {
        final t = await _readPdf(p);
        if (t.isNotEmpty) pdfTexts.add(t);
      } catch (_) {}
    }
    final source = [
      "Title: $title",
      if ((description ?? '').isNotEmpty) "Description: $description",
      if ((notes ?? '').isNotEmpty) "Notes: $notes",
      if (pdfTexts.isNotEmpty) "PDF excerpts:\n${pdfTexts.join('\n---\n')}",
    ].join("\n\n");

    final prompt = """
Generate a quiz in JSON. Up to $maxQuestions questions. Prefer multiple_choice with 4 options; use text for short answers when necessary. Keep prompts concise and factual from the provided material only.
Return JSON only in this shape:
{"questions":[{"type":"multiple_choice","prompt":"...","options":["A","B","C","D"],"correct_index":0},{"type":"text","prompt":"...","answer":"..."}]}

Input material:
$source
""";

    final response = await _callModel(
      settings: settings,
      prompt: prompt,
      maxTokens: tokenLimit,
    );

    final parsed = _extractJsonMap(response, 'questions');
    if (parsed == null) {
      throw Exception("Could not parse AI response into questions.");
    }
    final questions = (parsed['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .take(maxQuestions)
        .toList();
    if (questions.isEmpty) {
      throw Exception("No questions generated by AI.");
    }

    final quizId = await quizService.createQuiz(
      topicId: topicId,
      title: title.isEmpty ? "AI Quiz" : title,
      description: description,
    );

    int created = 0;
    for (final q in questions) {
      final promptText = (q['prompt'] ?? '').toString().trim();
      if (promptText.isEmpty) continue;
      final typeRaw = (q['type'] ?? '').toString();
      if (typeRaw == 'multiple_choice') {
        final options = (q['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        if (options.length < 2) continue;
        final correct = (q['correct_index'] is int) ? q['correct_index'] as int : 0;
        await quizService.addQuestion(
          quizId: quizId,
          prompt: promptText,
          type: QuizQuestionType.multipleChoice,
          options: options,
          correctIndex: correct.clamp(0, options.length - 1),
        );
        created++;
      } else {
        final answer = (q['answer'] ?? '').toString().trim();
        await quizService.addQuestion(
          quizId: quizId,
          prompt: promptText,
          type: QuizQuestionType.text,
          answer: answer.isEmpty ? null : answer,
        );
      }
    }
    return created;
  }
}

final aiGenerationService = AiGenerationService();
