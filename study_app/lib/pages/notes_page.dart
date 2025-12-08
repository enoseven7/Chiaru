import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/subject_services.dart';
import 'topics_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Subject> subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    subjects = await subjectService.getSubjects();
    if (mounted) setState(() {});
  }

  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';

        return AlertDialog(
          title: const Text('New Subject'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Enter subject name'),
            onChanged: (value) => name = value,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (name.trim().isEmpty) return;

                await subjectService.addSubject(name.trim());
                await _loadSubjects();

                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _openSubject(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TopicsPage(subject: subject)),
    ).then((_) => _loadSubjects());
  }

  void _showSubjectMenu(Subject subject) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Rename"),
                onTap: () {
                  Navigator.pop(context);
                  _renameSubject(subject);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await subjectService.deleteSubject(subject.id);
                  await _loadSubjects();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _renameSubject(Subject subject) {
    String name = subject.name;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Rename Subject"),
          content: TextField(
            controller: TextEditingController(text: name),
            onChanged: (val) => name = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;

                subject.name = name.trim();

                await subjectService.updateSubject(subject);
                await _loadSubjects();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: const Icon(Icons.add),
      ),
      body: subjects.isEmpty
          ? const Center(child: Text("No subjects yet. Add one!"))
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];

                return Dismissible(
                  key: ValueKey(subject.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Subject?"),
                        content: const Text(
                          "All topics and notes inside it will be removed.",
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
                  },
                  onDismissed: (_) async {
                    await subjectService.deleteSubject(subject.id);
                    await _loadSubjects();
                  },
                  child: ListTile(
                    title: Text(subject.name),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _openSubject(subject),
                    onLongPress: () => _showSubjectMenu(subject),
                  ),
                );
              },
            ),
    );
  }
}
