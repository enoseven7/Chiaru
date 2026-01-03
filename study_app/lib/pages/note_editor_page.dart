import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:study_app/services/note_service.dart';
import '../services/note_title_service.dart';
import '../models/note.dart';
import 'package:flutter_quill/flutter_quill.dart';


class NoteEditorPage extends StatefulWidget {
  final Note note;
  final Future<int> Function(Note) onSave;
  final Future<void> Function(int id, String title) onSaveTitle;

  const NoteEditorPage({super.key, required this.note, required this.onSave, required this.onSaveTitle});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late QuillController _controller;
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final doc = widget.note.content.isEmpty
        ? Document()
        : Document.fromJson(jsonDecode(widget.note.content));
    _loadTitle();
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _loadTitle() async {
    final titleMap = await noteTitleService.loadTitles([widget.note.id]);
    final title = titleMap[widget.note.id] ?? '';
    _titleController.text = title;
    setState(() {});
  }

  Future<void> _save() async {
    widget.note.content = jsonEncode(_controller.document.toDelta().toJson());
    final id = await widget.onSave(widget.note);
    await widget.onSaveTitle(id, _titleController.text.trim());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
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
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title (optional)"),
            ),
            const SizedBox(height: 10),
            QuillSimpleToolbar(controller: _controller),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: QuillEditor.basic(
                  controller: _controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
