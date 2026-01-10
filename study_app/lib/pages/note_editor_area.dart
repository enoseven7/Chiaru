import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/note.dart';
import '../services/note_service.dart';
import '../services/windows_pen_input.dart';

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
  quill.QuillController? _quillController;
  List<Note> _notes = [];
  Note? _activeNote;
  bool _isLoading = false;
  double _notesPanelWidth = 260;
  bool _notesCollapsed = false;

  CanvasDocumentData _canvas = CanvasDocumentData.empty();
  Color _penColor = Colors.blue;
  double _penWidth = 3.5;
  bool _usingEraser = false;
  bool _textMode = false;
  bool _canvasView = true;
  bool _allowTouchDraw = false;
  final List<Color> _penPalette = const [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _initCanvasForNote(null);
    _initRichForNote(null);
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

  CanvasDocumentData _canvasFromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return CanvasDocumentData.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['type'] == CanvasDocumentData.storageType) {
        return CanvasDocumentData.fromJson(decoded);
      }
      try {
        final legacyDoc = quill.Document.fromJson(decoded as List);
        final text = legacyDoc.toPlainText().trim();
        return CanvasDocumentData.fromPlainText(text);
      } catch (_) {
        if (decoded is String) {
          return CanvasDocumentData.fromPlainText(decoded);
        }
      }
    } catch (_) {
      return CanvasDocumentData.fromPlainText(raw);
    }
    return CanvasDocumentData.empty();
  }

  NoteContentBundle _bundleFromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return NoteContentBundle.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['type'] == NoteContentBundle.storageType) {
        return NoteContentBundle.fromJson(decoded);
      }
      if (decoded is Map<String, dynamic> && decoded['type'] == CanvasDocumentData.storageType) {
        return NoteContentBundle(
          canvas: CanvasDocumentData.fromJson(decoded),
          rich: "",
        );
      }
      if (decoded is List<dynamic>) {
        // old quill delta
        return NoteContentBundle(canvas: CanvasDocumentData.empty(), rich: jsonEncode(decoded));
      }
      if (decoded is String) {
        return NoteContentBundle(canvas: CanvasDocumentData.empty(), rich: decoded);
      }
    } catch (_) {
      return NoteContentBundle(canvas: CanvasDocumentData.empty(), rich: raw);
    }
    return NoteContentBundle.empty();
  }

  void _initCanvasForNote(Note? note) {
    _canvas = _canvasFromRaw(note?.content);
  }

  void _initRichForNote(Note? note) {
    _quillController?.dispose();
    final bundle = _bundleFromRaw(note?.content);
    try {
      final doc = bundle.rich.isEmpty
          ? quill.Document()
          : quill.Document.fromJson(jsonDecode(bundle.rich) as List<dynamic>);
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      _quillController = quill.QuillController.basic();
    }
  }

  String _currentRichJson() {
    if (_quillController == null) return "";
    try {
      return jsonEncode(_quillController!.document.toDelta().toJson());
    } catch (_) {
      return "";
    }
  }

  Future<void> _loadNotesForTopic({bool selectNewest = false}) async {
    final topicId = widget.topicId;
    setState(() {
      _isLoading = true;
      _notes = [];
      _activeNote = null;
      _canvas = CanvasDocumentData.empty();
    });

    if (topicId == 0) {
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
      final bundle = _bundleFromRaw(nextNote?.content);
      _canvas = bundle.canvas;
      _initRichForNote(nextNote);
    });
  }

  Future<void> _saveCurrentNote() async {
    if (_activeNote == null) return;

    final updatedContent = jsonEncode(
      NoteContentBundle(
        canvas: _canvas,
        rich: _currentRichJson(),
      ).toJson(),
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
      final bundle = _bundleFromRaw(note.content);
      _canvas = bundle.canvas;
      _initRichForNote(note);
    });
  }

  Future<void> _deleteNote(Note note) async {
    await noteService.deleteNote(note.id);
    await _loadNotesForTopic();
    if (_activeNote?.id == note.id) {
      setState(() {
        _activeNote = _notes.isNotEmpty ? _notes.first : null;
        if (_activeNote != null) {
          final bundle = _bundleFromRaw(_activeNote!.content);
          _canvas = bundle.canvas;
          _initRichForNote(_activeNote);
        } else {
          _canvas = CanvasDocumentData.empty();
          _initRichForNote(null);
        }
      });
    }
  }

  Future<void> _showNoteContextMenu(Offset position, Note note) async {
    final selection = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: const [
        PopupMenuItem(value: "delete", child: Text("Delete note")),
      ],
    );
    if (selection == "delete") {
      await _deleteNote(note);
    }
  }

  String _notePreview(Note note) {
    try {
      final bundle = _bundleFromRaw(note.content);
      final canvasText = bundle.canvas.previewText;
      if (canvasText.isNotEmpty) return canvasText;
      if (bundle.rich.isNotEmpty) {
        try {
          return quill.Document.fromJson(jsonDecode(bundle.rich) as List<dynamic>)
              .toPlainText()
              .trim();
        } catch (_) {}
      }
      return "(Sketch note)";
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) =>
                  _showNoteContextMenu(details.globalPosition, note),
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
          ),
        );
      },
    );
  }

  Widget _buildEditor() {
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
          const SizedBox(height: 12),
          Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text("Canvas"), icon: Icon(Icons.gesture)),
                  ButtonSegment(
                    value: false,
                    label: Text("Rich text"),
                    icon: Icon(Icons.notes_outlined),
                  ),
                ],
                selected: {_canvasView},
                onSelectionChanged: (set) => setState(() => _canvasView = set.first),
              ),
              const Spacer(),
              if (!_canvasView && _quillController != null)
                IconButton(
                  tooltip: "Clear rich text",
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _quillController = quill.QuillController.basic();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_canvasView)
            Expanded(
              child: Column(
                children: [
                  _CanvasToolbar(
                    penColor: _penColor,
                    penWidth: _penWidth,
                    erasing: _usingEraser,
                    textMode: _textMode,
                    allowTouchDraw: _allowTouchDraw,
                    palette: _penPalette,
                    onColorSelected: (c) => setState(() {
                      _usingEraser = false;
                      _penColor = c;
                    }),
                    onWidthChanged: (v) => setState(() => _penWidth = v),
                    onEraserToggled: () => setState(() => _usingEraser = !_usingEraser),
                    onTextModeToggled: () => setState(() => _textMode = !_textMode),
                    onTouchDrawToggled: () =>
                        setState(() => _allowTouchDraw = !_allowTouchDraw),
                    onUndo: () => setState(() => _canvas = _canvas.removeLastStroke()),
                    onClearAll: () => setState(() => _canvas = CanvasDocumentData.empty()),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Focus(
                      child: _CanvasBoard(
                        key: ValueKey(_activeNote?.id),
                        document: _canvas,
                        penColor: _penColor,
                        strokeWidth: _penWidth,
                        erasing: _usingEraser,
                        textMode: _textMode,
                        allowTouchDraw: _allowTouchDraw,
                        textPalette: _penPalette,
                        onChanged: (doc) => setState(() => _canvas = doc),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_quillController != null)
            Expanded(
              child: Column(
                children: [
                  quill.QuillSimpleToolbar(
                    controller: _quillController!,
                    config: const quill.QuillSimpleToolbarConfig(
                      multiRowsDisplay: false,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.onSurface.withOpacity(0.12)),
                      ),
                      child: quill.QuillEditor.basic(
                        config: const quill.QuillEditorConfig(
                          padding: EdgeInsets.all(12),
                        ),
                        controller: _quillController!,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Expanded(child: Center(child: Text("Rich text not available."))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      // note list header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text("Notes", style: Theme.of(context).textTheme.labelLarge),
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
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
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
            child: _buildEditor(),
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

// ==== canvas controls + models added below ====

class _CanvasToolbar extends StatelessWidget {
  final Color penColor;
  final double penWidth;
  final bool erasing;
  final bool textMode;
  final bool allowTouchDraw;
  final List<Color> palette;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onWidthChanged;
  final VoidCallback onEraserToggled;
  final VoidCallback onTextModeToggled;
  final VoidCallback onTouchDrawToggled;
  final VoidCallback onUndo;
  final VoidCallback onClearAll;

  const _CanvasToolbar({
    required this.penColor,
    required this.penWidth,
    required this.erasing,
    required this.textMode,
    required this.allowTouchDraw,
    required this.palette,
    required this.onColorSelected,
    required this.onWidthChanged,
    required this.onEraserToggled,
    required this.onTextModeToggled,
    required this.onTouchDrawToggled,
    required this.onUndo,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Canvas tools", style: textTheme.bodyMedium),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: palette
                    .map(
                      (c) => GestureDetector(
                        onTap: () => onColorSelected(c),
                        child: Container(
                          width: 22,
                          height: 22,
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
              FilledButton.tonalIcon(
                onPressed: onEraserToggled,
                icon: Icon(erasing ? Icons.brush : Icons.auto_fix_high_outlined, size: 18),
                label: Text(erasing ? "Pen" : "Eraser"),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onTextModeToggled,
                icon: Icon(textMode ? Icons.text_fields : Icons.add_comment_outlined, size: 18),
                label: Text(textMode ? "Text mode" : "Add text"),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text("Touch draw"),
                selected: allowTouchDraw,
                onSelected: (_) => onTouchDrawToggled(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Width"),
              Expanded(
                child: Slider(
                  value: penWidth,
                  min: 1.0,
                  max: 12.0,
                  onChanged: onWidthChanged,
                ),
              ),
              const SizedBox(width: 6),
              Text("${penWidth.toStringAsFixed(1)} px"),
              const Spacer(),
              IconButton(
                tooltip: "Undo stroke",
                onPressed: onUndo,
                icon: const Icon(Icons.undo_rounded),
              ),
              TextButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.layers_clear_outlined),
                label: const Text("Clear"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CanvasBoard extends StatefulWidget {
  final CanvasDocumentData document;
  final Color penColor;
  final double strokeWidth;
  final bool erasing;
  final bool textMode;
  final bool allowTouchDraw;
  final List<Color> textPalette;
  final ValueChanged<CanvasDocumentData> onChanged;

  const _CanvasBoard({
    super.key,
    required this.document,
    required this.penColor,
    required this.strokeWidth,
    required this.erasing,
    required this.textMode,
    required this.allowTouchDraw,
    required this.textPalette,
    required this.onChanged,
  });

  @override
  State<_CanvasBoard> createState() => _CanvasBoardState();
}

class _CanvasBoardState extends State<_CanvasBoard> {
  CanvasStroke? _activeStroke;
  final ValueNotifier<int> _repaintSignal = ValueNotifier<int>(0);
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final FocusNode _canvasFocusNode = FocusNode();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final GlobalKey _canvasKey = GlobalKey();
  int? _activePointerId;
  Offset? _lastStrokePointPos;
  bool _scrollLocked = false;
  bool _penGestureActive = false;
  StreamSubscription<WindowsPenEvent>? _penSubscription;
  String? _draggingId;
  Offset _dragStartBoxPos = Offset.zero;
  Offset _dragAccum = Offset.zero;
  String? _selectedBoxId;
  Offset? _lastPointerPos;
  Size? _lastCanvasSize;

  @override
  void didUpdateWidget(covariant _CanvasBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final box in widget.document.textBoxes) {
      _controllers.putIfAbsent(box.id, () => TextEditingController(text: box.text));
      _focusNodes.putIfAbsent(box.id, () => FocusNode());
      if (_controllers[box.id]!.text != box.text && !_focusNodes[box.id]!.hasFocus) {
        _controllers[box.id]!.text = box.text;
      }
    }
    final removed = _controllers.keys.where(
      (id) => widget.document.textBoxes.every((b) => b.id != id),
    );
    for (final id in removed.toList()) {
      _controllers.remove(id)?.dispose();
      _focusNodes.remove(id)?.dispose();
    }
    if (_selectedBoxId != null && widget.document.boxById(_selectedBoxId!) == null) {
      _selectedBoxId = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _penSubscription = WindowsPenInput.instance.events.listen(_handlePenEvent);
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _canvasFocusNode.dispose();
    _repaintSignal.dispose();
    _penSubscription?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _updateDoc(CanvasDocumentData next) {
    widget.onChanged(next);
  }

  bool _isEditingTextBox() {
    for (final focus in _focusNodes.values) {
      if (focus.hasFocus) return true;
    }
    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isEditingTextBox()) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final character = event.character;
    if (character == null || character.isEmpty) return KeyEventResult.ignored;
    if (character == '\n' || character == '\r' || character == '\t') {
      return KeyEventResult.ignored;
    }
    final size = _lastCanvasSize;
    if (size == null) return KeyEventResult.ignored;
    _addTextBoxForTyping(character, size);
    return KeyEventResult.handled;
  }

  void _maybeExpandCanvas(Offset localPosition, Size size) {
    const edgeThreshold = 120.0;
    const expandBy = 600.0;
    double nextWidth = size.width;
    double nextHeight = size.height;
    if (localPosition.dx > size.width - edgeThreshold) {
      nextWidth = size.width + expandBy;
    }
    if (localPosition.dy > size.height - edgeThreshold) {
      nextHeight = size.height + expandBy;
    }
    if (nextWidth != size.width || nextHeight != size.height) {
      final scaleX = size.width / nextWidth;
      final scaleY = size.height / nextHeight;
      if (_activeStroke != null) {
        _activeStroke = CanvasStroke(
          color: Color(_activeStroke!.color),
          width: _activeStroke!.width,
          points: _activeStroke!.points
              .map(
                (p) => CanvasPoint(
                  p.x * scaleX,
                  p.y * scaleY,
                  p.pressure,
                ),
              )
              .toList(),
        );
      }
      _updateDoc(widget.document.resize(nextWidth, nextHeight));
    }
  }

  void _startStroke(PointerDownEvent event, Size size) {
    if (!_shouldHandlePointer(event)) return;
    if (_activePointerId != null) return;
    if (widget.textMode) return;
    _activePointerId = event.pointer;
    _lastStrokePointPos = event.localPosition;
    if (!_scrollLocked) {
      setState(() => _scrollLocked = true);
    }
    final norm = _normalize(event.localPosition, size);
    if (widget.erasing) {
      _activeStroke = null;
      _eraseAt(norm);
      return;
    }
    final stroke = CanvasStroke(
      color: widget.erasing ? Colors.white : widget.penColor,
      width: widget.strokeWidth,
      points: [CanvasPoint(norm.dx, norm.dy, _pressure(event))],
    );
    setState(() => _activeStroke = stroke);
  }

  void _extendStroke(PointerMoveEvent event, Size size) {
    if (_activePointerId != event.pointer) return;
    if (!_shouldHandlePointer(event)) return;
    if (_lastStrokePointPos != null &&
        (event.localPosition - _lastStrokePointPos!).distance < 1.5) {
      return;
    }
    _lastStrokePointPos = event.localPosition;
    if (widget.erasing) {
      _eraseAt(_normalize(event.localPosition, size));
      return;
    }
    if (_activeStroke == null || widget.textMode) return;
    final norm = _normalize(event.localPosition, size);
    _maybeExpandCanvas(event.localPosition, size);
    _activeStroke!.points.add(CanvasPoint(norm.dx, norm.dy, _pressure(event)));
    _repaintSignal.value += 1;
  }

  void _endStroke() {
    _activePointerId = null;
    _lastStrokePointPos = null;
    if (_scrollLocked) {
      setState(() => _scrollLocked = false);
    }
    if (_activeStroke == null) return;
    if (_activeStroke!.points.length > 1) {
      _updateDoc(widget.document.addStroke(_activeStroke!));
    }
    setState(() => _activeStroke = null);
  }

  void _eraseAt(Offset normPoint) {
    const radius = 0.02; // normalized radius for hit-testing
    final next = widget.document.strokes.where((stroke) {
      return stroke.points.every((p) {
        final dx = p.x - normPoint.dx;
        final dy = p.y - normPoint.dy;
        return (dx * dx + dy * dy) > radius * radius;
      });
    }).toList();
    if (next.length != widget.document.strokes.length) {
      _updateDoc(
        CanvasDocumentData(
          strokes: next,
          textBoxes: widget.document.textBoxes,
          width: widget.document.width,
          height: widget.document.height,
        ),
      );
    }
  }

  void _addTextBox(
    Offset position,
    Size size, {
    String initialText = "",
    bool focus = false,
  }) {
    final norm = _normalize(position, size);
    const defaultWidth = 0.32;
    const defaultHeight = 0.16;
    final id = _id();
    _updateDoc(
      widget.document.addTextBox(
        CanvasTextBox(
          id: id,
          x: norm.dx.clamp(0.0, 1.0 - defaultWidth),
          y: norm.dy.clamp(0.0, 1.0 - defaultHeight),
          width: defaultWidth,
          height: defaultHeight,
          text: initialText,
          fontSize: 16,
          color: Colors.black.value,
        ),
      ),
    );
    _maybeExpandCanvas(position, size);
    if (focus) {
      _selectedBoxId = id;
      _controllers.putIfAbsent(id, () => TextEditingController(text: initialText));
      final focusNode = _focusNodes.putIfAbsent(id, () => FocusNode());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(focusNode);
      });
    }
  }

  void _addTextBoxForTyping(String initialText, Size size) {
    final position = _lastPointerPos ?? Offset(size.width * 0.5, size.height * 0.45);
    _addTextBox(position, size, initialText: initialText, focus: true);
  }

  void _deleteTextBox(String id) {
    _updateDoc(widget.document.removeTextBox(id));
    setState(() {
      if (_selectedBoxId == id) _selectedBoxId = null;
      if (_draggingId == id) _draggingId = null;
    });
  }

  void _onTextChanged(String id, String value) {
    _updateDoc(widget.document.updateTextBox(id, text: value));
  }

  void _startDragBox(String id, Size size) {
    final box = widget.document.boxById(id);
    if (box == null) return;
    _draggingId = id;
    _dragStartBoxPos = Offset(box.x, box.y);
    _dragAccum = Offset.zero;
    _selectedBoxId = id;
  }

  void _onDragBox(String id, Offset delta, Size size) {
    if (_draggingId != id) return;
    _dragAccum += Offset(delta.dx / size.width, delta.dy / size.height);
    final startX = _dragStartBoxPos.dx;
    final startY = _dragStartBoxPos.dy;
    final box = widget.document.boxById(id);
    final width = box?.width ?? 0.2;
    final height = box?.height ?? 0.1;
    final nextX = (startX + _dragAccum.dx).clamp(0.0, 1.0 - width);
    final nextY = (startY + _dragAccum.dy).clamp(0.0, 1.0 - height);
    _updateDoc(widget.document.updateTextBox(
      id,
      x: nextX,
      y: nextY,
    ));
    final bottomRight = Offset(
      (nextX + width) * size.width,
      (nextY + height) * size.height,
    );
    _maybeExpandCanvas(bottomRight, size);
  }

  Offset _normalize(Offset pos, Size size) {
    final clamped = Offset(
      pos.dx.clamp(0, size.width),
      pos.dy.clamp(0, size.height),
    );
    return Offset(clamped.dx / size.width, clamped.dy / size.height);
  }

  double _pressure(PointerEvent event) {
    final minP = event.pressureMin;
    final maxP = event.pressureMax;
    final p = event.pressure;
    if (maxP - minP <= 0.01) return 1.0;
    return ((p - minP) / (maxP - minP)).clamp(0.35, 1.2);
  }

  bool _shouldHandlePointer(PointerEvent event) {
    if (_penGestureActive) return false;
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus ||
        event.kind == PointerDeviceKind.mouse) {
      return true;
    }
    if (event.kind == PointerDeviceKind.touch) {
      return widget.allowTouchDraw || _isStylusTouch(event);
    }
    return false;
  }

  void _handlePenEvent(WindowsPenEvent event) {
    if (!mounted) return;
    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final size = _lastCanvasSize;
    if (renderBox == null || size == null) return;
    final local = renderBox.globalToLocal(Offset(event.x, event.y));

    if (event.type == "down") {
      _penGestureActive = true;
      _startPenStroke(local, size, event.pressure, event.eraser);
    } else if (event.type == "move") {
      if (_penGestureActive) {
        _extendPenStroke(local, size, event.pressure, event.eraser);
      }
    } else {
      _endPenStroke();
      _penGestureActive = false;
    }
  }

  void _startPenStroke(Offset localPosition, Size size, double pressure, bool eraser) {
    if (widget.textMode) return;
    if (!_scrollLocked) {
      setState(() => _scrollLocked = true);
    }
    _lastStrokePointPos = localPosition;
    final norm = _normalize(localPosition, size);
    if (widget.erasing || eraser) {
      _activeStroke = null;
      _eraseAt(norm);
      return;
    }
    final stroke = CanvasStroke(
      color: widget.penColor,
      width: widget.strokeWidth,
      points: [CanvasPoint(norm.dx, norm.dy, _normalizePressure(pressure))],
    );
    setState(() => _activeStroke = stroke);
  }

  void _extendPenStroke(Offset localPosition, Size size, double pressure, bool eraser) {
    if (widget.erasing || eraser) {
      _eraseAt(_normalize(localPosition, size));
      return;
    }
    if (_activeStroke == null || widget.textMode) return;
    if (_lastStrokePointPos != null &&
        (localPosition - _lastStrokePointPos!).distance < 1.5) {
      return;
    }
    _lastStrokePointPos = localPosition;
    final norm = _normalize(localPosition, size);
    _maybeExpandCanvas(localPosition, size);
    _activeStroke!.points.add(CanvasPoint(norm.dx, norm.dy, _normalizePressure(pressure)));
    _repaintSignal.value += 1;
  }

  void _endPenStroke() {
    _lastStrokePointPos = null;
    if (_scrollLocked) {
      setState(() => _scrollLocked = false);
    }
    if (_activeStroke == null) return;
    if (_activeStroke!.points.length > 1) {
      _updateDoc(widget.document.addStroke(_activeStroke!));
    }
    setState(() => _activeStroke = null);
  }

  double _normalizePressure(double pressure) {
    if (pressure <= 0.0) return 1.0;
    return pressure.clamp(0.35, 1.2);
  }

  bool _isStylusTouch(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch) return false;
    final stylusButtons = kPrimaryStylusButton | kSecondaryStylusButton;
    if ((event.buttons & stylusButtons) != 0) return true;

    final pressureRange = event.pressureMax - event.pressureMin;
    final hasPressure = pressureRange > 0.05 && event.pressure > 0.0;
    final radius = event.radiusMajor;
    final size = event.size;
    final contact = radius > 0 ? radius : (size > 0 ? size : 0.0);
    final smallContact = contact > 0 ? contact <= 6.0 : false;

    if (smallContact && hasPressure) return true;
    if (contact == 0.0 && pressureRange > 0.2 && event.pressureMax > 1.0) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(widget.document.width, widget.document.height);
        _lastCanvasSize = canvasSize;
        return Focus(
          focusNode: _canvasFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.touch,
              },
            ),
            child: Scrollbar(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                physics: _scrollLocked ? const NeverScrollableScrollPhysics() : null,
                child: Scrollbar(
                  controller: _horizontalController,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: _scrollLocked ? const NeverScrollableScrollPhysics() : null,
                    child: SizedBox(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.onSurface.withOpacity(0.08)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Listener(
                                key: _canvasKey,
                                onPointerDown: (e) {
                                  _canvasFocusNode.requestFocus();
                                  _lastPointerPos = e.localPosition;
                                  _startStroke(e, canvasSize);
                                },
                                onPointerMove: (e) {
                                  _lastPointerPos = e.localPosition;
                                  _extendStroke(e, canvasSize);
                                },
                                onPointerUp: (_) => _endStroke(),
                                onPointerCancel: (_) => _endStroke(),
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    isComplex: true,
                                    willChange: true,
                                    painter: _CanvasPainter(
                                      strokes: [
                                        ...widget.document.strokes,
                                        if (_activeStroke != null) _activeStroke!,
                                      ],
                                      repaint: _repaintSignal,
                                    ),
                                    foregroundPainter:
                                        _CanvasGridPainter(colors.onSurface.withOpacity(0.06)),
                                    child: Container(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ...widget.document.textBoxes.map(
                            (box) {
                              final controller =
                                  _controllers[box.id] ?? TextEditingController(text: box.text);
                              final focus = _focusNodes[box.id] ?? FocusNode();
                              final boxSize = Size(
                                box.width * canvasSize.width,
                                box.height * canvasSize.height,
                              );
                              return Positioned(
                                left: box.x * canvasSize.width,
                                top: box.y * canvasSize.height,
                                width: boxSize.width,
                                height: boxSize.height,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _draggingId == box.id
                                          ? colors.primary
                                          : colors.onSurface.withOpacity(0.14),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 8,
                                        color: colors.shadow.withOpacity(0.12),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onPanStart: (_) => setState(() {
                                          _startDragBox(box.id, canvasSize);
                                        }),
                                        onPanUpdate: (details) =>
                                            _onDragBox(box.id, details.delta, canvasSize),
                                        onPanEnd: (_) => setState(() => _draggingId = null),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.drag_indicator,
                                                size: 14,
                                                color: colors.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Text",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colors.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Spacer(),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: TextField(
                                            controller: controller,
                                            focusNode: focus,
                                            maxLines: null,
                                            decoration:
                                                const InputDecoration.collapsed(hintText: "Text"),
                                            style: TextStyle(
                                              fontSize: box.fontSize,
                                              color: Color(box.color),
                                            ),
                                            onTap: () => setState(() => _selectedBoxId = box.id),
                                            onChanged: (v) => _onTextChanged(box.id, v),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_selectedBoxId != null)
                            Builder(
                              builder: (_) {
                                final box = widget.document.boxById(_selectedBoxId!);
                                if (box == null) return const SizedBox.shrink();
                                final toolbarWidth = 220.0;
                                final left = box.x * canvasSize.width;
                                final top = (box.y * canvasSize.height) - 52;
                                final clampedLeft =
                                    left.clamp(6.0, canvasSize.width - toolbarWidth - 6.0);
                                final clampedTop = top.clamp(6.0, canvasSize.height - 56.0);
                                return Positioned(
                                  left: clampedLeft,
                                  top: clampedTop,
                                  child: Container(
                                    width: toolbarWidth,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: colors.onSurface.withOpacity(0.12)),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 8,
                                          color: colors.shadow.withOpacity(0.16),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            const Text("Text color",
                                                style: TextStyle(fontSize: 12)),
                                            const Spacer(),
                                            IconButton(
                                              tooltip: "Delete box",
                                              icon: const Icon(Icons.delete_outline, size: 16),
                                              onPressed: () => _deleteTextBox(box.id),
                                            ),
                                            IconButton(
                                              tooltip: "Close toolbar",
                                              icon: const Icon(Icons.close, size: 16),
                                              onPressed: () =>
                                                  setState(() => _selectedBoxId = null),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          children: widget.textPalette
                                              .map(
                                                (c) => GestureDetector(
                                                  onTap: () {
                                                    _updateDoc(
                                                      widget.document.updateTextBox(
                                                        box.id,
                                                        color: c.value,
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 18,
                                                    height: 18,
                                                    decoration: BoxDecoration(
                                                      color: c,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: box.color == c.value
                                                            ? colors.primary
                                                            : colors.outline,
                                                        width: box.color == c.value ? 2 : 1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.86),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: colors.onSurface.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.erasing
                                        ? Icons.auto_fix_high_outlined
                                        : Icons.brush_rounded,
                                    size: 16,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                      Text(
                                    widget.textMode
                                        ? "Type to add text box"
                                        : widget.allowTouchDraw
                                            ? "Draw with pen or touch"
                                            : "Pen-only drawing (enable touch to draw)",
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<CanvasStroke> strokes;

  _CanvasPainter({required this.strokes, Listenable? repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke;

      for (var i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        final pressureWidth1 = stroke.width * p1.pressure;
        final pressureWidth2 = stroke.width * p2.pressure;
        canvas.drawLine(
          Offset(p1.x * size.width, p1.y * size.height),
          Offset(p2.x * size.width, p2.y * size.height),
          paint
            ..strokeWidth = (pressureWidth1 + pressureWidth2) / 2
            ..color = Color(stroke.color),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}

class _CanvasGridPainter extends CustomPainter {
  final Color color;

  _CanvasGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const gap = 48.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) => false;
}

class CanvasDocumentData {
  static const storageType = "canvas-v1";
  static const double defaultWidth = 1800;
  static const double defaultHeight = 1200;
  final List<CanvasStroke> strokes;
  final List<CanvasTextBox> textBoxes;
  final double width;
  final double height;
  final String type;

  CanvasDocumentData({
    required this.strokes,
    required this.textBoxes,
    required this.width,
    required this.height,
    this.type = storageType,
  });

  factory CanvasDocumentData.empty() => CanvasDocumentData(
        strokes: const [],
        textBoxes: const [],
        width: defaultWidth,
        height: defaultHeight,
      );

  factory CanvasDocumentData.fromJson(Map<String, dynamic> json) {
    return CanvasDocumentData(
      type: json['type'] as String? ?? storageType,
      strokes: (json['strokes'] as List<dynamic>? ?? [])
          .map((s) => CanvasStroke.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      textBoxes: (json['textBoxes'] as List<dynamic>? ?? [])
          .map((s) => CanvasTextBox.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      width: (json['width'] as num?)?.toDouble() ?? defaultWidth,
      height: (json['height'] as num?)?.toDouble() ?? defaultHeight,
    );
  }

  factory CanvasDocumentData.fromPlainText(String text) {
    if (text.isEmpty) return CanvasDocumentData.empty();
    return CanvasDocumentData(
      strokes: const [],
      textBoxes: [
        CanvasTextBox(
          id: _id(),
          x: 0.08,
          y: 0.06,
          width: 0.6,
          height: 0.18,
          text: text,
          fontSize: 16,
          color: Colors.black.value,
        ),
      ],
      width: defaultWidth,
      height: defaultHeight,
    );
  }

  Map<String, dynamic> toJson() => {
        "type": storageType,
        "strokes": strokes.map((e) => e.toJson()).toList(),
        "textBoxes": textBoxes.map((e) => e.toJson()).toList(),
        "width": width,
        "height": height,
      };

  CanvasDocumentData addStroke(CanvasStroke stroke) {
    return CanvasDocumentData(
      strokes: [...strokes, stroke],
      textBoxes: textBoxes,
      width: width,
      height: height,
    );
  }

  CanvasDocumentData removeLastStroke() {
    if (strokes.isEmpty) return this;
    return CanvasDocumentData(
      strokes: strokes.sublist(0, strokes.length - 1),
      textBoxes: textBoxes,
      width: width,
      height: height,
    );
  }

  CanvasDocumentData addTextBox(CanvasTextBox box) {
    return CanvasDocumentData(
      strokes: strokes,
      textBoxes: [...textBoxes, box],
      width: width,
      height: height,
    );
  }

  CanvasDocumentData updateTextBox(
    String id, {
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    double? fontSize,
    int? color,
  }) {
    return CanvasDocumentData(
      strokes: strokes,
      textBoxes: textBoxes
          .map(
            (b) => b.id == id
                ? b.copyWith(
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    text: text,
                    fontSize: fontSize,
                    color: color,
                  )
                : b,
          )
          .toList(),
      width: this.width,
      height: this.height,
    );
  }

  CanvasTextBox? boxById(String id) {
    try {
      return textBoxes.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  CanvasDocumentData removeTextBox(String id) {
    return CanvasDocumentData(
      strokes: strokes,
      textBoxes: textBoxes.where((b) => b.id != id).toList(),
      width: width,
      height: height,
    );
  }

  CanvasDocumentData resize(double nextWidth, double nextHeight) {
    if (nextWidth == width && nextHeight == height) return this;
    final scaleX = width / nextWidth;
    final scaleY = height / nextHeight;
    return CanvasDocumentData(
      strokes: strokes
          .map(
            (s) => CanvasStroke(
              color: Color(s.color),
              width: s.width,
              points: s.points
                  .map(
                    (p) => CanvasPoint(
                      p.x * scaleX,
                      p.y * scaleY,
                      p.pressure,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      textBoxes: textBoxes
          .map(
            (b) => b.copyWith(
              x: b.x * scaleX,
              y: b.y * scaleY,
              width: b.width * scaleX,
              height: b.height * scaleY,
            ),
          )
          .toList(),
      width: nextWidth,
      height: nextHeight,
    );
  }

  String get previewText {
    if (textBoxes.isEmpty) return "";
    return textBoxes.map((b) => b.text.trim()).where((t) => t.isNotEmpty).join("\n");
  }
}

class CanvasStroke {
  final List<CanvasPoint> points;
  final int color;
  final double width;

  CanvasStroke({
    required Color color,
    required this.width,
    required this.points,
  }) : color = color.value;

  factory CanvasStroke.fromJson(Map<String, dynamic> json) {
    return CanvasStroke(
      color: Color(json['color'] as int? ?? Colors.blue.value),
      width: (json['width'] as num?)?.toDouble() ?? 3.0,
      points: (json['points'] as List<dynamic>? ?? [])
          .map((p) => CanvasPoint.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "color": color,
        "width": width,
        "points": points.map((e) => e.toJson()).toList(),
      };
}

class CanvasPoint {
  final double x;
  final double y;
  final double pressure;

  CanvasPoint(this.x, this.y, this.pressure);

  factory CanvasPoint.fromJson(Map<String, dynamic> json) {
    return CanvasPoint(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['pressure'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        "x": x,
        "y": y,
        "pressure": pressure,
      };
}

class CanvasTextBox {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final String text;
  final double fontSize;
  final int color;

  CanvasTextBox({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.text,
    required this.fontSize,
    required this.color,
  });

  CanvasTextBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    double? fontSize,
    int? color,
  }) {
    return CanvasTextBox(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
    );
  }

  factory CanvasTextBox.fromJson(Map<String, dynamic> json) {
    return CanvasTextBox(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      text: json['text'] as String? ?? "",
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      color: json['color'] as int? ?? Colors.black.value,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "text": text,
        "fontSize": fontSize,
        "color": color,
      };
}

String _id() => DateTime.now().microsecondsSinceEpoch.toString() +
    Random().nextInt(999999).toString().padLeft(6, '0');

class NoteContentBundle {
  static const storageType = "multi-v1";
  final CanvasDocumentData canvas;
  final String rich;
  final String type;

  NoteContentBundle({
    required this.canvas,
    required this.rich,
    this.type = storageType,
  });

  factory NoteContentBundle.empty() => NoteContentBundle(
        canvas: CanvasDocumentData.empty(),
        rich: "",
      );

  factory NoteContentBundle.fromJson(Map<String, dynamic> json) {
    return NoteContentBundle(
      type: json['type'] as String? ?? storageType,
      canvas: json['canvas'] is Map<String, dynamic>
          ? CanvasDocumentData.fromJson(Map<String, dynamic>.from(json['canvas']))
          : CanvasDocumentData.empty(),
      rich: json['rich'] as String? ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "type": storageType,
        "canvas": canvas.toJson(),
        "rich": rich,
      };
}
