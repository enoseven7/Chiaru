import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../models/note.dart';
import 'note_editor_page.dart';
import '../services/note_service.dart';

class NotesListPage extends StatefulWidget {
  final Topic topic;

  const NotesListPage({super.key, required this.topic});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
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
            await noteService.addNote(newNote.topicId, newNote.content);
            await _loadNotes();
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
            await _loadNotes();
          },
        ),
      ),
    );
  }

  Future<void> _loadNotes() async {
    notes = await noteService.getNotesForTopic(widget.topic.id);
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

                return ListTile(
                  title: Text(note.content.isEmpty
                      ? "(Empty note)"
                      : note.content.split('\n').first),
                  onTap: () => _openNote(note),
                );
              },
            ),
    );
  }
}
