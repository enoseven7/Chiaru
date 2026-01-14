import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'models/flashcard.dart';
import 'models/flashcard_deck.dart';
import 'models/note.dart';
import 'models/subject.dart';
import 'models/topic.dart';
import 'models/quiz.dart';
import 'models/quiz_question.dart';
import 'models/teach_settings.dart';
import 'models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/flashcard_home_page.dart';
import 'pages/notes_workspace_page.dart';
import 'pages/quiz_home_page.dart';
import 'pages/home_dashboard_page.dart';
import 'pages/teach_mode_page.dart';
import 'pages/planner_page.dart';
import 'pages/pomodoro_page.dart';
import 'services/notification_service.dart';
import 'pages/settings_page.dart';
import 'services/settings_service.dart';

late Isar isar;

enum AppSection {
  home,
  planner,
  notes,
  flashcards,
  quizzes,
  feynman,
  pomodoro,
  settings,
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_isDesktopPlatform()) {
    await windowManager.ensureInitialized();
  }

  await NotificationService.instance.init();

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
      TaskSchema,
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
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        final theme = _buildTheme(settings);
        return MaterialApp(
          title: 'Chiaru',
          localizationsDelegates: const [
            // AppLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            // Add other supported locales here
          ],
          themeMode: settings.brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
          theme: theme,
          darkTheme: theme,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaleFactor: settings.fontScale),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const MainScreen(title: 'Main Screen'),
        );
      },
    );
  }

  ThemeData _buildTheme(AppSettings settings) {
    final isRetro = settings.preset == ThemePreset.retro;
    final onPrimary = _idealOnColor(settings.primary);
    final onSecondary = _idealOnColor(settings.secondary);
    final outline = settings.highContrast
        ? settings.outline.withOpacity(0.6)
        : settings.outline;
    final surfaceHigh = Color.lerp(settings.panel, settings.surface, 0.1)!;
    final surfaceBright = Color.lerp(settings.surface, Colors.white, 0.06)!;

    final baseColorScheme = ColorScheme(
      brightness: settings.brightness,
      primary: settings.primary,
      onPrimary: onPrimary,
      secondary: settings.secondary,
      onSecondary: onSecondary,
      error: const Color(0xFFF97066),
      onError: Colors.black,
      surface: settings.surface,
      onSurface: settings.onSurface,
      surfaceTint: settings.primary,
      onSurfaceVariant: settings.onSurfaceVariant,
      outline: outline,
      shadow: Colors.black,
      outlineVariant: settings.outline.withOpacity(settings.highContrast ? 0.4 : 0.2),
      scrim: Colors.black,
      inverseSurface: settings.onSurface,
      inversePrimary: settings.primary,
      tertiary: settings.secondary,
      onTertiary: onSecondary,
      primaryContainer: settings.panel,
      onPrimaryContainer: settings.onSurface,
      secondaryContainer: settings.panel,
      onSecondaryContainer: settings.onSurface,
      surfaceContainerHighest: settings.panel,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainer: settings.panel,
      surfaceContainerLow: settings.surface,
      surfaceContainerLowest: settings.surface,
      surfaceBright: surfaceBright,
      surfaceDim: settings.surface,
    );

    final headlineFont = isRetro
        ? const TextStyle(fontFamily: 'Tahoma', fontFamilyFallback: ['Verdana', 'Arial', 'sans-serif'])
        : GoogleFonts.workSans().copyWith(fontFamilyFallback: const ['Segoe UI Variable', 'Segoe UI']);
    final bodyFont = isRetro
        ? const TextStyle(fontFamily: 'Tahoma', fontFamilyFallback: ['Verdana', 'Arial', 'sans-serif'])
        : GoogleFonts.inter().copyWith(fontFamilyFallback: const ['Segoe UI Variable', 'Segoe UI']);

    final motionTheme = settings.reduceMotion
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: NoTransitionsBuilder(),
              TargetPlatform.iOS: NoTransitionsBuilder(),
              TargetPlatform.macOS: NoTransitionsBuilder(),
              TargetPlatform.windows: NoTransitionsBuilder(),
              TargetPlatform.linux: NoTransitionsBuilder(),
            },
          )
        : const PageTransitionsTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: settings.brightness,
      scaffoldBackgroundColor:
          settings.useGradient ? settings.gradientStart : baseColorScheme.surface,
      colorScheme: baseColorScheme,
      cardColor: baseColorScheme.surfaceContainerHigh,
      visualDensity: VisualDensity.comfortable,
      dividerColor: baseColorScheme.outline.withOpacity(0.6),
      pageTransitionsTheme: motionTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isRetro ? const Color(0xFF0053D6) : baseColorScheme.surface,
        foregroundColor: isRetro ? Colors.white : baseColorScheme.onSurface,
        elevation: isRetro ? 3 : 2,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shadowColor: isRetro ? Colors.black45 : null,
        titleTextStyle: headlineFont.copyWith(
          fontSize: 20,
          fontWeight: isRetro ? FontWeight.w700 : FontWeight.w600,
          color: isRetro ? Colors.white : baseColorScheme.onSurface,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(
          color: isRetro ? Colors.white : baseColorScheme.onSurface,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: headlineFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: baseColorScheme.onSurface,
          letterSpacing: -0.15,
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
      splashFactory: settings.reduceMotion ? NoSplash.splashFactory : NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: isRetro ? 2 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isRetro ? 0 : 6),
          side: isRetro ? BorderSide(color: const Color(0xFF8B8680), width: 1) : BorderSide.none,
        ),
        color: isRetro ? const Color(0xFFECE9D8) : null,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isRetro ? Colors.white : baseColorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetro ? 0 : 6),
          borderSide: BorderSide(
            color: isRetro ? const Color(0xFF7A96DF) : baseColorScheme.outline.withOpacity(0.4),
            width: isRetro ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetro ? 0 : 6),
          borderSide: BorderSide(
            color: isRetro ? const Color(0xFF7A96DF) : baseColorScheme.outline.withOpacity(0.4),
            width: isRetro ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetro ? 0 : 6),
          borderSide: BorderSide(
            color: isRetro ? const Color(0xFF0053D6) : baseColorScheme.primary,
            width: isRetro ? 2 : 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isRetro ? 3 : 6),
            side: isRetro ? BorderSide(color: const Color(0xFF003C74), width: 1) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: isRetro ? const Color(0xFFECE9D8) : baseColorScheme.primary,
          foregroundColor: isRetro ? Colors.black : Colors.black,
          elevation: isRetro ? 1 : 0,
          shadowColor: isRetro ? Colors.black45 : null,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isRetro ? 3 : 6),
            side: isRetro ? BorderSide(color: const Color(0xFF003C74), width: 1) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: isRetro ? const Color(0xFFD4D0C8) : null,
          elevation: isRetro ? 1 : 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isRetro ? 3 : 6),
          ),
          side: BorderSide(
            color: isRetro ? const Color(0xFF003C74) : baseColorScheme.outline.withOpacity(0.6),
            width: isRetro ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          backgroundColor: isRetro ? const Color(0xFFECE9D8) : null,
        ),
      ),
      extensions: [
        AppDecorTheme(
          gradientStart: settings.gradientStart,
          gradientEnd: settings.gradientEnd,
          useGradient: settings.useGradient,
        ),
      ],
    );
  }

  Color _idealOnColor(Color background) {
    return background.computeLuminance() > 0.6 ? Colors.black : Colors.white;
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
  bool _onboardingShown = false;
  bool _onboardingLoaded = false;
  bool _kioskMode = false;
  bool _dockMode = false;
  DockSide _dockSide = DockSide.right;
  int _dockWidth = 640;
  Rect? _preDockBounds;
  bool? _preDockAlwaysOnTop;
  bool? _preDockResizable;
  bool? _preDockMinimizable;
  bool? _preDockMaximizable;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openSearch,
      },
      child: Focus(
        autofocus: true,
        child: _buildShell(context),
      ),
    );
  }

  Widget _buildShell(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final decor = Theme.of(context).extension<AppDecorTheme>();
    final gradient = decor?.useGradient == true
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [decor!.gradientStart, decor.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          )
        : BoxDecoration(color: colors.surface);

    if (_dockMode) {
      return Scaffold(
        body: Container(
          decoration: gradient,
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _buildContentCard(context, const NotesWorkspacePage(docked: true)),
                ),
                Positioned(
                  top: 6,
                  right: 10,
                  child: IconButton(
                    tooltip: 'Undock window',
                    onPressed: _toggleDockMode,
                    icon: const Icon(Icons.close_fullscreen),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerHighest.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: gradient,
        child: SafeArea(
          child: Row(
            children: [
              _buildRail(context),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                        child: _buildContentCard(context, _buildSection()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, Widget child) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }

  NavigationRail _buildRail(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1180;
    final brightness = Theme.of(context).brightness;
    final logoAsset =
        brightness == Brightness.dark ? 'assets/0.5x/White_Transparent@0.5x.png' : 'assets/0.5x/Black Transparent@0.5x.png';
    final destinations = [
      (AppSection.home, Icons.dashboard_outlined, 'Home'),
      (AppSection.planner, Icons.event_note_outlined, 'Planner'),
      (AppSection.notes, Icons.description_outlined, 'Notes'),
      (AppSection.flashcards, Icons.style_outlined, 'Cards'),
      (AppSection.quizzes, Icons.quiz_outlined, 'Quizzes'),
      (AppSection.feynman, Icons.record_voice_over_outlined, 'Teach'),
      (AppSection.pomodoro, Icons.timer_outlined, 'Focus'),
      (AppSection.settings, Icons.settings_outlined, 'Settings'),
    ];
    final selectedIndex = destinations.indexWhere((d) => d.$1 == currentSection);

    return NavigationRail(
      extended: isWide,
      minExtendedWidth: 160,
      minWidth: 56,
      backgroundColor: Colors.transparent,
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) => setState(() => currentSection = destinations[i].$1),
      leading: Padding(
        padding: EdgeInsets.only(top: isWide ? 8.0 : 6.0, bottom: isWide ? 12.0 : 8.0),
        child: Column(
          children:
          [
            Container(
              width: isWide ? 40 : 36,
              height: isWide ? 40 : 36,
              padding: EdgeInsets.all(isWide ? 6 : 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Image.asset(
                logoAsset,
                fit: BoxFit.contain,
              ),
            ),
            if (isWide)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  'Chiaru',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
      destinations: destinations
          .map(
            (d) => NavigationRailDestination(
              icon: Icon(d.$2),
              selectedIcon: Icon(d.$2, color: Theme.of(context).colorScheme.primary),
              label: Text(d.$3),
            ),
          )
          .toList(),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Show guide',
            onPressed: () => _showOnboarding(force: true),
            icon: const Icon(Icons.help_outline),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final showDock = _isDesktopPlatform();
    final isNarrow = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outline),
              ),
              child: InkWell(
                onTap: _openSearch,
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: colors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    if (!isNarrow)
                      Text(
                        'Search notes, cards, quizzes...',
                        style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.outline),
                      ),
                      child: Text('Ctrl+K', style: textTheme.labelSmall),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isNarrow)
            IconButton(
              tooltip: 'Quick add',
              onPressed: () => setState(() => currentSection = AppSection.planner),
              icon: const Icon(Icons.add_circle_outline),
            )
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => currentSection = AppSection.planner),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Quick add'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: _kioskMode ? 'Exit fullscreen' : 'Enter fullscreen',
            onPressed: _toggleKioskMode,
            icon: Icon(_kioskMode ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
          if (showDock) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: _dockMode ? 'Undock window' : 'Dock window',
              onPressed: _toggleDockMode,
              icon: Icon(_dockMode ? Icons.close_fullscreen : Icons.vertical_split),
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => setState(() => currentSection = AppSection.settings),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (currentSection) {
      case AppSection.home:
        return HomeDashboardPage(onNavigate: (section) => setState(() => currentSection = section));
      case AppSection.planner:
        return const PlannerPage();
      case AppSection.notes:
        return const NotesWorkspacePage();
      case AppSection.flashcards:
        return const FlashcardHomePage();
      case AppSection.quizzes:
        return const QuizPage();
      case AppSection.feynman:
        return const TeachModePage();
      case AppSection.pomodoro:
        return const PomodoroPage();
      case AppSection.settings:
        return const SettingsPage();
    }
  }

  @override
  void initState() {
    super.initState();
    _initOnboarding();
  }

  Future<void> _initOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool('onboarding_seen') ?? false;
    setState(() {
      _onboardingShown = alreadySeen;
      _onboardingLoaded = true;
    });
    if (!alreadySeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOnboarding());
    }
  }

  void _showOnboarding({bool force = false}) {
    if (!_onboardingLoaded) return;
    if (_onboardingShown && !force) return;
    if (!_onboardingShown) {
      _onboardingShown = true;
      SharedPreferences.getInstance().then((prefs) => prefs.setBool('onboarding_seen', true));
    }
    final steps = [
      (
        icon: Icons.dashboard_customize,
        title: 'Home dashboard',
        body: 'See your study pulse and quick stats. Start here to get a feel for your workspace.'
      ),
      (
        icon: Icons.event_note,
        title: 'Planner',
        body:
            'Organize tasks, set reminders, and switch between today/week/calendar views. Recurrence is supported.'
      ),
      (
        icon: Icons.book_outlined,
        title: 'Notes & Flashcards',
        body: 'Capture notes per subject/topic and turn them into flashcards for spaced review.'
      ),
      (
        icon: Icons.quiz_outlined,
        title: 'Quizzes & Feynman',
        body: 'Build quizzes to self-test, and use Feynman mode to teach concepts back for deeper understanding.'
      ),
      (
        icon: Icons.settings_outlined,
        title: 'Settings',
        body: 'Customize theme/colors, adjust font size, set accessibility, and export your data.'
      ),
    ];

    int step = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModal) {
          final current = steps[step];
          return AlertDialog(
            title: Row(
              children: [
                Icon(current.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(child: Text(current.title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.body),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.mouse),
                      label: const Text('Hover nav for tips'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.info_outline),
                      label: const Text('Tap ? anytime'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Skip'),
              ),
              TextButton(
                onPressed: () {
                  if (step < steps.length - 1) {
                    setModal(() => step += 1);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(step == steps.length - 1 ? 'Done' : 'Next'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _openSearch() async {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    List<_SearchResult> results = [];
    bool searching = false;

    Future<void> run(String query, void Function(void Function()) setModalState) async {
      setModalState(() => searching = true);
      final q = query.trim();
      if (q.isEmpty) {
        setModalState(() {
          results = [];
          searching = false;
        });
        return;
      }
      final lower = q.toLowerCase();
      final noteHits =
          await isar.notes.filter().contentContains(lower, caseSensitive: false).limit(8).findAll();
      final cardHits = await isar.flashcards
          .filter()
          .group((q) => q.frontContains(lower, caseSensitive: false))
          .or()
          .backContains(lower, caseSensitive: false)
          .limit(8)
          .findAll();
      final quizHits =
          await isar.quizs.filter().titleContains(lower, caseSensitive: false).limit(6).findAll();
      final taskHits =
          await isar.tasks.filter().titleContains(lower, caseSensitive: false).limit(6).findAll();

      setModalState(() {
        results = [
          ...noteHits.map((n) => _SearchResult(
                title: n.content.length > 60 ? "${n.content.substring(0, 60)}..." : n.content,
                subtitle: "Note",
                icon: Icons.description_outlined,
                section: AppSection.notes,
              )),
          ...cardHits.map((c) => _SearchResult(
                title: c.front,
                subtitle: "Flashcard",
                icon: Icons.style_outlined,
                section: AppSection.flashcards,
              )),
          ...quizHits.map((qz) => _SearchResult(
                title: qz.title,
                subtitle: "Quiz",
                icon: Icons.quiz_outlined,
                section: AppSection.quizzes,
              )),
          ...taskHits.map((t) => _SearchResult(
                title: t.title,
                subtitle: "Task",
                icon: Icons.event_note_outlined,
                section: AppSection.planner,
              )),
        ];
        searching = false;
      });
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  const Text('Quick search'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search notes, cards, quizzes, tasks',
                      ),
                      onChanged: (val) => run(val, setModalState),
                    ),
                    const SizedBox(height: 12),
                    if (searching) const LinearProgressIndicator(minHeight: 2),
                    if (results.isEmpty && !searching)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No matches yet. Try another keyword.',
                          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    if (results.isNotEmpty)
                      SizedBox(
                        height: 320,
                        child: ListView.separated(
                          itemBuilder: (context, index) {
                            final r = results[index];
                            return ListTile(
                              leading: Icon(r.icon, color: colors.primary),
                              title: Text(r.title),
                              subtitle: Text(r.subtitle),
                              onTap: () {
                                setState(() => currentSection = r.section);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemCount: results.length,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleKioskMode() async {
    await _setKioskMode(!_kioskMode);
  }

  Future<void> _setKioskMode(bool enabled) async {
    if (_isDesktopPlatform()) {
      if (enabled && _dockMode) {
        await _setDockMode(false);
      }
      if (enabled) {
        await windowManager.setFullScreen(true);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setResizable(false);
        await windowManager.setMinimizable(false);
        await windowManager.setMaximizable(false);
        await windowManager.setPreventClose(true);
      } else {
        await windowManager.setPreventClose(false);
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setFullScreen(false);
        await windowManager.setResizable(true);
        await windowManager.setMinimizable(true);
        await windowManager.setMaximizable(true);
      }
    }
    if (!mounted) return;
    setState(() => _kioskMode = enabled);
  }

  Future<void> _toggleDockMode() async {
    if (_dockMode) {
      await _setDockMode(false);
      return;
    }
    final nextSide = await _pickDockSide();
    if (nextSide == null) return;
    _dockSide = nextSide;
    await _setDockMode(true);
  }

  Future<void> _setDockMode(bool enabled) async {
    if (_isDesktopPlatform()) {
      if (enabled && _kioskMode) {
        await _setKioskMode(false);
      }
      if (enabled) {
        _preDockBounds = await windowManager.getBounds();
        _preDockAlwaysOnTop = await windowManager.isAlwaysOnTop();
        _preDockResizable = await windowManager.isResizable();
        _preDockMinimizable = await windowManager.isMinimizable();
        _preDockMaximizable = await windowManager.isMaximizable();

        await windowManager.setFullScreen(false);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setResizable(true);
        await windowManager.setMinimizable(true);
        await windowManager.setMaximizable(true);

        final display = await screenRetriever.getPrimaryDisplay();
        final visibleSize = display.visibleSize ?? display.size;
        final visiblePosition = display.visiblePosition ?? const Offset(0, 0);
        const minDockWidth = 360.0;
        final width = _dockWidth.toDouble().clamp(minDockWidth, visibleSize.width);
        final height = visibleSize.height;
        final left = _dockSide == DockSide.left
            ? visiblePosition.dx
            : visiblePosition.dx + visibleSize.width - width;
        final top = visiblePosition.dy;
        await windowManager.setBounds(Rect.fromLTWH(left, top, width, height));
      } else {
        final size = await windowManager.getSize();
        _dockWidth = size.width.round();
        await windowManager.setAlwaysOnTop(_preDockAlwaysOnTop ?? false);
        await windowManager.setResizable(_preDockResizable ?? true);
        await windowManager.setMinimizable(_preDockMinimizable ?? true);
        await windowManager.setMaximizable(_preDockMaximizable ?? true);
        if (_preDockBounds != null) {
          await windowManager.setBounds(_preDockBounds!);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _dockMode = enabled;
      if (enabled) {
        currentSection = AppSection.notes;
      }
    });
  }

  Future<DockSide?> _pickDockSide() async {
    if (!mounted) return null;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return showDialog<DockSide>(
      context: context,
      builder: (context) {
        var tempSide = _dockSide;
        return StatefulBuilder(
          builder: (context, setModal) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.vertical_split, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text('Dock window'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose which side to dock on.',
                    style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<DockSide>(
                    value: DockSide.left,
                    groupValue: tempSide,
                    onChanged: (val) => setModal(() => tempSide = val ?? DockSide.left),
                    title: const Text('Left'),
                  ),
                  RadioListTile<DockSide>(
                    value: DockSide.right,
                    groupValue: tempSide,
                    onChanged: (val) => setModal(() => tempSide = val ?? DockSide.right),
                    title: const Text('Right'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(tempSide),
                  child: const Text('Dock'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class AppDecorTheme extends ThemeExtension<AppDecorTheme> {
  final Color gradientStart;
  final Color gradientEnd;
  final bool useGradient;

  const AppDecorTheme({
    required this.gradientStart,
    required this.gradientEnd,
    required this.useGradient,
  });

  @override
  AppDecorTheme copyWith({Color? gradientStart, Color? gradientEnd, bool? useGradient}) {
    return AppDecorTheme(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      useGradient: useGradient ?? this.useGradient,
    );
  }

  @override
  AppDecorTheme lerp(ThemeExtension<AppDecorTheme>? other, double t) {
    if (other is! AppDecorTheme) return this;
    return AppDecorTheme(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t) ?? gradientStart,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t) ?? gradientEnd,
      useGradient: t < 0.5 ? useGradient : other.useGradient,
    );
  }
}

class _SearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final AppSection section;

  _SearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.section,
  });
}

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuizHomePage();
  }
}

bool _isDesktopPlatform() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

// Alias to avoid conflict with the page class.
class TeachModePage extends StatelessWidget {
  const TeachModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeachModePageScreen();
  }
}
