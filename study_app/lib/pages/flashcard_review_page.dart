import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const int _maxReviewPerSession = 200;
  List<Flashcard> cards = [];
  List<Flashcard> queue = [];
  int index = 0;
  bool showBack = false;
  late final AudioPlayer _player;
  bool _isPlaying = false;
  String? _audioPath;
  bool _onlyDue = true;
  int _dueLearning = 0;
  int _dueReview = 0;
  int _dueNew = 0;
  int _introducedToday = 0;
  late String _todayKey;
  final Set<int> _seenNewIds = {};

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
    _todayKey = _todayString();
    await _loadDailyNewState();
    _seenNewIds.clear();
    _rebuildQueue(startIndex: widget.startIndex);
  }

  void _rebuildQueue({int? startIndex}) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Categorize cards
    final learningDueNow =
        cards.where((c) => c.intervalDays == 0 && c.dueAt != 0 && c.dueAt <= nowMs).toList();
    final learningSoon =
        cards.where((c) => c.intervalDays == 0 && c.dueAt != 0 && c.dueAt > nowMs).toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final reviewDue = cards.where((c) => c.dueAt <= nowMs && c.intervalDays > 0).toList();
    final reviewLimited = reviewDue.take(_maxReviewPerSession).toList();
    final newUnseen = cards.where((c) => c.dueAt == 0 && !_seenNewIds.contains(c.id)).toList();
    final quota = (_maxNewPerSession - _introducedToday).clamp(0, _maxNewPerSession);
    final newCards = quota > 0 ? newUnseen.take(quota).toList() : <Flashcard>[];

    // Counts reflect total cards in each phase
    _dueLearning = cards.where((c) => c.intervalDays == 0 && c.dueAt != 0).length;
    _dueReview = cards.where((c) => c.intervalDays > 0).length;
    _dueNew = min(quota, cards.where((c) => c.dueAt == 0).length);

    if (_onlyDue) {
      // Anki-like behavior: mix learning, review, and new cards
      final combined = <Flashcard>[];

      // Add all learning cards that are due now
      combined.addAll(learningDueNow);

      // Add review cards
      combined.addAll(reviewLimited);

      // Add new cards progressively (interleaved with learning/review)
      // This ensures new cards are introduced gradually throughout the session
      final newCardsToAdd = min(newCards.length, max(1, (combined.length / 4).ceil()));
      combined.addAll(newCards.take(newCardsToAdd));

      // If queue is empty but we have learning cards coming up soon, show them
      if (combined.isEmpty && learningSoon.isNotEmpty) {
        final soon = learningSoon.first;
        final delta = soon.dueAt - nowMs;
        // Show cards due within next 60 seconds
        if (delta <= 60000) {
          combined.add(soon);
        }
      }

      // Sort by priority: learning first (by due time), then reviews, then new
      combined.sort((a, b) {
        // Both are learning
        if (a.intervalDays == 0 && b.intervalDays == 0) {
          return a.dueAt.compareTo(b.dueAt);
        }
        // a is learning, b is not - a comes first
        if (a.intervalDays == 0) return -1;
        if (b.intervalDays == 0) return 1;
        // Both are review or new - sort by due date
        return a.dueAt.compareTo(b.dueAt);
      });

      queue = combined;
    } else {
      queue = List<Flashcard>.from(cards)..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    }

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
    final wasNew = current.dueAt == 0;
    final outcome = await flashcardService.reviewFlashcard(current.id, quality);
    if (outcome != null) {
      final pos = cards.indexWhere((c) => c.id == outcome.card.id);
      if (pos != -1) {
        cards[pos] = outcome.card;
      }
      if (wasNew) {
        _seenNewIds.add(current.id);
        _introducedToday += 1;
        await _saveDailyNewState();
      }
      _rebuildQueue();

      if (mounted) {
        final due = DateTime.fromMillisecondsSinceEpoch(outcome.dueAtMs).toLocal();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Scheduled in ${outcome.scheduledLabel} (due $due)"),
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

  // Predict next interval label for a given quality, without mutating the card.
  String _intervalLabelFor(Flashcard card, int quality) {
    // Mirror scheduler constants.
    const learningSteps = [1, 10]; // minutes
    const graduatingDays = 1;
    const easyDays = 4;
    const easyBonus = 1.3;
    const hardFactor = 1.2;
    const lapseFactor = 0.5;
    const minIntervalDays = 1;

    final q = quality.clamp(0, 4);
    final isLearning = card.intervalDays == 0;
    final isNew = card.dueAt == 0 && card.repetitions == 0 && card.intervalDays == 0;

    if (isLearning || isNew) {
      int stepIndex = card.repetitions.clamp(0, learningSteps.length - 1);
      if (q == 0) {
        return "<${learningSteps.first}m";
      } else if (q == 2) {
        return "<${learningSteps[stepIndex]}m";
      } else if (q == 3) {
        if (stepIndex < learningSteps.length - 1) {
          return "<${learningSteps[stepIndex + 1]}m";
        }
        return "${graduatingDays}d";
      } else {
        return "${easyDays}d";
      }
    } else {
      double ease = card.easeFactor;
      int intervalDays = card.intervalDays;
      if (q == 0) {
        final reduced = max(minIntervalDays, (intervalDays * lapseFactor).round());
        return "<${learningSteps.first}m";
      } else if (q == 2) {
        intervalDays = max(minIntervalDays, (intervalDays * hardFactor).round());
      } else if (q == 3) {
        intervalDays = max(minIntervalDays, (intervalDays * ease).round());
      } else {
        intervalDays = max(minIntervalDays, (intervalDays * ease * easyBonus).round());
      }
      if (intervalDays < 1) return "<1d";
      return "${intervalDays}d";
    }
  }

  List<String> _audioPathsForSide(Flashcard card, bool showBack) {
    final raw = card.audioPath;
    if (raw == null || raw.isEmpty) return [];
    try {
      if (raw.trim().startsWith('{')) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final front = (decoded['front'] as List<dynamic>? ?? []).cast<String>();
        final back = (decoded['back'] as List<dynamic>? ?? []).cast<String>();
        return showBack ? back : front;
      }
      if (raw.trim().startsWith('[')) {
        final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
        return list;
      }
    } catch (_) {}
    final isFront = card.audioOnFront;
    return ((showBack && !isFront) || (!showBack && isFront)) ? [raw] : [];
  }

  String _humanDuration(Duration d) {
    if (d.inSeconds <= 0) return "now";
    if (d.inMinutes < 1) return "<1m";
    if (d.inHours < 1) return "${d.inMinutes}m";
    if (d.inDays < 1) {
      final hrs = d.inHours;
      final mins = d.inMinutes % 60;
      return mins == 0 ? "${hrs}h" : "${hrs}h ${mins}m";
    }
    final days = d.inDays;
    final hrs = d.inHours % 24;
    return hrs == 0 ? "${days}d" : "${days}d ${hrs}h";
  }

  String _todayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadDailyNewState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDay = prefs.getString("deck_${widget.deck.id}_new_day");
    if (storedDay == _todayKey) {
      _introducedToday = prefs.getInt("deck_${widget.deck.id}_new_count") ?? 0;
    } else {
      _introducedToday = 0;
      await prefs.setString("deck_${widget.deck.id}_new_day", _todayKey);
      await prefs.setInt("deck_${widget.deck.id}_new_count", 0);
    }
  }

  Future<void> _saveDailyNewState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("deck_${widget.deck.id}_new_day", _todayKey);
    await prefs.setInt("deck_${widget.deck.id}_new_count", _introducedToday);
  }

  @override
  Widget build(BuildContext context) {
    final newRemaining = (_maxNewPerSession - _introducedToday).clamp(0, _maxNewPerSession);
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
              Text(_onlyDue ? "All cards for today are done" : "No cards"),
              const SizedBox(height: 8),
              if (cards.any((c) => c.dueAt == 0)) ...[
                const SizedBox(height: 10),
                Text(
                  "New remaining today: $newRemaining",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                if (newRemaining > 0)
                  FilledButton(
                    onPressed: () => setState(() {
                      _onlyDue = false;
                      _rebuildQueue();
                    }),
                    child: const Text("Introduce more new cards"),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    final card = queue[index];
    final now = DateTime.now().millisecondsSinceEpoch;
    final newAvailable = cards.where((c) => c.dueAt == 0).length;
    final audioPaths = _audioPathsForSide(card, showBack);

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
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _StatChip(label: "Learning", value: _dueLearning, color: Colors.redAccent),
                _StatChip(label: "Review", value: _dueReview, color: Colors.green),
                _StatChip(
                  label: "New",
                  value: _onlyDue
                      ? (newRemaining < _dueNew ? newRemaining : _dueNew)
                      : _dueNew,
                  color: Colors.blue,
                  suffix: _onlyDue && _dueNew > newRemaining ? "/$_dueNew" : null,
                ),
              ],
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
                            if (audioPaths.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final path in audioPaths)
                                    FilledButton.icon(
                                      onPressed: () => _playAudio(path),
                                      icon: Icon(
                                        _isPlaying && _audioPath == path
                                            ? Icons.stop
                                            : Icons.volume_up_rounded,
                                      ),
                                      label: Text(
                                        _isPlaying && _audioPath == path ? "Stop audio" : "Play audio",
                                      ),
                                    ),
                                ],
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
                _GradeButton(
                  label: "Again",
                  intervalLabel: _intervalLabelFor(card, 0),
                  style: GradeButtonStyle.outlined,
                  onTap: () => _gradeCard(0),
                ),
                _GradeButton(
                  label: "Hard",
                  intervalLabel: _intervalLabelFor(card, 2),
                  style: GradeButtonStyle.outlined,
                  onTap: () => _gradeCard(2),
                ),
                _GradeButton(
                  label: "Good",
                  intervalLabel: _intervalLabelFor(card, 3),
                  style: GradeButtonStyle.filled,
                  onTap: () => _gradeCard(3),
                ),
                _GradeButton(
                  label: "Easy",
                  intervalLabel: _intervalLabelFor(card, 4),
                  style: GradeButtonStyle.tonal,
                  onTap: () => _gradeCard(4),
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

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final String? suffix;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            "$label: $value${suffix ?? ''}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

enum GradeButtonStyle { outlined, filled, tonal }

class _GradeButton extends StatelessWidget {
  final String label;
  final String intervalLabel;
  final GradeButtonStyle style;
  final VoidCallback onTap;

  const _GradeButton({
    required this.label,
    required this.intervalLabel,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final intervalText = Text(
      intervalLabel,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );

    Widget button;
    switch (style) {
      case GradeButtonStyle.outlined:
        button = OutlinedButton(onPressed: onTap, child: Text(label));
        break;
      case GradeButtonStyle.filled:
        button = FilledButton(onPressed: onTap, child: Text(label));
        break;
      case GradeButtonStyle.tonal:
        button = FilledButton.tonal(onPressed: onTap, child: Text(label));
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        intervalText,
        const SizedBox(height: 4),
        button,
      ],
    );
  }
}
