import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local LLM models via Ollama
///
/// This service allows users to download and use local LLM models through Ollama,
/// which must be installed separately. Ollama handles model management and inference.
class LocalLLMService {
  static final LocalLLMService instance = LocalLLMService._();
  LocalLLMService._();

  // Ollama typically runs on localhost:11434
  static const String defaultOllamaUrl = 'http://localhost:11434';

  // Available models that work well with Ollama
  static const List<LLMModelInfo> availableModels = [
    LLMModelInfo(
      name: 'Llama 3.2 1B',
      modelTag: 'llama3.2:1b',
      sizeInMB: 1300,
      description: 'Small, fast model from Meta. Good for quick responses.',
    ),
    LLMModelInfo(
      name: 'Llama 3.2 3B',
      modelTag: 'llama3.2:3b',
      sizeInMB: 2000,
      description: 'Balanced model with better quality than 1B.',
    ),
    LLMModelInfo(
      name: 'Phi-3 Mini',
      modelTag: 'phi3:mini',
      sizeInMB: 2300,
      description: 'Microsoft\'s efficient model, great for study tasks.',
    ),
    LLMModelInfo(
      name: 'Gemma 2B',
      modelTag: 'gemma:2b',
      sizeInMB: 1700,
      description: 'Google\'s lightweight model with good performance.',
    ),
  ];

  Future<String> getOllamaUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ollama_url') ?? defaultOllamaUrl;
  }

  Future<void> setOllamaUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ollama_url', url.trim());
  }

  Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_ollama_model');
  }

  Future<void> setSelectedModel(String modelTag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ollama_model', modelTag);
  }

  /// Check if Ollama is running and accessible
  Future<bool> isOllamaRunning() async {
    try {
      final baseUrl = await getOllamaUrl();
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 2),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get list of models installed in Ollama
  Future<List<String>> getInstalledModels() async {
    try {
      final baseUrl = await getOllamaUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List<dynamic>? ?? [];
        return models.map((m) => m['name'].toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Pull (download) a model in Ollama
  /// Returns a stream of progress updates
  Stream<OllamaDownloadProgress> downloadModel(String modelTag) async* {
    final baseUrl = await getOllamaUrl();
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/pull'),
    );
    request.body = jsonEncode({'name': modelTag});
    request.headers['Content-Type'] = 'application/json';

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            final status = data['status']?.toString() ?? '';
            final completed = data['completed'] as int? ?? 0;
            final total = data['total'] as int? ?? 0;

            double? progress;
            if (total > 0) {
              progress = completed / total;
            }

            yield OllamaDownloadProgress(
              status: status,
              progress: progress,
              completed: completed,
              total: total,
            );
          } catch (_) {
            // Skip malformed JSON lines
          }
        }
      }

      // Save as selected model after successful download
      await setSelectedModel(modelTag);
    } finally {
      client.close();
    }
  }

  /// Delete a model from Ollama
  Future<void> deleteModel(String modelTag) async {
    final baseUrl = await getOllamaUrl();
    await http.delete(
      Uri.parse('$baseUrl/api/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelTag}),
    );

    // Clear selected model if it was deleted
    final selected = await getSelectedModel();
    if (selected == modelTag) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_ollama_model');
    }
  }

  /// Generate text using the selected local model
  Future<String> generate({
    required String prompt,
    int maxTokens = 512,
  }) async {
    final baseUrl = await getOllamaUrl();
    final modelTag = await getSelectedModel();

    if (modelTag == null) {
      throw Exception('No local model selected. Please download and select a model in Settings.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': modelTag,
        'prompt': prompt,
        'stream': false,
        'options': {
          'temperature': 0.4,
          'num_predict': maxTokens,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ollama request failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    return (data['response'] ?? '').toString().trim();
  }

  /// Generate text with streaming (for future use)
  Stream<String> generateStream({
    required String prompt,
    int maxTokens = 512,
  }) async* {
    final baseUrl = await getOllamaUrl();
    final modelTag = await getSelectedModel();

    if (modelTag == null) {
      throw Exception('No local model selected.');
    }

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/generate'),
    );
    request.body = jsonEncode({
      'model': modelTag,
      'prompt': prompt,
      'stream': true,
      'options': {
        'temperature': 0.4,
        'num_predict': maxTokens,
      },
    });
    request.headers['Content-Type'] = 'application/json';

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            final response = data['response']?.toString() ?? '';
            if (response.isNotEmpty) {
              yield response;
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }
}

final localLLMService = LocalLLMService.instance;

class OllamaDownloadProgress {
  final String status;
  final double? progress;
  final int completed;
  final int total;

  OllamaDownloadProgress({
    required this.status,
    this.progress,
    required this.completed,
    required this.total,
  });
}

class LLMModelInfo {
  final String name;
  final String modelTag;
  final int sizeInMB;
  final String description;

  const LLMModelInfo({
    required this.name,
    required this.modelTag,
    required this.sizeInMB,
    required this.description,
  });
}
