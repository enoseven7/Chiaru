import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:signature/signature.dart';

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
  double _notesPanelWidth = 260;
  bool _notesCollapsed = false;
  bool _sketchCollapsed = true;
  double _sketchHeight = 230;
  late SignatureController _signatureController;
  Color _penColor = Colors.blue;
  bool _usingEraser = false;
  bool _hasSignatureController = false;
  final List<Color> _penPalette = const [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _signatureController = _createSignatureController();
    _hasSignatureController = true;
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

  SignatureController _createSignatureController({
    List<Point>? points,
    Color? color,
    double? strokeWidth,
  }) {
    final existingPoints = points ??
        (_hasSignatureController ? List<Point>.from(_signatureController.points) : <Point>[]);
    return SignatureController(
      penStrokeWidth: strokeWidth ?? 3,
      penColor: color ?? (_usingEraser ? Colors.white : _penColor),
      exportBackgroundColor: Colors.white,
      points: existingPoints,
    );
  }

  void _updateSignatureController({Color? color, bool? useEraser}) {
    final bool nextEraser = useEraser ?? _usingEraser;
    final Color newPenColor = nextEraser ? Colors.white : (color ?? _penColor);
    final points =
        _hasSignatureController ? List<Point>.from(_signatureController.points) : <Point>[];
    if (_hasSignatureController) {
      _signatureController.dispose();
    }
    setState(() {
      if (color != null) _penColor = color;
      _usingEraser = nextEraser;
      _signatureController = _createSignatureController(points: points, color: newPenColor);
      _hasSignatureController = true;
    });
  }

  @override
  void dispose() {
    () async {
      await _saveCurrentNote();
    }();
    _signatureController.dispose();
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

  Future<void> _insertSketch(QuillController controller) async {
    if (_signatureController.isEmpty) return;
    try {
      final Uint8List? png = await _signatureController.toPngBytes();
      if (png == null) return;
      final dataUri = 'data:image/png;base64,${base64Encode(png)}';

      final sel = controller.selection;
      final docLength = controller.document.length;
      final index = (sel.baseOffset < 0 || sel.baseOffset > docLength) ? docLength : sel.baseOffset;
      controller.replaceText(
        index,
        0,
        BlockEmbed.image(dataUri),
        TextSelection.collapsed(offset: index + 1),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to insert sketch: $e')),
      );
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
          _SketchPad(
            controller: _signatureController,
            collapsed: _sketchCollapsed,
            height: _sketchHeight,
            penColor: _penColor,
            palette: _penPalette,
            onToggle: () => setState(() => _sketchCollapsed = !_sketchCollapsed),
            onClear: () => _signatureController.clear(),
            onEraseToggle: () => _updateSignatureController(useEraser: !_usingEraser),
            onColorSelected: (c) => _updateSignatureController(color: c, useEraser: false),
            onResize: (delta) {
              setState(() {
                _sketchCollapsed = false;
                _sketchHeight = (_sketchHeight + delta).clamp(160, 420);
              });
            },
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
                    embedBuilders: const [_ImageEmbedBuilder()],
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
          _ResizablePanel(
            width: _notesCollapsed ? 56 : _notesPanelWidth,
            minWidth: 180,
            collapsed: _notesCollapsed,
            onToggleCollapse: () => setState(() => _notesCollapsed = !_notesCollapsed),
            onDrag: (dx) {
              setState(() {
                _notesCollapsed = false;
                _notesPanelWidth = (_notesPanelWidth + dx).clamp(180, 360);
              });
            },
            child: _notesCollapsed
                ? _CollapsedRail(
                    label: "Notes",
                    icon: Icons.note_outlined,
                    onExpand: () => setState(() => _notesCollapsed = false),
                  )
                : Column(
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
          constraints: BoxConstraints(minWidth: collapsed ? 40 : minWidth),
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
                    backgroundColor: colors.surfaceContainerHighest.withOpacity(0.6),
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
                    color: colors.onSurface.withOpacity(0.18),
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

class _ImageEmbedBuilder extends EmbedBuilder {
  const _ImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final source = data is String ? data : '';

    Widget image;
    if (source.startsWith('data:image')) {
      final idx = source.indexOf(',');
      final base64Str = idx != -1 ? source.substring(idx + 1) : source;
      image = Image.memory(
        base64Decode(base64Str),
        fit: BoxFit.contain,
      );
    } else if (source.startsWith('file://')) {
      image = Image.file(
        File(Uri.parse(source).toFilePath()),
        fit: BoxFit.contain,
      );
    } else if (source.startsWith('/')) {
      image = Image.file(
        File(source),
        fit: BoxFit.contain,
      );
    } else {
      image = Image.network(
        source,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420, maxWidth: 1200),
        child: image,
      ),
    );
  }
}

class _SketchPad extends StatelessWidget {
  final SignatureController controller;
  final bool collapsed;
  final double height;
  final Color penColor;
  final List<Color> palette;
  final VoidCallback onToggle;
  final VoidCallback onClear;
  final VoidCallback onEraseToggle;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onResize;

  const _SketchPad({
    required this.controller,
    required this.collapsed,
    required this.height,
    required this.penColor,
    required this.palette,
    required this.onToggle,
    required this.onClear,
    required this.onEraseToggle,
    required this.onColorSelected,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      height: collapsed ? 46 : height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("Sketch pad", style: textTheme.bodyMedium),
              const SizedBox(width: 10),
              Wrap(
                spacing: 6,
                children: palette
                    .map(
                      (c) => GestureDetector(
                        onTap: () => onColorSelected(c),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c == penColor ? colors.primary : colors.outline,
                              width: c == penColor ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              IconButton(
                tooltip: collapsed ? "Show sketch pad" : "Hide sketch pad",
                icon: Icon(collapsed ? Icons.edit : Icons.expand_less),
                onPressed: onToggle,
              ),
            ],
          ),
          if (!collapsed) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.onSurface.withOpacity(0.1)),
                ),
                clipBehavior: Clip.hardEdge,
                child: Signature(
                  controller: controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Clear"),
                ),
                TextButton.icon(
                  onPressed: onEraseToggle,
                  icon: const Icon(Icons.auto_fix_normal_outlined),
                  label: const Text("Eraser"),
                ),
              ],
            ),
            const SizedBox(height: 6),
            MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) => onResize(details.delta.dy),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
