import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../main.dart';

class FlashcardService {

  FlashcardService();

  // Anki v2 defaults.
  static const List<int> _learningStepsMinutes = [1, 10]; // minutes
  static const List<int> _relearningStepsMinutes = [10]; // minutes
  static const int _graduatingIntervalDays = 1;
  static const int _easyIntervalDays = 4;
  static const double _easyBonus = 1.3;
  static const double _hardIntervalFactor = 1.2;
  static const double _lapseIntervalFactor = 0.5;
  static const int _minIntervalDays = 1;

  Future<List<FlashcardDeck>> getDecksByTopic(int topicId) async {
    return await isar.flashcardDecks
        .filter()
        .topicIdEqualTo(topicId)
        .findAll();
  }

  Future<int> createDeck(int topicId, String name) async {
    final deck = FlashcardDeck()
      ..topicId = topicId
      ..name = name;
    return await isar.writeTxn(() async {
      return await isar.flashcardDecks.put(deck);
    });
  }

  Future<void> deleteDeck(int deckId) async {
    await isar.writeTxn(() async {
      await isar.flashcards.filter().deckIdEqualTo(deckId).deleteAll();
      await isar.flashcardDecks.delete(deckId);
    });
  }

  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) async {
    return await isar.flashcards
        .filter()
        .deckIdEqualTo(deckId)
        .findAll();
  }

  Future<int> createFlashcard(
    int deckId,
    String front,
    String back, {
    String? imagePath,
    String? audioPath,
    bool imageOnFront = false,
    bool audioOnFront = false,
    int? lastReviewed,
    int? dueAt,
    int intervalDays = 0,
    double easeFactor = 2.5,
    int repetitions = 0,
    int lapses = 0,
  }) async {
    final flashcard = Flashcard()
      ..deckId = deckId
      ..front = front
      ..back = back
      ..imagePath = imagePath
      ..audioPath = audioPath
      ..imageOnFront = imageOnFront
      ..audioOnFront = audioOnFront
      ..lastReviewed = lastReviewed ?? 0
      ..dueAt = dueAt ?? 0
      ..intervalDays = intervalDays
      ..easeFactor = easeFactor
      ..repetitions = repetitions
      ..lapses = lapses;
    return await isar.writeTxn(() async {
      return await isar.flashcards.put(flashcard);
    });
  }

  Future<void> deleteFlashcard(int flashcardId) async {
    await isar.writeTxn(() async {
      await isar.flashcards.delete(flashcardId);
    });
  }

  Future<void> updateFlashcard(
    int flashcardId, {
    String? front,
    String? back,
    String? imagePath,
    String? audioPath,
    bool? imageOnFront,
    bool? audioOnFront,
  }) async {
    final flashcard = await isar.flashcards.get(flashcardId);
    if (flashcard != null) {
      if (front != null) flashcard.front = front;
      if (back != null) flashcard.back = back;
      flashcard.imagePath = imagePath ?? flashcard.imagePath;
      flashcard.audioPath = audioPath ?? flashcard.audioPath;
      if (imageOnFront != null) flashcard.imageOnFront = imageOnFront;
      if (audioOnFront != null) flashcard.audioOnFront = audioOnFront;
      await isar.writeTxn(() async {
        await isar.flashcards.put(flashcard);
      });
    }
  }

  /// SM-2-like scheduler with Anki-style learning/relearning steps.
  ///
  /// Learning steps (minutes) until graduation: Good -> 1 day, Easy -> 4 days.
  /// Lapses return to steps with reduced interval; Hard/Good/Easy scale intervals in review.
  Future<FlashcardReviewOutcome?> reviewFlashcard(int flashcardId, int quality) async {
    final card = await isar.flashcards.get(flashcardId);
    if (card == null) return null;

    final now = DateTime.now();
    final clamped = quality.clamp(0, 4);
    int scheduledMinutes = 0;
    bool wasLapse = false;

    final bool isLearning = card.intervalDays == 0;
    final bool isNew = card.dueAt == 0 && card.repetitions == 0 && card.intervalDays == 0;

    if (isLearning || isNew) {
      // Learning/relearning steps in minutes.
      int stepIndex = card.repetitions.clamp(0, _learningStepsMinutes.length - 1);

      if (clamped == 0) {
        // Again: restart learning steps.
        wasLapse = !isNew;
        card.repetitions = 0;
        stepIndex = 0;
        scheduledMinutes = _learningStepsMinutes.first;
        card.dueAt = now.add(Duration(minutes: scheduledMinutes)).millisecondsSinceEpoch;
      } else if (clamped == 2) {
        // Hard: stay on current step.
        scheduledMinutes = _learningStepsMinutes[stepIndex];
        card.easeFactor = (card.easeFactor - 0.15).clamp(1.3, 3.0);
        card.dueAt = now.add(Duration(minutes: scheduledMinutes)).millisecondsSinceEpoch;
      } else if (clamped == 3) {
        // Good: advance a step or graduate.
        if (stepIndex < _learningStepsMinutes.length - 1) {
          stepIndex += 1;
          card.repetitions = stepIndex;
          scheduledMinutes = _learningStepsMinutes[stepIndex];
          card.dueAt = now.add(Duration(minutes: scheduledMinutes)).millisecondsSinceEpoch;
        } else {
          // Graduate to review.
          card.intervalDays = _graduatingIntervalDays;
          card.repetitions = 1;
          scheduledMinutes = card.intervalDays * 1440;
          card.dueAt = now.add(Duration(days: card.intervalDays)).millisecondsSinceEpoch;
        }
      } else if (clamped == 4) {
        // Easy: graduate immediately to easy interval and boost ease slightly.
        card.intervalDays = _easyIntervalDays;
        card.repetitions = 1;
        card.easeFactor = (card.easeFactor + 0.15).clamp(1.3, 3.0);
        scheduledMinutes = card.intervalDays * 1440;
        card.dueAt = now.add(Duration(days: card.intervalDays)).millisecondsSinceEpoch;
      }
    } else {
      // Review phase with SM-2 interval math.
      if (clamped == 0) {
        // Lapse: reduce ease, send to relearning step.
        wasLapse = true;
        card.lapses += 1;
        card.repetitions = 0;
        card.easeFactor = (card.easeFactor - 0.2).clamp(1.3, 3.0);
        card.intervalDays = max(_minIntervalDays, (card.intervalDays * _lapseIntervalFactor).round());
        scheduledMinutes = _relearningStepsMinutes.first;
        card.dueAt = now.add(Duration(minutes: scheduledMinutes)).millisecondsSinceEpoch;
      } else {
        // Calculate next interval.
        double ease = card.easeFactor;
        if (clamped == 2) {
          ease = (ease - 0.15).clamp(1.3, 3.0);
        } else if (clamped == 4) {
          ease = (ease + 0.15).clamp(1.3, 3.0);
        }
        card.easeFactor = ease;

        int nextInterval;
        if (clamped == 2) {
          nextInterval = max(_minIntervalDays, (card.intervalDays * _hardIntervalFactor).round());
        } else if (clamped == 3) {
          nextInterval = max(_minIntervalDays, (card.intervalDays * ease).round());
        } else {
          // Easy
          nextInterval = max(_minIntervalDays, (card.intervalDays * ease * _easyBonus).round());
        }

        card.intervalDays = nextInterval.clamp(_minIntervalDays, 36500);
        scheduledMinutes = card.intervalDays * 1440;
        card.dueAt = now.add(Duration(days: card.intervalDays)).millisecondsSinceEpoch;
        card.repetitions += 1;
      }
    }

    card.lastReviewed = now.millisecondsSinceEpoch;

    await isar.writeTxn(() async {
      await isar.flashcards.put(card);
    });

    final scheduledLabel = scheduledMinutes < 1440
        ? "$scheduledMinutes min"
        : "${(scheduledMinutes / 1440).round()} day(s)";

    return FlashcardReviewOutcome(
      card: card,
      scheduledMinutes: scheduledMinutes,
      scheduledLabel: scheduledLabel,
      dueAtMs: card.dueAt,
      easeFactor: card.easeFactor,
      wasLapse: wasLapse,
    );
  }

  /// Export a single deck with its cards and embedded media (base64).
  Future<Map<String, dynamic>> exportDeckData(int deckId) async {
    final deck = await isar.flashcardDecks.get(deckId);
    if (deck == null) {
      return {};
    }

    final cards = await getFlashcardsByDeck(deckId);

    final serializedCards = <Map<String, dynamic>>[];
    for (final card in cards) {
      String? imageData;
      String? imageFileName;
      if (card.imagePath != null) {
        final file = File(card.imagePath!);
        if (await file.exists()) {
          imageData = base64Encode(await file.readAsBytes());
          imageFileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : null;
        }
      }

      String? audioData;
      String? audioFileName;
      if (card.audioPath != null) {
        final file = File(card.audioPath!);
        if (await file.exists()) {
          audioData = base64Encode(await file.readAsBytes());
          audioFileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : null;
        }
      }

      serializedCards.add({
        'front': card.front,
        'back': card.back,
        'imagePath': card.imagePath,
        'audioPath': card.audioPath,
        'imageOnFront': card.imageOnFront,
        'audioOnFront': card.audioOnFront,
        'lastReviewed': card.lastReviewed,
        'dueAt': card.dueAt,
        'intervalDays': card.intervalDays,
        'easeFactor': card.easeFactor,
        'repetitions': card.repetitions,
        'lapses': card.lapses,
        'imageData': imageData,
        'imageFileName': imageFileName,
        'audioData': audioData,
        'audioFileName': audioFileName,
      });
    }

    return {
      'version': 1,
      'deck': {
        'name': deck.name,
        'topicId': deck.topicId,
      },
      'cards': serializedCards,
    };
  }

  Future<int> importDeckData(int topicId, Map<String, dynamic> data) async {
    final deckInfo = (data['deck'] ?? {}) as Map<String, dynamic>;
    final deckName = (deckInfo['name'] as String?)?.trim();
    final name = (deckName == null || deckName.isEmpty)
        ? 'Imported Deck ${DateTime.now().millisecondsSinceEpoch}'
        : deckName;

    final newDeckId = await createDeck(topicId, name);
    final cards = (data['cards'] ?? []) as List<dynamic>;
    await _importCardsIntoDeck(newDeckId, cards);
    return newDeckId;
  }

  Future<void> importCardsIntoDeck(int deckId, Map<String, dynamic> data) async {
    final cards = (data['cards'] ?? []) as List<dynamic>;
    await _importCardsIntoDeck(deckId, cards);
  }

  Future<void> _importCardsIntoDeck(int deckId, List<dynamic> cards) async {
    for (final raw in cards) {
      if (raw is! Map<String, dynamic>) continue;

      final front = (raw['front'] ?? '').toString();
      final back = (raw['back'] ?? '').toString();
      if (front.isEmpty && back.isEmpty) continue;

      final imagePath = await _restoreAttachment(
        raw['imageData'] as String?,
        raw['imageFileName'] as String?,
        fallbackName: 'image',
      );
      final audioPath = await _restoreAttachment(
        raw['audioData'] as String?,
        raw['audioFileName'] as String?,
        fallbackName: 'audio',
      );

      await createFlashcard(
        deckId,
        front,
        back,
        imagePath: imagePath ?? raw['imagePath'] as String?,
        audioPath: audioPath ?? raw['audioPath'] as String?,
        imageOnFront: (raw['imageOnFront'] as bool?) ?? false,
        audioOnFront: (raw['audioOnFront'] as bool?) ?? false,
        lastReviewed: raw['lastReviewed'] as int?,
        dueAt: raw['dueAt'] as int?,
        intervalDays: (raw['intervalDays'] as int?) ?? 0,
        easeFactor: (raw['easeFactor'] as num?)?.toDouble() ?? 2.5,
        repetitions: (raw['repetitions'] as int?) ?? 0,
        lapses: (raw['lapses'] as int?) ?? 0,
      );
    }
  }

  Future<String?> _restoreAttachment(
    String? base64Data,
    String? fileName, {
    required String fallbackName,
  }) async {
    if (base64Data == null || base64Data.isEmpty) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${dir.path}/flashcard_media');
      if (!mediaDir.existsSync()) {
        await mediaDir.create(recursive: true);
      }

      final safeName = (fileName == null || fileName.isEmpty)
          ? '$fallbackName-${DateTime.now().millisecondsSinceEpoch}'
          : fileName;
      final file = File('${mediaDir.path}/$safeName');
      await file.writeAsBytes(base64Decode(base64Data));
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Import Anki .apkg (Basic note type) into this topic.
  /// Returns list of new deck IDs created.
  Future<List<int>> importAnkiApkg(int topicId, String apkgPath) async {
    final tmpRoot = await getTemporaryDirectory();
    final workDir = Directory(p.join(
      tmpRoot.path,
      'anki_import_${DateTime.now().millisecondsSinceEpoch}',
    ));
    await workDir.create(recursive: true);

    final createdDeckIds = <int>[];
    Database? db;

    try {
      // 1) Unzip the package into a temp folder.
      final bytes = await File(apkgPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      for (final file in archive) {
        if (file.isFile) {
          final outFile = File(p.join(workDir.path, file.name));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      // 2) Load media map.
      final mediaFile = File(p.join(workDir.path, 'media'));
      Map<String, dynamic> mediaMap = {};
      if (await mediaFile.exists()) {
        final mediaJson = await mediaFile.readAsString();
        mediaMap = jsonDecode(mediaJson) as Map<String, dynamic>;
      }

      // 3) Open collection DB.
      final collectionPathCandidates = [
        p.join(workDir.path, 'collection.anki21'),
        p.join(workDir.path, 'collection.anki2'),
      ];
      final collectionPath = collectionPathCandidates.firstWhere(
        (p) => File(p).existsSync(),
        orElse: () => '',
      );
      if (collectionPath.isEmpty) {
        throw Exception('collection.anki21 not found in package.');
      }

      db = sqlite3.open(collectionPath, mode: OpenMode.readOnly);

      // 4) Deck names and creation day (crt).
      final colRows = db.select('SELECT decks, models, crt FROM col LIMIT 1');
      final colRow = colRows.isNotEmpty ? colRows.first : null;
      final decksJson = (colRow?['decks'] as String?) ?? '{}';
      final modelsJson = (colRow?['models'] as String?) ?? '{}';
      final crtDays = (colRow?['crt'] as int?) ?? 0;
      final deckNameMap = <int, String>{};
      final modelMap = <int, _AnkiModel>{};
      try {
        final parsed = jsonDecode(decksJson) as Map<String, dynamic>;
        for (final entry in parsed.entries) {
          final deckId = int.tryParse(entry.key);
          if (deckId != null) {
            final name = (entry.value as Map)['name'] as String? ?? 'Imported Deck $deckId';
            deckNameMap[deckId] = name;
          }
        }
      } catch (_) {}
      try {
        final parsed = jsonDecode(modelsJson) as Map<String, dynamic>;
        for (final entry in parsed.entries) {
          final mid = int.tryParse(entry.key);
          if (mid != null) {
            final model = _AnkiModel.fromJson(Map<String, dynamic>.from(entry.value));
            modelMap[mid] = model;
          }
        }
      } catch (_) {}

      // 5) Fetch cards (Basic only, ord=0 template).
      final rows = db.select('''
        SELECT c.id, c.nid, c.did, c.due, c.ivl, c.factor, c.reps, c.lapses, c.type, n.flds, n.mid, c.ord
        FROM cards c
        JOIN notes n ON c.nid = n.id
        WHERE c.ord = 0
      ''');

      final cardsByDeck = <int, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final did = row['did'] as int;
        cardsByDeck.putIfAbsent(did, () => []).add(row);
      }

      // 6) Create decks and import cards.
      for (final entry in cardsByDeck.entries) {
        final ankiDeckId = entry.key;
        final deckName = deckNameMap[ankiDeckId] ?? p.basenameWithoutExtension(apkgPath);

        final newDeckId = await createDeck(topicId, deckName);
        createdDeckIds.add(newDeckId);

        for (final row in entry.value) {
          final fields = (row['flds'] as String).split('\u001F');
          final mid = row['mid'] as int?;
          final model = mid != null ? modelMap[mid] : null;
          final template = model?.templates.isNotEmpty == true ? model!.templates.first : null;

          String frontRaw;
          String backRaw;
          if (template != null) {
            frontRaw = _renderTemplate(template.qfmt, fields, model!.fieldNames);
            final renderedFront = frontRaw;
            backRaw = _renderTemplate(
              template.afmt.replaceAll("{{FrontSide}}", renderedFront),
              fields,
              model.fieldNames,
            );
          } else {
            // Fallback: basic two-sided
            final frontParts = <String>[];
            if (fields.isNotEmpty) frontParts.add(fields[0]);
            if (fields.length > 1) frontParts.add(fields[1]);
            frontRaw = frontParts.join('\n\n');
            backRaw = fields.length > 2 ? fields.sublist(2).join('\n\n') : (fields.length > 1 ? fields[1] : '');
          }

          final cleanedFront = _cleanField(frontRaw);
          final cleanedBack = _cleanField(backRaw);

          final type = row['type'] as int; // 0=new,1=learning,2=review,3=relearn
          final ivl = row['ivl'] as int? ?? 0;
          final factor = row['factor'] as int? ?? 2500;
          final reps = row['reps'] as int? ?? 0;
          final lapses = row['lapses'] as int? ?? 0;
          final dueRaw = row['due'] as int? ?? 0;

          int dueAt = 0;
          int intervalDays = 0;
          int lastReviewed = 0;
          double ease = (factor / 1000).clamp(1.3, 3.0);

          if (type >= 2 && ivl > 0) {
            intervalDays = ivl;
            final dueDays = crtDays + dueRaw;
            dueAt = DateTime.fromMillisecondsSinceEpoch(dueDays * 86400000).millisecondsSinceEpoch;
            lastReviewed = DateTime.now().millisecondsSinceEpoch;
          }

          final mediaFront = await _extractMedia(frontRaw, mediaMap, workDir);
          final mediaBack = await _extractMedia(backRaw, mediaMap, workDir);

          // Fallback if text is empty but media exists.
          final hasFrontMedia = mediaFront.imagePath != null || mediaFront.audioPaths.isNotEmpty;
          final hasBackMedia = mediaBack.imagePath != null || mediaBack.audioPaths.isNotEmpty;
          final finalFront = cleanedFront.isNotEmpty
              ? cleanedFront
              : (hasFrontMedia ? 'Media card' : frontRaw.trim());
          final finalBack = cleanedBack.isNotEmpty
              ? cleanedBack
              : (hasBackMedia ? 'Media card' : backRaw.trim());

          await createFlashcard(
            newDeckId,
            finalFront,
            finalBack,
            imagePath: mediaFront.imagePath ?? mediaBack.imagePath,
            audioPath: _serializeAudioBundle(mediaFront, mediaBack),
            imageOnFront: mediaFront.imagePath != null,
            audioOnFront: mediaFront.audioPaths.isNotEmpty,
            lastReviewed: lastReviewed,
            dueAt: dueAt,
            intervalDays: intervalDays,
            easeFactor: ease,
            repetitions: reps,
            lapses: lapses,
          );
        }
      }
    } finally {
      db?.dispose();
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    }

    return createdDeckIds;
  }

  Future<_ImportedMedia> _extractMedia(
    String field,
    Map<String, dynamic> mediaMap,
    Directory workDir,
  ) async {
    String? imagePath;
    final audioPaths = <String>[];

    // Sound: [sound:xxx.mp3]
    final soundMatches = RegExp(r'\[sound:([^\]]+)\]').allMatches(field);
    for (final m in soundMatches) {
      final name = m.group(1)!;
      final copied = await _copyMediaFile(name, mediaMap, workDir);
      if (copied != null) audioPaths.add(copied);
    }

    // Image: <img src="xxx.png">
    final imgMatch = RegExp(r'src="([^"]+)"').firstMatch(field);
    if (imgMatch != null) {
      final name = imgMatch.group(1)!;
      imagePath = await _copyMediaFile(name, mediaMap, workDir);
    }

    // Also handle <audio src="...">
    final audioTagMatches = RegExp(r'<audio[^>]*src="([^"]+)"').allMatches(field);
    for (final m in audioTagMatches) {
      final name = m.group(1)!;
      final copied = await _copyMediaFile(name, mediaMap, workDir);
      if (copied != null) audioPaths.add(copied);
    }

    return _ImportedMedia(imagePath: imagePath, audioPaths: audioPaths);
  }

  Future<String?> _copyMediaFile(
    String filename,
    Map<String, dynamic> mediaMap,
    Directory workDir,
  ) async {
    // Resolve filename to numbered file in the extracted archive.
    String? numberedName;
    for (final entry in mediaMap.entries) {
      if (entry.value == filename) {
        numberedName = entry.key;
        break;
      }
    }
    numberedName ??= filename;

    final source = File(p.join(workDir.path, numberedName));
    if (!source.existsSync()) return null;

    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'flashcard_media'));
      if (!mediaDir.existsSync()) {
        await mediaDir.create(recursive: true);
      }

      final safeName = filename.replaceAll(RegExp(r'[\\\\/:*?"<>|]'), '_');
      final dest = File(p.join(mediaDir.path, safeName));

      final uniqueDest = dest.existsSync()
          ? File(p.join(mediaDir.path,
              '${DateTime.now().millisecondsSinceEpoch}_$safeName'))
          : dest;

      return source.copySync(uniqueDest.path).path;
    } catch (_) {
      return null;
    }
  }

  String _cleanField(String text) {
    var t = text;
    t = t.replaceAll(RegExp(r'<br\\s*/?>', caseSensitive: false), '\n');
    t = t.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    t = t.replaceAll(RegExp(r'\[sound:[^\]]+\]'), '');
    t = t.replaceAll(RegExp(r'<audio[^>]*src="([^"]+)"[^>]*>[^<]*</audio>', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'<[^>]+>'), '');
    return t.trim();
  }

  String _renderTemplate(String template, List<String> fieldValues, List<String> fieldNames) {
    var rendered = template;
    for (var i = 0; i < fieldNames.length && i < fieldValues.length; i++) {
      final name = fieldNames[i];
      rendered = rendered.replaceAll('{{$name}}', fieldValues[i]);
    }
    // Strip other tags like {{FrontSide}}
    rendered = rendered.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');
    return rendered;
  }
}

final flashcardService = FlashcardService();

class FlashcardReviewOutcome {
  final Flashcard card;
  final int scheduledMinutes;
  final String scheduledLabel;
  final int dueAtMs;
  final double easeFactor;
  final bool wasLapse;

  FlashcardReviewOutcome({
    required this.card,
    required this.scheduledMinutes,
    required this.scheduledLabel,
    required this.dueAtMs,
    required this.easeFactor,
    required this.wasLapse,
  });
}

class _ImportedMedia {
  final String? imagePath;
  final List<String> audioPaths;

  _ImportedMedia({this.imagePath, this.audioPaths = const []});
}

String _serializeAudioBundle(_ImportedMedia front, _ImportedMedia back) {
  if (front.audioPaths.isEmpty && back.audioPaths.isEmpty) return '';
  final payload = {
    'front': front.audioPaths,
    'back': back.audioPaths,
  };
  return jsonEncode(payload);
}

class _AnkiModel {
  final List<String> fieldNames;
  final List<_AnkiTemplate> templates;

  _AnkiModel({required this.fieldNames, required this.templates});

  factory _AnkiModel.fromJson(Map<String, dynamic> json) {
    final fieldsRaw = (json['flds'] as List<dynamic>? ?? [])
        .map((f) => (f as Map)['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final tmplsRaw = (json['tmpls'] as List<dynamic>? ?? [])
        .map((t) => _AnkiTemplate.fromJson(Map<String, dynamic>.from(t)))
        .toList();
    return _AnkiModel(fieldNames: fieldsRaw, templates: tmplsRaw);
  }
}

class _AnkiTemplate {
  final String qfmt;
  final String afmt;

  _AnkiTemplate({required this.qfmt, required this.afmt});

  factory _AnkiTemplate.fromJson(Map<String, dynamic> json) {
    return _AnkiTemplate(
      qfmt: (json['qfmt'] as String?) ?? '',
      afmt: (json['afmt'] as String?) ?? '',
    );
  }
}
