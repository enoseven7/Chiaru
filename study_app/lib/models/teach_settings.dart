import 'package:isar/isar.dart';

part 'teach_settings.g.dart';

@collection
class TeachSettings {
  /// Singleton entry: id = 0
  Id id = 0;

  /// Which cloud provider to call (e.g., openai, anthropic).
  String cloudProvider = 'openai';

  /// Model identifier for the chosen cloud provider.
  String cloudModel = 'gpt-4o-mini';

  /// Optional custom endpoint for OpenAI-compatible proxies.
  String cloudEndpoint = '';

  /// Placeholder for cloud key (not used yet)
  String? apiKey;
}
