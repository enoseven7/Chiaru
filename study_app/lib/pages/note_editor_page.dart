import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteEditorPage extends StatefulWidget {
  final Note note;
  final Future<void> Function(Note) onSave;

  const NoteEditorPage({super.key, required this.note, required this.onSave});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.content);
  }

  Future<void> _save() async {
    widget.note.content = _controller.text;
    await widget.onSave(widget.note);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Note"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Write your note here...",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
