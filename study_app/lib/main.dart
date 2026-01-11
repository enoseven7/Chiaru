import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
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

    final headlineFont =
        GoogleFonts.workSans().copyWith(fontFamilyFallback: const ['Segoe UI Variable', 'Segoe UI']);
    final bodyFont =
        GoogleFonts.inter().copyWith(fontFamilyFallback: const ['Segoe UI Variable', 'Segoe UI']);

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
        backgroundColor: baseColorScheme.surface,
        foregroundColor: baseColorScheme.onSurface,
        elevation: 2,
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
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseColorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: baseColorScheme.outline.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: baseColorScheme.outline.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: baseColorScheme.primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: baseColorScheme.primary,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: BorderSide(color: baseColorScheme.outline.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                        padding: const EdgeInsets.fromLTRB(12, 4, 16, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.outline),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _buildSection(),
                          ),
                        ),
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

  NavigationRail _buildRail(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1180;
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
      (AppSection.settings, Icons.settings_outlined, 'Settings'),
    ];
    final selectedIndex = destinations.indexWhere((d) => d.$1 == currentSection);

    return NavigationRail(
      extended: isWide,
      minExtendedWidth: 180,
      backgroundColor: Colors.transparent,
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) => setState(() => currentSection = destinations[i].$1),
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
        child: Column(
          children: 
          [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
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
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Chiaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline),
              ),
              child: InkWell(
                onTap: _openSearch,
                child: Row(
                  children: [
                    Icon(Icons.search, color: colors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Search notes, cards, quizzes...',
                      style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.outline),
                      ),
                      child: Text('Ctrl + K', style: textTheme.labelLarge),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => setState(() => currentSection = AppSection.planner),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Quick add'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: _kioskMode ? 'Exit fullscreen' : 'Enter fullscreen',
            onPressed: _toggleKioskMode,
            icon: Icon(_kioskMode ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
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
