import 'package:isar/isar.dart';

part 'teach_settings.g.dart';

@collection
class TeachSettings {
  /// Singleton entry: id = 0
  Id id = 0;

  /// 'cloud' or 'local'
  String provider = 'local';

  /// Selected local model id/name
  String? localModel;

  /// Placeholder for cloud key (not used yet)
  String? apiKey;
}
