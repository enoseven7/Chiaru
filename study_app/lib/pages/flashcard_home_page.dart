import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/flashcard_deck.dart';
import '../models/subject.dart';
import '../models/topic.dart';

import '../pages/flashcard_editor_page.dart';
import '../pages/flashcard_review_page.dart';
import '../pages/subjects_panel.dart';
import '../pages/topics_panel.dart';

import '../services/flashcard_service.dart';
import '../services/subject_services.dart';
import '../services/topic_service.dart';
import '../services/ai_generation_service.dart';
import '../services/teach_service.dart';
import '../services/note_service.dart';
import '../services/note_title_service.dart';

class FlashcardHomePage extends StatefulWidget {
  const FlashcardHomePage({super.key});

  @override
  State<FlashcardHomePage> createState() => _FlashcardHomePageState();
}

class _FlashcardHomePageState extends State<FlashcardHomePage> {
  List<Subject> subjects = [];
  List<Topic> topics = [];
  List<FlashcardDeck> decks = [];

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
      decks = [];
      selectedSubject = 0;
      selectedTopic = 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTopics(int subjectId) async {
    topics = await topicService.getTopicsForSubject(subjectId);
    if (topics.isNotEmpty) {
      selectedTopic = 0;
      await _loadDecks(topics[0].id);
    } else {
      selectedTopic = 0;
      decks = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadDecks(int topicId) async {
    if (topicId == 0) {
      decks = [];
    } else {
      decks = await flashcardService.getDecksByTopic(topicId);
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await subjectService.addSubject(name);
                await _loadSubjects();
              }
              if (!mounted) return;
              Navigator.pop(context);
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await topicService.addTopic(subjectId, name);
                await _loadTopics(subjectId);
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addDeck() async {
    if (topics.isEmpty || selectedTopic >= topics.length) return;

    final controller = TextEditingController();
    final topicId = topics[selectedTopic].id;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Deck"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter deck name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newDeckId = await flashcardService.createDeck(topicId, name);
                await _loadDecks(topicId);
                final newDeck = decks.firstWhere(
                  (d) => d.id == newDeckId,
                  orElse: () => FlashcardDeck()
                    ..id = newDeckId
                    ..topicId = topicId
                    ..name = name,
                );
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlashcardsEditorPage(deck: newDeck),
                  ),
                );
                await _loadDecks(topicId);
                return;
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _generateWithAi(int topicId) async {
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
    int maxCards = 10;
    int tokenLimit = 512;
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
      return aiGenerationService.estimateTokens(base, perItem: 60, itemCount: maxCards);
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text("Generate deck with AI"),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Deck title"),
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
                      Expanded(
                        child: Text("PDFs: ${pdfs.length} selected"),
                      ),
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
                            const Text("Max cards"),
                            Slider(
                              value: maxCards.toDouble(),
                              min: 5,
                              max: 30,
                              divisions: 25,
                              label: "$maxCards",
                              onChanged: working
                                  ? null
                                  : (v) => setLocal(() {
                                        maxCards = v.round();
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
                          final created = await aiGenerationService.generateFlashcards(
                            topicId: topicId,
                            title: titleCtrl.text.trim().isEmpty ? "AI Deck" : titleCtrl.text.trim(),
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
                            maxCards: maxCards,
                            tokenLimit: tokenLimit,
                          );
                          if (!mounted) return;
                          await _loadDecks(topicId);
                          Navigator.pop(ctx);
                          if (created == 0) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text("No cards were generated.")));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Generated $created cards in a new deck.")));
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

  Future<void> _deleteDeck(FlashcardDeck deck) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete deck?"),
        content: Text(
          "All cards in \"${deck.name}\" will be removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      await flashcardService.deleteDeck(deck.id);
      await _loadDecks(deck.topicId);
    }
  }

  Future<void> _importDeckFromFile(int topicId) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: "Import deck (.json)",
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      await flashcardService.importDeckData(topicId, data);
      await _loadDecks(topicId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deck imported successfully.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to import deck: $e")),
      );
    }
  }

  Future<void> _importAnkiDeck(int topicId) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: "Import Anki deck (.apkg)",
      type: FileType.custom,
      allowedExtensions: ['apkg'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    try {
      await flashcardService.importAnkiApkg(topicId, path);
      await _loadDecks(topicId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anki deck imported.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to import Anki deck: $e")),
      );
    }
  }

  Widget _buildDecksList(int currentTopicId) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (currentTopicId == 0) {
      return const Center(child: Text("Select a topic to see its decks."));
    }

    if (decks.isEmpty) {
      return const Center(child: Text("No decks yet. Add one to start."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: decks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final deck = decks[i];
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.onSurface.withOpacity(0.08)),
          ),
          child: ListTile(
            title: Text(
              deck.name,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              "Deck ID: ${deck.id}",
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Review",
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardReviewPage(deck: deck),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Edit",
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardsEditorPage(deck: deck),
                    ),
                  ).then((_) => _loadDecks(deck.topicId)),
                ),
                IconButton(
                  tooltip: "Delete",
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteDeck(deck),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardsEditorPage(deck: deck),
              ),
            ).then((_) => _loadDecks(deck.topicId)),
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
                    onSelect: (i) async {
                      setState(() {
                        selectedSubject = i;
                        selectedTopic = 0;
                        topics = [];
                        decks = [];
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
                    onSelect: (i) async {
                      if (i >= topics.length) return;
                      setState(() {
                        selectedTopic = i;
                        decks = [];
                      });
                      await _loadDecks(topics[i].id);
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
                      Text(
                        "Decks",
                        style: textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: currentTopicId == 0
                            ? null
                            : () => _importAnkiDeck(currentTopicId),
                        icon: const Icon(Icons.cloud_download_outlined, size: 18),
                        label: const Text("Import .apkg"),
                      ),
                      TextButton.icon(
                        onPressed: currentTopicId == 0
                            ? null
                            : () => _importDeckFromFile(currentTopicId),
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text("Import Deck"),
                      ),
                      TextButton.icon(
                        onPressed: currentTopicId == 0 ? null : () => _generateWithAi(currentTopicId),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text("Generate with AI"),
                      ),
                      TextButton.icon(
                        onPressed: currentTopicId == 0 ? null : _addDeck,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("New Deck"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildDecksList(currentTopicId)),
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
