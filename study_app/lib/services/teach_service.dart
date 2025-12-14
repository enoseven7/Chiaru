
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../models/teach_settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocalModelInfo {
  final String id;
  final String name;
  final String url;
  final int sizeBytes;
  final String sha256;
  const LocalModelInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeBytes,
    this.sha256 = '',
  });
}

/// Example model list (swap URLs/hashes as needed).
const availableLocalModels = [
  LocalModelInfo(
    id: 'tiny-3b-q4_0',
    name: 'Tiny 3B Q4_0 (~1.6GB)',
    url:
        'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    sizeBytes: 0, // prefer server-reported size to avoid mismatches
  ),
];

class LocalModelManager {
  Future<Directory> _modelDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final models = Directory(p.join(dir.path, 'local_models'));
    if (!models.existsSync()) {
      models.createSync(recursive: true);
    }
    return models;
  }

  Future<bool> isInstalled(LocalModelInfo model) async {
    final dir = await _modelDir();
    return File(p.join(dir.path, '${model.id}.gguf')).exists();
  }

  Future<String?> installedPath(LocalModelInfo model) async {
    final dir = await _modelDir();
    final path = p.join(dir.path, '${model.id}.gguf');
    return File(path).existsSync() ? path : null;
  }

  Future<void> remove(LocalModelInfo model) async {
    final dir = await _modelDir();
    final file = File(p.join(dir.path, '${model.id}.gguf'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Simple downloader using HttpClient; call [onProgress] with 0..1.
  /// Saves the file into the app's documents/local_models directory where the runtime will load from.
  Future<String> download(LocalModelInfo model, void Function(double) onProgress) async {
    final dir = await _modelDir();
    final tmpPath = p.join(dir.path, '${model.id}.part');
    final finalPath = p.join(dir.path, '${model.id}.gguf');

    final uri = Uri.parse(model.url);
    final client = HttpClient();
    final req = await client.getUrl(uri);
    final resp = await req.close();
    if (resp.statusCode != 200) {
      throw Exception('Download failed: ${resp.statusCode}');
    }

    final sink = File(tmpPath).openWrite();
    int downloaded = 0;
    final expectedBytes = resp.contentLength > 0 ? resp.contentLength : model.sizeBytes;
    final total = expectedBytes > 0 ? expectedBytes : null;
    await for (final chunk in resp) {
      downloaded += chunk.length;
      sink.add(chunk);
      if (total != null && total > 0) {
        onProgress(downloaded / total);
      }
    }
    await sink.flush();
    await sink.close();
    await File(tmpPath).rename(finalPath);
    client.close(force: true);

    final downloadedFile = File(finalPath);
    if (!downloadedFile.existsSync()) {
      throw Exception('Model file missing after download');
    }
    final bytes = await downloadedFile.length();
    // Guard against truncated downloads even when size is unknown.
    const minAcceptableBytes = 50 * 1024 * 1024; // 50MB sanity check
    if ((expectedBytes > 0 && bytes < (expectedBytes * 0.95)) || bytes < minAcceptableBytes) {
      await downloadedFile.delete();
      throw Exception('Model download incomplete (expected ~${expectedBytes > 0 ? expectedBytes : 'unknown'} bytes, got $bytes)');
    }

    onProgress(1);
    return finalPath;
  }
}

class TeachService {
  final _modelManager = LocalModelManager();
  final _runtime = LlamaRuntime();

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

  LocalModelManager get modelManager => _modelManager;

  Future<String> critiqueLocally({
    required String explanation,
    required String topic,
    String audience = 'peer',
    String? modelId,
  }) async {
    final id = modelId ?? availableLocalModels.first.id;
    final info = availableLocalModels.firstWhere((m) => m.id == id, orElse: () => availableLocalModels.first);
    final path = await _modelManager.installedPath(info);
    if (path == null) throw Exception("Model not installed");
    try {
      await _runtime.load(path);
    } catch (e) {
      return "Failed to load local model: $e";
    }

    final prompt = """
You are tasked with critiquing a user's explanation for them to practice a topic using the Feynman technique. You should act the roll of a $audience, and tailor mannerisms that $audience would have into the critique.. Critique the explanation below for clarity, accuracy, and completeness. Topic: $topic. Audience: $audience. Ignore informal grammar or casual phrasing unless the user explicitly asks for a grammar-focused review.

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

    try {
      final result = await _runtime.generate(prompt);
      return result;
    } catch (e) {
      return "Failed to run local model: $e";
    }
  }

  Future<String> critiqueCloud({
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

    try {
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
    } catch (e) {
      return "Failed to call cloud provider: $e";
    }
  }
}

final teachService = TeachService();

class LlamaRuntime {
  Llama? _llama;
  String? _loadedPath;
  String? _libPath;

  String? _findLibrary() {
    if (_libPath != null) return _libPath;

    // Allow an explicit override for tricky deployment layouts.
    final override = Platform.environment['LLAMA_DLL_PATH'];
    if (override != null && override.isNotEmpty && File(override).existsSync()) {
      _libPath = override;
      return _libPath;
    }

    final cwd = Directory.current.path;
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = <String>[
      p.join(cwd, 'llama.dll'),
      p.join(cwd, 'bin', 'llama.dll'),
      p.join(exeDir, 'llama.dll'),
      p.join(exeDir, 'bin', 'llama.dll'),
      p.join(p.dirname(exeDir), 'bin', 'llama.dll'),
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        _libPath = candidate;
        return _libPath;
      }
    }
    return null;
  }

  Future<void> load(String path) async {
    if (_loadedPath == path && _llama != null) return;
    _llama?.dispose();
    final libPath = _findLibrary();
    if (libPath == null) {
      throw Exception(
        "llama.dll not found. Place it next to the exe or in a bin/ folder, "
        "or set LLAMA_DLL_PATH to the full path. Working dir: ${Directory.current.path}",
      );
    }
    if (!File(path).existsSync()) {
      throw Exception("Model file not found at $path");
    }
    try {
      Llama.libraryPath = libPath;
      _llama = Llama(
        path,
        null,
        ContextParams()
          ..nCtx = 2048
          ..nPredict = 256,
      );
      _loadedPath = path;
    } on Error catch (e) {
      _llama = null;
      _loadedPath = null;
      throw Exception(
        "Failed to initialize llama runtime. Ensure a valid llama.dll and model file are present. Original error: $e",
      );
    } catch (e) {
      _llama = null;
      _loadedPath = null;
      rethrow;
    }
  }

  Future<String> generate(String prompt) async {
    final llama = _llama;
    if (llama == null) throw Exception("Model not loaded");
    try {
      llama.setPrompt(prompt);
      final buffer = StringBuffer();
      await for (final chunk in llama.generateText()) {
        buffer.write(chunk);
      }
      return buffer.toString();
    } catch (e) {
      rethrow;
    }
  }
}
