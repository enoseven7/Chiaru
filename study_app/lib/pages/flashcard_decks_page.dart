import 'package:flutter/material.dart';
import '../models/flashcard_deck.dart';
import '../models/topic.dart';
import '../services/flashcard_service.dart';
import '../pages/flashcard_editor_page.dart';

class FlashcardDecksPage extends StatefulWidget {
  final Topic topic;

  const FlashcardDecksPage({super.key, required this.topic});

  @override
  State<FlashcardDecksPage> createState() => _FlashcardDecksPageState();
}

class _FlashcardDecksPageState extends State<FlashcardDecksPage> {
  List<FlashcardDeck> decks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    decks = await flashcardService.getDecksByTopic(widget.topic.id);
    setState(() {});
  }

  Future<void> _deleteDeck(FlashcardDeck deck) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete deck?"),
            content: Text("All cards in \"${deck.name}\" will be removed."),
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
    await flashcardService.deleteDeck(deck.id);
    await _load();
  }

  Future<void> _showDeckContextMenu(Offset position, FlashcardDeck deck) async {
    final selection = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: const [
        PopupMenuItem(value: "delete", child: Text("Delete")),
      ],
    );
    if (selection == "delete") {
      await _deleteDeck(deck);
    }
  }

  void _addDeck() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("New Deck"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            child: Text("Add"),
            onPressed: () async {
              if (c.text.isNotEmpty) {
                await flashcardService.createDeck(widget.topic.id, c.text);
                await _load();
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flashcards – ${widget.topic.name}"),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _addDeck),
        ],
      ),
      body: ListView.builder(
        itemCount: decks.length,
        itemBuilder: (_, i) {
          final deck = decks[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: (details) =>
                _showDeckContextMenu(details.globalPosition, deck),
            child: ListTile(
              title: Text(deck.name),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlashcardsEditorPage(deck: deck),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
