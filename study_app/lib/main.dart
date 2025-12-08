import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/subject.dart';
import '../models/topic.dart';
import '../models/note.dart';

import '../pages/topics_page.dart';

import '../services/subject_services.dart';

late Isar isar;


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  isar = await Isar.open(
    [SubjectSchema, TopicSchema, NoteSchema],
    directory: dir.path,
  );

  runApp(const StudyApp());
}

class StudyApp extends StatelessWidget {
  const StudyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.tealAccent,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF101010),
          indicatorColor: Colors.tealAccent,
        ),
      ),

      home: const MainScreen(title: 'Main Screen'),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    NotesPage(),
    FlashcardPage(),
    QuizPage(),
    TeachModePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_pageTitle(_selectedIndex)),
      ),
      body: Center(child: _pages.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Flashcards'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Teach Mode',
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }

  String _pageTitle(int index) {
    switch (index) {
      case 0:
        return 'Notes';
      case 1:
        return 'Flashcards';
      case 2:
        return 'Quiz';
      case 3:
        return 'Teach Mode';
      default:
        return 'Study App';
    }
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Subject> subjects = [];

  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) {
        String subjectName = '';

        return AlertDialog(
          title: const Text('Add Subject'),
          content: TextField(
            onChanged: (value) {
              subjectName = value;
            },
            decoration: const InputDecoration(hintText: 'Subject Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (subjectName.trim().isEmpty) return;

                await subjectService.addSubject(subjectName.trim());
                if(mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
      );
  }

  void _openSubject(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicsPage(subject: subject),
      ),
    );
  }
  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: const Icon(Icons.add),
      ),
      body: subjects.isEmpty
          ? const Center(child: Text("No subjects yet. Add one!"))
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];

                return ListTile(
                  title: Text(subject.name),
                  onTap: () => _openSubject(subject),
                  trailing: const Icon(Icons.arrow_forward_ios),
                );
              }
          )
    );
  }
}

class FlashcardPage extends StatelessWidget {
  const FlashcardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Flashcard Page'));
  }
}

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Quiz Page'));
  }
}

class TeachModePage extends StatelessWidget {
  const TeachModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Teach Mode Page'));
  }
}
