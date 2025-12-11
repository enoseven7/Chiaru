import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../models/quiz_question.dart';
import '../services/quiz_service.dart';
import 'quiz_play_page.dart';

class QuizEditorPage extends StatefulWidget {
  final Quiz quiz;
  const QuizEditorPage({super.key, required this.quiz});

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  late Quiz quiz;
  List<QuizQuestion> questions = [];

  @override
  void initState() {
    super.initState();
    quiz = widget.quiz;
    _load();
  }

  Future<void> _load() async {
    questions = await quizService.getQuestions(quiz.id);
    setState(() {});
  }

  Future<String?> _pickFile(FileType type, {List<String>? extensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: extensions,
    );
    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }
    return null;
  }

  Future<void> _editQuizMeta() async {
    final title = TextEditingController(text: quiz.title);
    final desc = TextEditingController(text: quiz.description ?? '');
    bool immediate = quiz.immediateFeedback;
    bool countdown = quiz.countdown;
    final limit = TextEditingController(text: quiz.timeLimitSeconds.toString());

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => AlertDialog(
          title: const Text("Quiz settings"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: "Description"),
                  minLines: 1,
                  maxLines: 3,
                ),
                SwitchListTile(
                  title: const Text("Immediate feedback"),
                  value: immediate,
                  onChanged: (v) => setSheet(() => immediate = v),
                ),
                SwitchListTile(
                  title: const Text("Countdown timer"),
                  value: countdown,
                  onChanged: (v) => setSheet(() => countdown = v),
                ),
                if (countdown)
                  TextField(
                    controller: limit,
                    decoration: const InputDecoration(labelText: "Time limit (seconds)"),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                quiz
                  ..title = title.text.trim().isEmpty ? quiz.title : title.text.trim()
                  ..description = desc.text.trim().isEmpty ? null : desc.text.trim()
                  ..immediateFeedback = immediate
                  ..countdown = countdown
                  ..timeLimitSeconds = countdown ? int.tryParse(limit.text.trim()) ?? 0 : 0;
                await quizService.updateQuiz(quiz);
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editQuestion({QuizQuestion? question}) async {
    final isEdit = question != null;
    final prompt = TextEditingController(text: question?.prompt ?? '');
    final answer = TextEditingController(text: question?.answer ?? '');
    QuizQuestionType type = question?.type ?? QuizQuestionType.text;
    final options = (question?.options?.split('\n') ?? <String>[]);
    int correctIndex = question?.correctIndex ?? -1;
    String? imagePath = question?.imagePath;
    String? audioPath = question?.audioPath;
    String? videoPath = question?.videoPath;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) {
          void ensureOptionLength(int count) {
            while (options.length < count) {
              options.add('');
            }
          }

          return AlertDialog(
            title: Text(isEdit ? "Edit question" : "New question"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: prompt,
                    decoration: const InputDecoration(labelText: "Prompt"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<QuizQuestionType>(
                    value: type,
                    items: const [
                      DropdownMenuItem(
                        value: QuizQuestionType.text,
                        child: Text("Open-ended"),
                      ),
                      DropdownMenuItem(
                        value: QuizQuestionType.multipleChoice,
                        child: Text("Multiple choice"),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheet(() => type = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (type == QuizQuestionType.text)
                    TextField(
                      controller: answer,
                      decoration: const InputDecoration(labelText: "Expected answer"),
                    )
                  else
                    Column(
                      children: [
                        for (int i = 0; i < (options.isEmpty ? 4 : options.length); i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(labelText: "Option ${i + 1}"),
                                    controller: TextEditingController(
                                      text: i < options.length ? options[i] : '',
                                    ),
                                    onChanged: (val) {
                                      if (i >= options.length) ensureOptionLength(i + 1);
                                      options[i] = val;
                                    },
                                  ),
                                ),
                                Radio<int>(
                                  value: i,
                                  groupValue: correctIndex,
                                  onChanged: (v) {
                                    if (v != null) setSheet(() => correctIndex = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                        TextButton(
                          onPressed: () {
                            setSheet(() {
                              options.add('');
                              if (correctIndex == -1) correctIndex = 0;
                            });
                          },
                          child: const Text("Add option"),
                        )
                      ],
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.image_outlined),
                        label: const Text("Image"),
                        onPressed: () async {
                          final p = await _pickFile(FileType.image);
                          if (p != null) setSheet(() => imagePath = p);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text("Audio"),
                        onPressed: () async {
                          final p = await _pickFile(FileType.audio);
                          if (p != null) setSheet(() => audioPath = p);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.video_library_outlined),
                        label: const Text("Video"),
                        onPressed: () async {
                          final p = await _pickFile(FileType.custom, extensions: ['mp4', 'mov', 'mkv']);
                          if (p != null) setSheet(() => videoPath = p);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (imagePath != null) Text("Image: ${File(imagePath!).uri.pathSegments.last}"),
                  if (audioPath != null) Text("Audio: ${File(audioPath!).uri.pathSegments.last}"),
                  if (videoPath != null) Text("Video: ${File(videoPath!).uri.pathSegments.last}"),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(
                child: Text(isEdit ? "Save" : "Add"),
                onPressed: () async {
                  if (prompt.text.trim().isEmpty) return;
                  if (type == QuizQuestionType.multipleChoice) {
                    ensureOptionLength(options.length < 2 ? 2 : options.length);
                    options.removeWhere((o) => o.trim().isEmpty);
                    if (options.isEmpty) return;
                    if (correctIndex < 0 || correctIndex >= options.length) {
                      correctIndex = 0;
                    }
                  }

                  if (isEdit) {
                    question
                      ..prompt = prompt.text.trim()
                      ..type = type
                      ..answer = type == QuizQuestionType.text ? answer.text.trim() : options[correctIndex]
                      ..options = type == QuizQuestionType.multipleChoice ? options.join('\n') : null
                      ..correctIndex = type == QuizQuestionType.multipleChoice ? correctIndex : -1
                      ..imagePath = imagePath
                      ..audioPath = audioPath
                      ..videoPath = videoPath;
                    await quizService.updateQuestion(question);
                  } else {
                    await quizService.addQuestion(
                      quizId: quiz.id,
                      prompt: prompt.text.trim(),
                      type: type,
                      answer: type == QuizQuestionType.text ? answer.text.trim() : options[correctIndex],
                      options: type == QuizQuestionType.multipleChoice ? options : null,
                      correctIndex: type == QuizQuestionType.multipleChoice ? correctIndex : -1,
                      imagePath: imagePath,
                      audioPath: audioPath,
                      videoPath: videoPath,
                    );
                  }
                  await _load();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importQuiz() async {
    final pick = await FilePicker.platform.pickFiles(
      dialogTitle: "Import quiz (.json)",
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (pick == null || pick.files.single.path == null) return;
    try {
      final file = File(pick.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final newId = await quizService.importQuiz(quiz.topicId, data);
      final newQuizList = await quizService.getQuizzesByTopic(quiz.topicId);
      final imported = newQuizList.firstWhere((q) => q.id == newId, orElse: () => quiz);
      setState(() {
        quiz = imported;
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Quiz imported into this topic.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import failed: $e")));
      }
    }
  }

  Future<void> _exportQuiz() async {
    try {
      final data = await quizService.exportQuiz(quiz.id);
      if (data.isEmpty) return;
      final defaultName = '${quiz.title.replaceAll(' ', '_')}.json';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: "Export quiz",
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath == null) return;
      final file = File(savePath);
      await file.writeAsString(jsonEncode(data));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Exported to ${file.path}")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        actions: [
          IconButton(
            tooltip: "Settings",
            icon: const Icon(Icons.settings_outlined),
            onPressed: _editQuizMeta,
          ),
          IconButton(
            tooltip: "Import quiz",
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _importQuiz,
          ),
          IconButton(
            tooltip: "Export quiz",
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportQuiz,
          ),
          IconButton(
            tooltip: "Play quiz",
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizPlayPage(
                    quiz: quiz,
                    questions: questions,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editQuestion(),
        icon: const Icon(Icons.add),
        label: const Text("Add question"),
      ),
      body: questions.isEmpty
          ? const Center(child: Text("No questions yet."))
          : ListView.builder(
              itemCount: questions.length,
              itemBuilder: (_, i) {
                final q = questions[i];
                return Card(
                  color: colors.surfaceContainerHighest,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(q.prompt),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.type == QuizQuestionType.text
                            ? "Answer: ${q.answer ?? ''}"
                            : "Options: ${(q.options ?? '').replaceAll('\n', ', ')}"),
                        if (q.imagePath != null)
                          Text("Image: ${File(q.imagePath!).uri.pathSegments.last}",
                              style: textTheme.bodySmall),
                        if (q.audioPath != null)
                          Text("Audio: ${File(q.audioPath!).uri.pathSegments.last}",
                              style: textTheme.bodySmall),
                        if (q.videoPath != null)
                          Text("Video: ${File(q.videoPath!).uri.pathSegments.last}",
                              style: textTheme.bodySmall),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editQuestion(question: q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            await quizService.deleteQuestion(q.id);
                            await _load();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
