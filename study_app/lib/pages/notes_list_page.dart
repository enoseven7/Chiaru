import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../models/note.dart';
import 'note_editor_page.dart';
import '../services/note_service.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import '../services/note_title_service.dart';

class NotesListPage extends StatefulWidget {
  final Topic topic;

  const NotesListPage({super.key, required this.topic});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Note> notes = [];
  Map<int, String> titles = {};

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _showNoteMenu(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit"),
                onTap: () {
                  Navigator.pop(context);
                  _openNote(note);
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
                  await noteService.deleteNote(note.id);
                  await _loadNotes();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(
          note: Note()
            ..topicId = widget.topic.id
            ..content = "",
          onSave: (newNote) async {
            final id = await noteService.addNote(newNote.topicId, newNote.content);
            if (newNote.id == 0) newNote.id = id;
            return id;
          },
          onSaveTitle: (id, title) async {
            if (id > 0 && title.trim().isNotEmpty) {
              await noteTitleService.saveTitle(id, title);
            }
          },
        ),
      ),
    );
  }

  void _openNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(
          note: note,
          onSave: (updated) async {
            await noteService.updateNote(updated);
            return updated.id;
          },
          onSaveTitle: (id, title) async {
            if (id > 0 && title.trim().isNotEmpty) {
              await noteTitleService.saveTitle(id, title);
            }
          },
        ),
      ),
    );
  }

  String _getNotePreviewLine(Note note) {
    if (note.content.isEmpty) return "(Empty note)";

    try {
      final preview = Document.fromJson(jsonDecode(note.content)).toPlainText().trim();

      if (preview.isEmpty) return "(Empty note)";
      return preview.split('\n').first;
    } catch (_) {
      return "(Invalid note data)";
    }
  }

  String _getNotePreviewParagraph(Note note) {
    try {
      final preview = Document.fromJson(jsonDecode(note.content)).toPlainText().trim();

      if (preview.isEmpty) return "";
      if (preview.length <= 50) return preview;

      return "${preview.substring(0, 50)}...";
    } catch (_) {
      return "";
    }
  }

  Future<void> _loadNotes() async {
    notes = await noteService.getNotesForTopic(widget.topic.id);
    titles = await noteTitleService.loadTitles(notes.map((n) => n.id).toList());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
      body: notes.isEmpty
          ? const Center(child: Text("No notes yet. Add one!"))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final text = _getNotePreviewParagraph(note);
                final title = titles[note.id] ??
                    (text.isEmpty
                        ? "(Untitled note)"
                        : (text.length > 30 ? "${text.substring(0, 30)}..." : text));

                return ListTile(
                  leading: const Icon(Icons.note_alt),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.drive_file_rename_outline),
                    tooltip: "Rename",
                    onPressed: () async {
                      final controller = TextEditingController(text: titles[note.id] ?? title);
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Rename note"),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(labelText: "Note title"),
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
                        await noteTitleService.saveTitle(note.id, newName);
                        await _loadNotes();
                      }
                    },
                  ),
                  onTap: () => _openNote(note),
                  onLongPress: () => _showNoteMenu(note),
                );
              },
            ),
    );
  }
}

