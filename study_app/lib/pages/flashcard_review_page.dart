import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../services/flashcard_service.dart';

class FlashcardReviewPage extends StatefulWidget {
  final FlashcardDeck deck;
  final int startIndex;

  const FlashcardReviewPage({
    super.key,
    required this.deck,
    this.startIndex = 0,
  });

  @override
  State<FlashcardReviewPage> createState() => _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends State<FlashcardReviewPage> {
  static const int _maxNewPerSession = 20;
  List<Flashcard> cards = [];
  List<Flashcard> queue = [];
  int index = 0;
  bool showBack = false;
  late final AudioPlayer _player;
  bool _isPlaying = false;
  String? _audioPath;
  bool _onlyDue = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _load();
  }

  Future<void> _load() async {
    cards = await flashcardService.getFlashcardsByDeck(widget.deck.id);
    _rebuildQueue(startIndex: widget.startIndex);
  }

  void _rebuildQueue({int? startIndex}) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_onlyDue) {
      final dueCards = cards.where((c) => c.dueAt <= nowMs && c.dueAt != 0).toList();
      final newCards = cards.where((c) => c.dueAt == 0).take(_maxNewPerSession).toList();
      queue = [...dueCards, ...newCards];
    } else {
      queue = List<Flashcard>.from(cards);
    }

    queue.sort((a, b) => a.dueAt.compareTo(b.dueAt));

    if (queue.isEmpty) {
      index = 0;
    } else {
      index = (startIndex ?? index).clamp(0, queue.length - 1);
    }

    if (!mounted) return;
    setState(() {
      showBack = false;
    });
  }

  void _flip() {
    if (!mounted) return;
    setState(() => showBack = !showBack);
  }

  void _next() {
    if (queue.isEmpty) return;
    if (!mounted) return;
    setState(() {
      if (index < queue.length - 1) {
        index++;
      } else {
        index = 0;
      }
      showBack = false;
      _stopAudio(notify: false);
    });
  }

  Future<void> _gradeCard(int quality) async {
    if (queue.isEmpty) return;
    final current = queue[index];
    final outcome = await flashcardService.reviewFlashcard(current.id, quality);
    if (outcome != null) {
      final pos = cards.indexWhere((c) => c.id == outcome.card.id);
      if (pos != -1) {
        cards[pos] = outcome.card;
      }
      _rebuildQueue();

      if (mounted) {
        final due = DateTime.fromMillisecondsSinceEpoch(outcome.dueAtMs).toLocal();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Scheduled in ${outcome.scheduledLabel} — due $due"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    if (!mounted) return;
    _next();
  }

  String _dueLabel(Flashcard card) {
    if (card.dueAt <= 0) return "new";
    try {
      return DateTime.fromMillisecondsSinceEpoch(card.dueAt).toLocal().toString();
    } catch (_) {
      return "new";
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      if (!mounted) return;
      setState(() {
        _audioPath = path;
        _isPlaying = true;
      });
    } catch (_) {}
  }

  void _stopAudio({bool notify = true}) {
    _player.stop();
    _isPlaying = false;
    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Review"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_onlyDue ? "No due cards" : "No cards"),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => setState(() {
                  _onlyDue = false;
                  _rebuildQueue();
                }),
                child: const Text("Show all cards"),
              ),
            ],
          ),
        ),
      );
    }

    final card = queue[index];
    final now = DateTime.now().millisecondsSinceEpoch;
    final dueToday = cards.where((c) => c.dueAt <= now && c.dueAt != 0).length;
    final newAvailable = cards.where((c) => c.dueAt == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _onlyDue = !_onlyDue;
                _rebuildQueue();
              });
            },
            child: Text(_onlyDue ? "Due only" : "All cards"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Card ${index + 1} of ${queue.length}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _onlyDue
                  ? "Due: $dueToday, New: ${newAvailable > _maxNewPerSession ? _maxNewPerSession : newAvailable}/$newAvailable"
                  : "Cards in session: ${queue.length}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GestureDetector(
                onTap: _flip,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(showBack),
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 640),
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              showBack ? card.back : card.front,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (card.imagePath != null &&
                                ((showBack && !card.imageOnFront) || (!showBack && card.imageOnFront)))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(card.imagePath!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            if (card.audioPath != null &&
                                ((showBack && !card.audioOnFront) || (!showBack && card.audioOnFront))) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _playAudio(card.audioPath!),
                                icon: Icon(_isPlaying && _audioPath == card.audioPath
                                    ? Icons.stop
                                    : Icons.volume_up_rounded),
                                label: Text(
                                  _isPlaying && _audioPath == card.audioPath ? "Stop audio" : "Play audio",
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              "Due: ${_dueLabel(card)}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => _gradeCard(0),
                  child: const Text("Again"),
                ),
                OutlinedButton(
                  onPressed: () => _gradeCard(2),
                  child: const Text("Hard"),
                ),
                FilledButton(
                  onPressed: () => _gradeCard(3),
                  child: const Text("Good"),
                ),
                FilledButton.tonal(
                  onPressed: () => _gradeCard(4),
                  child: const Text("Easy"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text("Skip"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopAudio(notify: false);
    _player.dispose();
    super.dispose();
  }
}
