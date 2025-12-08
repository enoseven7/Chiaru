import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../pages/notes_list_page.dart';

class TopicsPage extends StatefulWidget {
  final Subject subject;

  const TopicsPage({super.key, required this.subject});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  List<Topic> topics = [];

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
              onPressed: () {
                if (name.trim().isEmpty) return;

                setState(() {
                  topics.add(
                    Topic(
                      id: DateTime.now().toString(),
                      subjectId: widget.subject.id,
                      name: name.trim(),
                    ),
                  );
                });

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
      MaterialPageRoute(
        builder: (_) => NotesListPage(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
      ),
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

                return ListTile(
                  title: Text(topic.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _openTopic(topic),
                );
              },
            ),
    );
  }
}
