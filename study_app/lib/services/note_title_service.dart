import 'package:shared_preferences/shared_preferences.dart';

class NoteTitleService {
  static const _prefix = 'note_title_';

  Future<Map<int, String>> loadTitles(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <int, String>{};
    for (final id in ids) {
      final t = prefs.getString('$_prefix$id');
      if (t != null && t.trim().isNotEmpty) {
        map[id] = t.trim();
      }
    }
    return map;
  }

  Future<void> saveTitle(int id, String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$id', title.trim());
  }

  Future<void> removeTitle(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
  }

  String displayTitle(int id, String plainText, Map<int, String> cache) {
    if (cache.containsKey(id)) return cache[id]!;
    if (plainText.isEmpty) return "(empty note)";
    final t = plainText.trim();
    return t.length > 50 ? "${t.substring(0, 50)}..." : t;
  }
}

final noteTitleService = NoteTitleService();
