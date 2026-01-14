import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../main.dart';
import '../models/teach_settings.dart';
import '../services/local_llm_service.dart';

class TeachService {
  http.Client _buildClient({required bool allowBadCertificates}) {
    if (!allowBadCertificates) return http.Client();
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return IOClient(httpClient);
  }

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
    bool useLocalLLM = false,
  }) async {
    final prompt = """
You are an expert educational tutor providing constructive feedback. Analyze the student's explanation below and provide detailed, helpful critique.

**Topic:** $topic
**Target Audience:** $audience
**Student's Explanation:**
$explanation

Please provide your critique in the following format (use markdown formatting):

**Clarity:** x/10
Explain how clear and understandable the explanation is.

**Accuracy:** x/10
Assess factual correctness and technical precision.

**Completeness:** x/10
Evaluate coverage of key concepts and necessary details.

**Improved Explanation:**
Rewrite the explanation in a clearer, more engaging way appropriate for the target audience. Use examples or analogies where helpful.

**Key Feedback:**
- Provide 3-5 specific, actionable bullet points for improvement
- Focus on content, structure, and pedagogical effectiveness
- Be constructive and encouraging

**Suggested Follow-up Questions:**
List 2-3 thought-provoking questions to deepen understanding of the topic.

Keep your response focused and practical. Use **bold** for headings and key terms, and use bullet points for lists.
""";

    // Use local LLM if enabled
    if (useLocalLLM) {
      try {
        final response = await localLLMService.generate(
          prompt: prompt,
          maxTokens: 1024,
        );
        return response.trim().isEmpty ? "No response from local model." : response.trim();
      } catch (e) {
        return "Local LLM error: $e";
      }
    }

    // Otherwise use cloud provider
    switch (provider) {
      case 'openai':
        final base = (endpointOverride != null && endpointOverride.isNotEmpty)
            ? endpointOverride
            : 'https://api.openai.com/v1/chat/completions';
        final uri = Uri.parse(base);
        final client = _buildClient(
          allowBadCertificates: endpointOverride != null && endpointOverride.isNotEmpty,
        );
        http.Response resp;
        try {
          resp = await client.post(
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
        } finally {
          client.close();
        }
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
