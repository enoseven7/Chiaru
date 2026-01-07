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
import '../services/ai_generation_service.dart';
import '../services/teach_service.dart';
import '../services/note_service.dart';
import '../services/note_title_service.dart';

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
  double subjectsWidth = 170;
  double topicsWidth = 220;
  bool subjectsCollapsed = false;
  bool topicsCollapsed = false;

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

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Subject?"),
            content: const Text("All topics and quizzes inside it will be removed."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    await subjectService.deleteSubject(subject.id);
    await _loadSubjects();
  }

  Future<void> _deleteTopic(Topic topic) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Topic?"),
            content: const Text("All quizzes inside this topic will also be deleted."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    await topicService.deleteTopic(topic.id);
    await _loadTopics(topic.subjectId);
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

  Future<void> _generateQuizWithAi(int topicId) async {
    final settings = await teachService.loadSettings();
    if ((settings.apiKey ?? '').trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add an AI API key in Settings > AI usage first.")),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final notes = await noteService.getNotesForTopic(topicId);
    final titleMap = await noteTitleService.loadTitles(notes.map((n) => n.id).toList());
    final Set<int> selectedNotes = {};
    int maxQuestions = 8;
    int tokenLimit = 768;
    List<String> pdfs = [];
    bool working = false;
    String status = "";

    int estimateTokens() {
      final base = [
        titleCtrl.text,
        descCtrl.text,
        ...selectedNotes
            .map((id) => notes.firstWhere((n) => n.id == id, orElse: () => notes.first).content)
            .map(aiGenerationService.extractNoteText),
      ].where((e) => e.trim().isNotEmpty).join("\n");
      return aiGenerationService.estimateTokens(base, perItem: 90, itemCount: maxQuestions);
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text("Generate quiz with AI"),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Quiz title"),
                      onChanged: (_) => setLocal(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: "Description (optional)"),
                      onChanged: (_) => setLocal(() {}),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      child: const Text("Include notes"),
                    ),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: notes.isEmpty
                          ? const Center(child: Text("No notes in this topic."))
                          : Scrollbar(
                              child: ListView.builder(
                                itemCount: notes.length,
                                itemBuilder: (_, idx) {
                                  final n = notes[idx];
                                  final text = aiGenerationService.extractNoteText(n.content);
                                  final title = noteTitleService.displayTitle(n.id, text, titleMap);
                                  final checked = selectedNotes.contains(n.id);
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onSecondaryTap: () async {
                                      final controller = TextEditingController(text: titleMap[n.id] ?? title);
                                      final newName = await showDialog<String>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Rename note"),
                                          content: TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(labelText: "Note name"),
                                            autofocus: true,
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, controller.text.trim()),
                                              child: const Text("Save"),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (newName != null && newName.isNotEmpty) {
                                        await noteTitleService.saveTitle(n.id, newName);
                                        setLocal(() {
                                          titleMap[n.id] = newName;
                                        });
                                      }
                                    },
                                    child: CheckboxListTile(
                                      dense: true,
                                      value: checked,
                                      title: Text(title),
                                      onChanged: (v) {
                                        setLocal(() {
                                          if (v == true) {
                                            selectedNotes.add(n.id);
                                          } else {
                                            selectedNotes.remove(n.id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text("PDFs: ${pdfs.length} selected")),
                        TextButton.icon(
                          onPressed: working
                              ? null
                              : () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                  );
                                  if (result != null) {
                                    setLocal(() {
                                      pdfs = result.paths.whereType<String>().toList();
                                    });
                                  }
                                },
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Add PDFs"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Max questions"),
                              Slider(
                                value: maxQuestions.toDouble(),
                                min: 4,
                                max: 20,
                                divisions: 16,
                                label: "$maxQuestions",
                                onChanged: working
                                    ? null
                                    : (v) => setLocal(() {
                                          maxQuestions = v.round();
                                        }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Token limit"),
                              Slider(
                                value: tokenLimit.toDouble(),
                                min: 256,
                                max: 2048,
                                divisions: 14,
                                label: "$tokenLimit",
                                onChanged: working
                                    ? null
                                    : (v) => setLocal(() {
                                          tokenLimit = v.round();
                                        }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Estimated tokens (notes only, PDFs not counted): ${estimateTokens()}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (status.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: working ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: working
                    ? null
                    : () async {
                        setLocal(() {
                          working = true;
                          status = "";
                        });
                        try {
                          final created = await aiGenerationService.generateQuiz(
                            topicId: topicId,
                            title: titleCtrl.text.trim().isEmpty ? "AI Quiz" : titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            notes: selectedNotes
                                    .map((id) => notes.firstWhere((n) => n.id == id).content)
                                    .map(aiGenerationService.extractNoteText)
                                    .where((t) => t.trim().isNotEmpty)
                                    .join("\n\n")
                                    .trim()
                                    .isEmpty
                                ? null
                                : selectedNotes
                                    .map((id) => notes.firstWhere((n) => n.id == id).content)
                                    .map(aiGenerationService.extractNoteText)
                                    .where((t) => t.trim().isNotEmpty)
                                    .join("\n\n")
                                    .trim(),
                            pdfPaths: pdfs,
                            maxQuestions: maxQuestions,
                            tokenLimit: tokenLimit,
                          );
                          if (!mounted) return;
                          await _loadQuizzes(topicId);
                          Navigator.pop(ctx);
                          if (created == 0) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text("No questions were generated.")));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Generated $created questions in a new quiz.")));
                          }
                        } catch (e) {
                          setLocal(() {
                            working = false;
                            status = e.toString();
                          });
                        }
                      },
                child: working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Generate"),
              ),
            ],
          );
        });
      },
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

  Future<void> _showQuizContextMenu(Offset position, Quiz quiz) async {
    final selection = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: const [
        PopupMenuItem(value: "edit", child: Text("Edit")),
        PopupMenuItem(value: "delete", child: Text("Delete")),
      ],
    );
    if (selection == "edit") {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizEditorPage(quiz: quiz)),
      );
      await _loadQuizzes(quiz.topicId);
    } else if (selection == "delete") {
      await _deleteQuiz(quiz);
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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) =>
              _showQuizContextMenu(details.globalPosition, quiz),
          child: Container(
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
          _ResizablePanel(
            width: subjectsCollapsed ? 56 : subjectsWidth,
            minWidth: 140,
            collapsed: subjectsCollapsed,
            onDrag: (delta) {
              setState(() {
                subjectsCollapsed = false;
                subjectsWidth = (subjectsWidth + delta).clamp(140, 320);
              });
            },
            onToggleCollapse: () => setState(() => subjectsCollapsed = !subjectsCollapsed),
            child: subjectsCollapsed
                ? _CollapsedRail(
                    label: "Subjects",
                    icon: Icons.book_outlined,
                    onExpand: () => setState(() => subjectsCollapsed = false),
                  )
                : SubjectsPanel(
                    subjects: subjects,
                    selectedIndex: selectedSubject,
                    addSubject: _addSubject,
                    onDelete: _deleteSubject,
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
          _ResizablePanel(
            width: topicsCollapsed ? 56 : topicsWidth,
            minWidth: 160,
            collapsed: topicsCollapsed,
            onDrag: (delta) {
              setState(() {
                topicsCollapsed = false;
                topicsWidth = (topicsWidth + delta).clamp(160, 340);
              });
            },
            onToggleCollapse: () => setState(() => topicsCollapsed = !topicsCollapsed),
            child: topicsCollapsed
                ? _CollapsedRail(
                    label: "Topics",
                    icon: Icons.label_outline,
                    onExpand: () => setState(() => topicsCollapsed = false),
                  )
                : TopicsPanel(
                    topics: topics,
                    subjectId: currentSubjectId,
                    selectedIndex: selectedTopic,
                    addTopic: _addTopic,
                    onDelete: _deleteTopic,
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
                        onPressed: currentTopicId == 0 ? null : () => _generateQuizWithAi(currentTopicId),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text("Generate with AI"),
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

class _ResizablePanel extends StatelessWidget {
  final double width;
  final double minWidth;
  final bool collapsed;
  final Widget child;
  final VoidCallback onToggleCollapse;
  final void Function(double delta) onDrag;

  const _ResizablePanel({
    required this.width,
    required this.minWidth,
    required this.collapsed,
    required this.child,
    required this.onToggleCollapse,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(child: child),
              Positioned(
                top: 8,
                right: 6,
                child: IconButton(
                  icon: Icon(
                    collapsed ? Icons.chevron_right : Icons.chevron_left,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  tooltip: collapsed ? "Expand" : "Collapse",
                  onPressed: onToggleCollapse,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
            child: Container(
              width: 8,
              height: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 2,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsedRail extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onExpand;

  const _CollapsedRail({
    required this.label,
    required this.icon,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onExpand,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: RotatedBox(
          quarterTurns: 3,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
