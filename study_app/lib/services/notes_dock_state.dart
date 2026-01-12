class NotesDockState {
  NotesDockState._();

  static final NotesDockState instance = NotesDockState._();

  int? selectedSubjectId;
  int? selectedTopicId;
  int? selectedNoteId;
  final Map<int, bool> noteCanvasView = {};
  bool lastCanvasView = true;
}

final notesDockState = NotesDockState.instance;
