import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../pages/quiz_editor_page.dart';
import '../pages/subjects_panel.dart';
import '../pages/topics_panel.dart';
import '../services/quiz_service.dart';
import '../services/subject_services.dart';
import '../services/topic_service.dart';

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  List<Subject> subjects = [];
  List<Topic> topics = [];
  List<Quiz> quizzes = [];

  int selectedSubject = 0;
  int selectedTopic = 0;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    subjects = await subjectService.getSubjects();
    if (subjects.isNotEmpty) {
      selectedSubject = 0;
      await _loadTopics(subjects[0].id);
    } else {
      topics = [];
      quizzes = [];
      selectedSubject = 0;
      selectedTopic = 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTopics(int subjectId) async {
    topics = await topicService.getTopicsForSubject(subjectId);
    if (topics.isNotEmpty) {
      selectedTopic = 0;
      await _loadQuizzes(topics[0].id);
    } else {
      selectedTopic = 0;
      quizzes = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadQuizzes(int topicId) async {
    if (topicId == 0) {
      quizzes = [];
    } else {
      quizzes = await quizService.getQuizzesByTopic(topicId);
    }
    if (mounted) setState(() {});
  }

  Future<void> _addSubject() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Subject"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter subject name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await subjectService.addSubject(name);
                await _loadSubjects();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addTopic() async {
    if (subjects.isEmpty) return;
    final controller = TextEditingController();
    final subjectId = subjects[selectedSubject].id;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Topic"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter topic name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await topicService.addTopic(subjectId, name);
                await _loadTopics(subjectId);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addQuiz() async {
    if (topics.isEmpty || selectedTopic >= topics.length) return;
    final topicId = topics[selectedTopic].id;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Quiz"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Quiz title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final id = await quizService.createQuiz(topicId: topicId, title: name);
                await _loadQuizzes(topicId);
                if (!mounted) return;
                final quiz = quizzes.firstWhere((q) => q.id == id, orElse: () => Quiz()
                  ..id = id
                  ..topicId = topicId
                  ..title = name);
                Navigator.pop(context);
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizEditorPage(quiz: quiz)),
                );
                await _loadQuizzes(topicId);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete quiz?"),
        content: Text('This will remove "${quiz.title}" and its questions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await quizService.deleteQuiz(quiz.id);
      await _loadQuizzes(quiz.topicId);
    }
  }

  Future<void> _importQuiz(int topicId) async {
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
      await quizService.importQuiz(topicId, data);
      await _loadQuizzes(topicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz imported.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import failed: $e")));
      }
    }
  }

  Future<void> _exportQuiz(Quiz quiz) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Exported to ${file.path}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  Widget _buildQuizzesList(int currentTopicId) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (currentTopicId == 0) {
      return const Center(child: Text("Select a topic to see its quizzes."));
    }
    if (quizzes.isEmpty) {
      return const Center(child: Text("No quizzes yet. Add one to start."));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: quizzes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final quiz = quizzes[i];
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.onSurface.withOpacity(0.08)),
          ),
          child: ListTile(
            title: Text(
              quiz.title,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              quiz.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: "Export",
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () => _exportQuiz(quiz),
                ),
                IconButton(
                  tooltip: "Edit",
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuizEditorPage(quiz: quiz)),
                  ).then((_) => _loadQuizzes(quiz.topicId)),
                ),
                IconButton(
                  tooltip: "Delete",
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteQuiz(quiz),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuizEditorPage(quiz: quiz)),
            ).then((_) => _loadQuizzes(quiz.topicId)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSubjectId = (subjects.isNotEmpty && selectedSubject < subjects.length)
        ? subjects[selectedSubject].id
        : 0;
    final currentTopicId = (topics.isNotEmpty && selectedTopic < topics.length)
        ? topics[selectedTopic].id
        : 0;

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: SubjectsPanel(
              subjects: subjects,
              selectedIndex: selectedSubject,
              addSubject: _addSubject,
              onSelect: (i) async {
                setState(() {
                  selectedSubject = i;
                  selectedTopic = 0;
                  topics = [];
                  quizzes = [];
                });
                await _loadTopics(subjects[i].id);
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: TopicsPanel(
              topics: topics,
              subjectId: currentSubjectId,
              selectedIndex: selectedTopic,
              addTopic: _addTopic,
              onSelect: (i) async {
                if (i >= topics.length) return;
                setState(() {
                  selectedTopic = i;
                  quizzes = [];
                });
                await _loadQuizzes(topics[i].id);
              },
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.onSurface.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text("Quizzes", style: textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: currentTopicId == 0
                            ? null
                            : () => _importQuiz(currentTopicId),
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text("Import"),
                      ),
                      TextButton.icon(
                        onPressed: currentTopicId == 0 ? null : _addQuiz,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("New Quiz"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildQuizzesList(currentTopicId)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
