import 'dart:convert';

import 'package:http/http.dart' as http;

import '../main.dart';
import '../models/teach_settings.dart';

class TeachService {
  Future<TeachSettings> loadSettings() async {
    final existing = await isar.collection<TeachSettings>().get(0);
    if (existing != null) return existing;
    final defaults = TeachSettings();
    await isar.writeTxn(() async => isar.collection<TeachSettings>().put(defaults));
    return defaults;
  }

  Future<void> saveSettings(TeachSettings settings) async {
    await isar.writeTxn(() async => isar.collection<TeachSettings>().put(settings));
  }

  Future<String> critique({
    required String provider,
    required String apiKey,
    required String model,
    String? endpointOverride,
    required String topic,
    required String explanation,
    String audience = 'peer',
  }) async {
    final prompt = """
You are a concise tutor. Critique the explanation below for clarity, accuracy, and completeness. Topic: $topic. Audience: $audience. Ignore informal grammar or casual phrasing unless the user explicitly asks for a grammar-focused review.

Explanation:
$explanation

Respond with:
Clarity: x/10
Accuracy: x/10
Completeness: x/10
Improved Explanation: rewrite it more clearly for the stated audience.

Feedback: bullet points, brief (avoid focusing on casual grammar unless requested).
Follow-ups: 2-3 suggested questions.
""";

    switch (provider) {
      case 'openai':
        final base = (endpointOverride != null && endpointOverride.isNotEmpty)
            ? endpointOverride
            : 'https://api.openai.com/v1/chat/completions';
        final uri = Uri.parse(base);
        final resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': 'You are a concise tutor.'},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.4,
          }),
        );
        if (resp.statusCode >= 400) {
          return "Cloud request failed (${resp.statusCode}): ${resp.body}";
        }
        final data = jsonDecode(resp.body);
        final choice = data['choices']?[0]?['message']?['content'] ?? '';
        return choice.toString().trim().isEmpty ? "No response from model." : choice.toString().trim();
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
            'max_tokens': 512,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        );
        if (resp.statusCode >= 400) {
          return "Cloud request failed (${resp.statusCode}): ${resp.body}";
        }
        final data = jsonDecode(resp.body);
        final text = (data['content'] is List && data['content'].isNotEmpty)
            ? (data['content'][0]['text'] ?? '').toString()
            : '';
        return text.trim().isEmpty ? "No response from model." : text.trim();
      default:
        return "Unsupported provider: $provider";
    }
  }
}

final teachService = TeachService();
