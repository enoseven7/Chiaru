import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../pages/notes_list_page.dart';
import '../services/topic_service.dart';

class TopicsPage extends StatefulWidget {
  final Subject subject;

  const TopicsPage({super.key, required this.subject});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  List<Topic> topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  void _addTopic() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';

        return AlertDialog(
          title: const Text('New Topic'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Enter topic name'),
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

                await topicService.addTopic(widget.subject.id, name.trim());
                await _loadTopics();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _openTopic(Topic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotesListPage(topic: topic)),
    );
  }

  void _showTopicMenu(Topic topic) {
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
                  _renameTopic(topic);
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
                  await topicService.deleteTopic(topic.id);
                  await _loadTopics();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDeleteTopic() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Topic?"),
            content: const Text("All notes inside this topic will also be deleted."),
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
  }

  Future<void> _showTopicContextMenu(Offset position, Topic topic) async {
    final selection = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: const [
        PopupMenuItem(value: "rename", child: Text("Rename")),
        PopupMenuItem(value: "delete", child: Text("Delete")),
      ],
    );
    if (selection == "rename") {
      _renameTopic(topic);
    } else if (selection == "delete") {
      final confirm = await _confirmDeleteTopic();
      if (confirm) {
        await topicService.deleteTopic(topic.id);
        await _loadTopics();
      }
    }
  }

  void _renameTopic(Topic topic) {
    String name = topic.name;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Rename Topic"),
          content: TextField(
            controller: TextEditingController(text: name),
            onChanged: (value) => name = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;

                topic.name = name.trim();

                await topicService.updateTopic(topic);
                await _loadTopics();
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadTopics() async {
    topics = await topicService.getTopicsForSubject(widget.subject.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subject.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTopic,
        child: const Icon(Icons.add),
      ),
      body: topics.isEmpty
          ? const Center(child: Text("No topics yet. Add one!"))
          : ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];

                return Dismissible(
                  key: ValueKey(topic.id),
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
                        title: const Text("Delete Topic?"),
                        content: const Text(
                          "All notes inside this topic will also be deleted.",
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
                    await topicService.deleteTopic(topic.id);
                    await _loadTopics();
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onSecondaryTapDown: (details) =>
                        _showTopicContextMenu(details.globalPosition, topic),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.folder_open),
                        title: Text(topic.name),
                        textColor: Colors.white,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openTopic(topic),
                        onLongPress: () => _showTopicMenu(topic),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
