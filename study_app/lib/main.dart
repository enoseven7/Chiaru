import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/flashcard.dart';
import 'models/flashcard_deck.dart';
import 'models/note.dart';
import 'models/subject.dart';
import 'models/topic.dart';
import 'models/quiz.dart';
import 'models/quiz_question.dart';
import 'models/teach_settings.dart';

import 'pages/flashcard_home_page.dart';
import 'pages/notes_workspace_page.dart';
import 'pages/quiz_home_page.dart';
import 'pages/home_dashboard_page.dart';
import 'pages/teach_mode_page.dart';

late Isar isar;

enum AppSection {
  home,
  notes,
  flashcards,
  quizzes,
  feynman,
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  isar = await Isar.open(
    [
      SubjectSchema,
      TopicSchema,
      NoteSchema,
      FlashcardDeckSchema,
      FlashcardSchema,
      QuizSchema,
      QuizQuestionSchema,
      TeachSettingsSchema,
    ],
    directory: dir.path,
  );

  runApp(const StudyApp());
}

class StudyApp extends StatelessWidget {
  const StudyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final headlineFont = GoogleFonts.workSans();
    final bodyFont = GoogleFonts.inter();

    // Sleek, VSCode/Notion-inspired palette: cool neutrals with a single accent.
    const surface = Color(0xFF0F1116);
    const panel = Color(0xFF141820);
    const accent = Color(0xFF5CC8FF);
    final baseColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: Colors.black,
      secondary: const Color(0xFF8BA1B6),
      onSecondary: Colors.black,
      error: const Color(0xFFF97066),
      onError: Colors.black,
      surface: surface,
      onSurface: const Color(0xFFE2E8F0),
      surfaceTint: accent,
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: Colors.white.withOpacity(0.04),
      shadow: Colors.black,
      outlineVariant: Colors.white.withOpacity(0.08),
      scrim: Colors.black,
      inverseSurface: const Color(0xFFE2E8F0),
      inversePrimary: accent,
      tertiary: const Color(0xFFCBD5E1),
      onTertiary: Colors.black,
      primaryContainer: panel,
      onPrimaryContainer: const Color(0xFFE2E8F0),
      secondaryContainer: panel,
      onSecondaryContainer: const Color(0xFFE2E8F0),
      surfaceContainerHighest: panel,
      surfaceContainerHigh: panel,
      surfaceContainer: panel,
      surfaceContainerLow: surface,
      surfaceContainerLowest: surface,
      surfaceBright: const Color(0xFF181C23),
      surfaceDim: surface,
    );

    return MaterialApp(
      title: 'Study App',
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        // Add other supported locales here
      ],
      themeMode: ThemeMode.dark,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: baseColorScheme.surface,
        colorScheme: baseColorScheme,
        cardColor: baseColorScheme.surfaceContainerHigh,
        visualDensity: VisualDensity.standard,
        appBarTheme: AppBarTheme(
          backgroundColor: baseColorScheme.surface,
          foregroundColor: baseColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: headlineFont.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: baseColorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: headlineFont.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: baseColorScheme.onSurface,
            letterSpacing: -0.2,
          ),
          titleMedium: headlineFont.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: baseColorScheme.onSurface,
            letterSpacing: -0.05,
          ),
          bodyLarge: bodyFont.copyWith(
            fontSize: 16,
            height: 1.4,
            color: baseColorScheme.onSurface,
          ),
          bodyMedium: bodyFont.copyWith(
            fontSize: 14,
            height: 1.35,
            color: baseColorScheme.onSurfaceVariant,
          ),
          labelLarge: bodyFont.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: baseColorScheme.onSurface,
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: baseColorScheme.onSurfaceVariant,
          textColor: baseColorScheme.onSurface,
          selectedColor: baseColorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        ),
        dividerColor: baseColorScheme.outline,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: baseColorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: baseColorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: baseColorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: baseColorScheme.primary, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            backgroundColor: baseColorScheme.primary,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: baseColorScheme.outline),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
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
  AppSection currentSection = AppSection.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Study App', style: Theme.of(context).appBarTheme.titleTextStyle),
            const SizedBox(width: 32),
            _navButton("Home", AppSection.home),
            const SizedBox(width: 12),
            _navButton("Notes", AppSection.notes),
            const SizedBox(width: 12),
            _navButton("Flashcards", AppSection.flashcards),
            const SizedBox(width: 12),
            _navButton("Quizzes", AppSection.quizzes),
            const SizedBox(width: 12),
            _navButton("Feynman", AppSection.feynman),
          ],
        ),
      ),
      body: _buildSection(),
    );
  }
  
  Widget _buildSection() {
    switch (currentSection) {
      case AppSection.home:
        return const HomeDashboardPage();
      case AppSection.notes:
        return const NotesWorkspacePage();
      case AppSection.flashcards:
        return const FlashcardHomePage();
      case AppSection.quizzes:
        return const QuizPage();
      case AppSection.feynman:
        return const TeachModePage();
    }
  }

  Widget _navButton(String text, AppSection section) {
    final selected = currentSection == section;
    return GestureDetector(
      onTap: () => setState(() => currentSection = section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuizHomePage();
  }
}

// Alias to avoid conflict with the page class.
class TeachModePage extends StatelessWidget {
  const TeachModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeachModePageScreen();
  }
}
