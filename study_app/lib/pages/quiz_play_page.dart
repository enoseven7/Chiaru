import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../models/quiz_question.dart';

class QuizPlayPage extends StatefulWidget {
  final Quiz quiz;
  final List<QuizQuestion> questions;
  const QuizPlayPage({super.key, required this.quiz, required this.questions});

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  late List<QuizQuestion> questions;
  int index = 0;
  final Map<int, dynamic> answers = {};
  final Map<int, bool> results = {};
  Timer? _timer;
  int elapsedSeconds = 0;
  int remainingSeconds = 0;
  late bool countdown;
  late bool immediate;
  bool completed = false;
  late AudioPlayer _player;
  bool _playingAudio = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    questions = List.of(widget.questions);
    countdown = widget.quiz.countdown && widget.quiz.timeLimitSeconds > 0;
    remainingSeconds = widget.quiz.timeLimitSeconds;
    immediate = widget.quiz.immediateFeedback;
    _player = AudioPlayer();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingAudio = false);
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedSeconds += 1;
        if (countdown) {
          if (remainingSeconds > 0) {
            remainingSeconds -= 1;
          } else {
            completed = true;
            _timer?.cancel();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _submitAnswer(dynamic value) {
    if (completed) return;
    final q = questions[index];
    answers[q.id] = value;
    if (immediate) {
      final isCorrect = _isCorrect(q, value);
      results[q.id] = isCorrect;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? "Correct" : "Incorrect"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
    if (index < questions.length - 1) {
      setState(() => index += 1);
    } else {
      setState(() => completed = true);
      _timer?.cancel();
    }
  }

  bool _isCorrect(QuizQuestion q, dynamic value) {
    if (q.type == QuizQuestionType.multipleChoice) {
      return (value is int) && value == q.correctIndex;
    }
    final expected = (q.answer ?? '').trim().toLowerCase();
    final given = (value?.toString() ?? '').trim().toLowerCase();
    return expected.isNotEmpty && expected == given;
  }

  String _timeLabel() {
    if (countdown) {
      final m = remainingSeconds ~/ 60;
      final s = remainingSeconds % 60;
      return "-${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    } else {
      final m = elapsedSeconds ~/ 60;
      final s = elapsedSeconds % 60;
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      if (!mounted) return;
      setState(() {
        _playingAudio = true;
        _audioPath = path;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz")),
        body: const Center(child: Text("No questions.")),
      );
    }

    if (completed) {
      final total = questions.length;
      final correct = results.values.where((v) => v == true).length;
      return Scaffold(
        appBar: AppBar(title: const Text("Review")),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Score: $correct / $total",
                style: textTheme.titleMedium?.copyWith(color: colors.primary)),
            const SizedBox(height: 12),
            for (final q in questions)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.prompt, style: textTheme.bodyLarge),
                      const SizedBox(height: 6),
                      Text("Your answer: ${_answerLabel(q, answers[q.id])}"),
                      Text("Correct: ${_correctLabel(q)}",
                          style: textTheme.bodySmall?.copyWith(color: colors.primary)),
                      if (results.containsKey(q.id))
                        Text(results[q.id]! ? "Correct" : "Incorrect",
                            style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final q = questions[index];
    final currentAnswer = answers[q.id];

    return Scaffold(
      appBar: AppBar(
        title: Text("Question ${index + 1} / ${questions.length}"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Chip(
              label: Text(_timeLabel()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(q.prompt, style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (q.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(q.imagePath!), height: 180, fit: BoxFit.cover),
              ),
            if (q.audioPath != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _playAudio(q.audioPath!),
                icon: Icon(_playingAudio && _audioPath == q.audioPath ? Icons.stop : Icons.volume_up),
                label: Text(_playingAudio && _audioPath == q.audioPath ? "Stop" : "Play audio"),
              ),
            ],
            if (q.videoPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Video attached: ${File(q.videoPath!).uri.pathSegments.last}"),
              ),
            const SizedBox(height: 12),
            if (q.type == QuizQuestionType.text)
              TextField(
                decoration: const InputDecoration(labelText: "Your answer"),
                onChanged: (v) => answers[q.id] = v,
              )
            else
              Column(
                children: [
                  for (int i = 0; i < (q.options?.split('\n').length ?? 0); i++)
                    RadioListTile<int>(
                      value: i,
                      groupValue: currentAnswer is int ? currentAnswer : null,
                      onChanged: (v) => setState(() => answers[q.id] = v),
                      title: Text(q.options!.split('\n')[i]),
                    )
                ],
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: index > 0
                      ? () => setState(() {
                            index -= 1;
                          })
                      : null,
                  child: const Text("Back"),
                ),
                FilledButton(
                  onPressed: () => _submitAnswer(
                    q.type == QuizQuestionType.text ? answers[q.id] ?? '' : answers[q.id],
                  ),
                  child: Text(index == questions.length - 1 ? "Finish" : "Next"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _answerLabel(QuizQuestion q, dynamic a) {
    if (q.type == QuizQuestionType.multipleChoice) {
      final opts = q.options?.split('\n') ?? [];
      if (a is int && a >= 0 && a < opts.length) return opts[a];
      return "(no answer)";
    }
    return (a?.toString().isEmpty ?? true) ? "(no answer)" : a.toString();
  }

  String _correctLabel(QuizQuestion q) {
    if (q.type == QuizQuestionType.multipleChoice) {
      final opts = q.options?.split('\n') ?? [];
      if (q.correctIndex >= 0 && q.correctIndex < opts.length) return opts[q.correctIndex];
    }
    return q.answer ?? '';
  }
}
