import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../models/topic.dart';

import '../pages/subjects_panel.dart';
import '../pages/topics_panel.dart';
import '../pages/note_editor_area.dart';

import '../services/subject_services.dart';
import '../services/topic_service.dart';

class NotesWorkspacePage extends StatefulWidget {
  const NotesWorkspacePage({super.key});

  @override
  State<NotesWorkspacePage> createState() => _NotesWorkspacePageState();
}

class _NotesWorkspacePageState extends State<NotesWorkspacePage> {
  List<Subject> subjects = [];
  List<Topic> topics = [];

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
      selectedSubject = 0;
      selectedTopic = 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTopics(int subjectId) async {
    topics = await topicService.getTopicsForSubject(subjectId);
    selectedTopic = 0;
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

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Subject?"),
            content: const Text("All topics and notes inside it will be removed."),
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
            content: const Text("All notes inside this topic will also be deleted."),
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

  @override
  Widget build(BuildContext context) {
    final currentSubjectId = (subjects.isNotEmpty && selectedSubject < subjects.length)
        ? subjects[selectedSubject].id
        : 0;
    final currentTopicId = (topics.isNotEmpty && selectedTopic < topics.length)
        ? topics[selectedTopic].id
        : 0;

    return Row(
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
                  onSelect: (i) {
                    if (i >= topics.length) return;
                    setState(() {
                      selectedTopic = i;
                    });
                  },
                ),
        ),
        Expanded(
          child: NoteEditorArea(
            subjectId: currentSubjectId,
            topicId: currentTopicId,
          ),
        )
      ],
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
