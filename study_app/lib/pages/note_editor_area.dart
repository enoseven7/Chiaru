import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../models/note.dart';
import '../services/note_service.dart';

class NoteEditorArea extends StatefulWidget {
  final int subjectId;
  final int topicId;

  const NoteEditorArea({
    super.key,
    required this.subjectId,
    required this.topicId,
  });

  @override
  State<NoteEditorArea> createState() => _NoteEditorAreaState();
}

class _NoteEditorAreaState extends State<NoteEditorArea> {
  QuillController? _quillController;
  List<Note> _notes = [];
  Note? _activeNote;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllerForNote(null);
    _loadNotesForTopic();
  }

  @override
  void didUpdateWidget(NoteEditorArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topicId != widget.topicId) {
      () async {
        await _saveCurrentNote();
      }();
      _loadNotesForTopic();
    }
  }

  @override
  void dispose() {
    () async {
      await _saveCurrentNote();
    }();
    _quillController?.dispose();
    super.dispose();
  }

  Document _documentFromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return Document();
    try {
      return Document.fromJson(jsonDecode(raw));
    } catch (_) {
      return Document();
    }
  }

  void _initControllerForNote(Note? note) {
    _quillController?.dispose();
    _quillController = QuillController(
      document: _documentFromRaw(note?.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _loadNotesForTopic({bool selectNewest = false}) async {
    final topicId = widget.topicId;
    setState(() {
      _isLoading = true;
      _notes = [];
      _activeNote = null;
    });

    if (topicId == 0) {
      _initControllerForNote(null);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final previousNoteId = selectNewest ? null : _activeNote?.id;
    final notes = await noteService.getNotesForTopic(topicId);

    if (!mounted || widget.topicId != topicId) return;

    Note? nextNote;
    if (notes.isNotEmpty) {
      if (selectNewest) {
        nextNote = notes.last;
      } else {
        nextNote = notes.firstWhere(
          (n) => n.id == previousNoteId,
          orElse: () => notes.first,
        );
      }
    }

    setState(() {
      _notes = notes;
      _activeNote = nextNote;
      _isLoading = false;
    });
    _initControllerForNote(_activeNote);
  }

  Future<void> _saveCurrentNote() async {
    if (_activeNote == null || _quillController == null) return;

    final updatedContent = jsonEncode(
      _quillController!.document.toDelta().toJson(),
    );

    if (_activeNote!.content == updatedContent) return;

    _activeNote!.content = updatedContent;
    await noteService.updateNote(_activeNote!);

    final idx = _notes.indexWhere((n) => n.id == _activeNote!.id);
    if (idx != -1) {
      setState(() {
        _notes[idx] = _activeNote!;
      });
    }
  }

  Future<void> _createNote() async {
    if (widget.topicId == 0) return;

    await _saveCurrentNote();
    await noteService.addNote(widget.topicId, "");
    await _loadNotesForTopic(selectNewest: true);
  }

  Future<void> _selectNote(Note note) async {
    if (_activeNote?.id == note.id) return;

    await _saveCurrentNote();
    setState(() {
      _activeNote = note;
    });
    _initControllerForNote(note);
  }

  String _notePreview(Note note) {
    if (note.content.isEmpty) return "(Empty note)";
    try {
      final preview = Document.fromJson(
        jsonDecode(note.content),
      ).toPlainText().trim();
      if (preview.isEmpty) return "(Empty note)";
      return preview;
    } catch (_) {
      return "(Invalid note)";
    }
  }

  String _previewLine(Note note) {
    final text = _notePreview(note);
    return text.split('\n').first;
  }

  String _previewParagraph(Note note) {
    final text = _notePreview(note);
    if (text.length <= 60) return text;
    return "${text.substring(0, 60)}...";
  }

  Widget _buildNotesList() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.topicId == 0) {
      return const Center(child: Text("Select a topic to see its notes."));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return const Center(child: Text("No notes yet. Create the first one."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        final isSelected = note.id == _activeNote?.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withOpacity(0.08)
                  : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colors.primary.withOpacity(0.28)
                    : colors.onSurface.withOpacity(0.08),
              ),
            ),
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -1),
              title: Text(
                _previewLine(note),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
              subtitle: Text(
                _previewParagraph(note),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
              onTap: () => _selectNote(note),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditor(QuillController controller) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.topicId == 0) {
      return const Center(child: Text("Pick a topic to start writing."));
    }

    if (_activeNote == null) {
      return const Center(child: Text("Create a note to start writing."));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "Note ${_activeNote!.id}",
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _saveCurrentNote,
                icon: const Icon(Icons.save_outlined),
                label: const Text("Save"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 64,
                  maxWidth: MediaQuery.of(context).size.width - 64,
                ),
                child: QuillSimpleToolbar(
                  controller: controller,
                  config: QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    toolbarSectionSpacing: 4,
                    showDividers: false,
                    showFontSize: true,
                    customButtons: [
                      QuillToolbarCustomButtonOptions(
                        icon: const Icon(Icons.text_fields),
                        tooltip: 'Custom size',
                        onPressed: () async {
                          final textCtrl = TextEditingController(text: '16');
                          final size = await showDialog<double>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Custom font size (px)'),
                              content: TextField(
                                controller: textCtrl,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop<double>(
                                    context,
                                    double.tryParse(textCtrl.text),
                                  ),
                                  child: const Text('Apply'),
                                ),
                              ],
                            ),
                          );
                          if (size != null) {
                            controller.formatSelection(
                              Attribute.fromKeyValue(
                                Attribute.size.key,
                                size.toStringAsFixed(0),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      fontSize: const QuillToolbarFontSizeButtonOptions(
                        items: {
                          '12 px': '12',
                          '14 px': '14',
                          '16 px': '16',
                          '18 px': '18',
                          '24 px': '24',
                          '32 px': '32',
                        },
                        defaultDisplayText: 'Size',
                      ),
                    ),
                    iconTheme: QuillIconTheme(
                      iconButtonUnselectedData: IconButtonData(
                        color: colors.onSurfaceVariant,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            colors.surfaceContainerHighest,
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                      ),
                      iconButtonSelectedData: IconButtonData(
                        color: colors.primary,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            colors.primary.withOpacity(0.14),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Focus(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.6),
                  border: Border.all(color: colors.onSurface.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QuillEditor.basic(
                  controller: controller,
                  config: QuillEditorConfig(
                    scrollable: true,
                    autoFocus: false,
                    expands: true,
                    padding: const EdgeInsets.all(12),
                    placeholder: 'Start writing your note here...',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _quillController;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.onSurface.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text("Notes", style: textTheme.labelLarge),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: widget.topicId == 0 ? null : _createNote,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("New"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.onSurface.withOpacity(0.08),
                    ),
                  ),
                    child: _buildNotesList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: controller == null
                ? const SizedBox.shrink()
                : _buildEditor(controller),
          ),
        ],
      ),
    );
  }
}
