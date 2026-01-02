import 'package:flutter/material.dart';

import '../main.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../models/note.dart';
import '../models/quiz.dart';
import '../models/quiz_question.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key, required this.onNavigate});

  final ValueChanged<AppSection> onNavigate;

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int subjects = 0;
  int topics = 0;
  int notes = 0;
  int decks = 0;
  int cards = 0;
  int quizzes = 0;
  int questions = 0;
  List<double> _trendData = const [];
  bool _usageLogged = false;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadTrend();
  }

  Future<void> _loadStats() async {
    final s = await isar.collection<Subject>().count();
    final t = await isar.collection<Topic>().count();
    final n = await isar.collection<Note>().count();
    final d = await isar.collection<FlashcardDeck>().count();
    final c = await isar.collection<Flashcard>().count();
    final qz = await isar.collection<Quiz>().count();
    final qq = await isar.collection<QuizQuestion>().count();
    if (!mounted) return;
    setState(() {
      subjects = s;
      topics = t;
      notes = n;
      decks = d;
      cards = c;
      quizzes = qz;
      questions = qq;
      loading = false;
    });
  }

  Future<void> _loadTrend() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('usage_trend_v1') ?? const [];
    final parsed = raw.map((e) => double.tryParse(e) ?? 0).toList();
    setState(() {
      _trendData = parsed.isEmpty ? List.filled(7, 0) : parsed.take(14).toList();
    });
    if (!_usageLogged) {
      await _bumpToday();
    }
  }

  Future<void> _bumpToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final stored = prefs.getString('usage_trend_date');
    final lastDate = stored != null ? DateTime.tryParse(stored) : null;
    // If last entry is today, increment; else shift and add a fresh point.
    final data = List<double>.from(_trendData.isEmpty ? List.filled(7, 0) : _trendData);
    if (lastDate != null &&
        lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day) {
      if (data.isEmpty) data.add(0);
      data[data.length - 1] = data.last + 1;
    } else {
      data.add(1);
      if (data.length > 7) {
        data.removeAt(0);
      }
    }
    await prefs.setStringList('usage_trend_v1', data.map((d) => d.toString()).toList());
    await prefs.setString('usage_trend_date', today.toIso8601String());
    setState(() {
      _trendData = data;
      _usageLogged = true;
    });
  }

  Widget _statCard(String label, int value, IconData icon, Color accent) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodyMedium),
              Text(
                value.toString(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(colors, textTheme),
          const SizedBox(height: 20),
          loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: MediaQuery.of(context).size.width > 1024 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3,
                  children: [
                    _statCard("Subjects", subjects, Icons.book_outlined, colors.primary),
                    _statCard("Topics", topics, Icons.folder_open, colors.secondary),
                    _statCard("Notes", notes, Icons.description_outlined, colors.primary),
                    _statCard("Decks", decks, Icons.layers_outlined, colors.secondary),
                    _statCard("Cards", cards, Icons.style_outlined, colors.primary),
                    _statCard("Quizzes", quizzes, Icons.quiz_outlined, colors.secondary),
                    _statCard("Questions", questions, Icons.list_alt_outlined, colors.primary),
                  ],
                ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_outlined, color: colors.primary),
                    const SizedBox(width: 8),
                    Text("Next steps", style: textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Review due flashcards, create a quick quiz for your latest topic, or start a new note session.",
                  style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text("Focus tips", style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _tipChip(Icons.timer_outlined, "Try a 25m focus block on your hardest topic."),
              _tipChip(Icons.replay_outlined, "Warm up with 10 due flashcards before notes."),
              _tipChip(Icons.task_alt_outlined, "Create 5 MC questions for a quick quiz."),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ColorScheme colors, TextTheme textTheme) {
    final hasData = _trendData.any((e) => e > 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceContainer.withOpacity(0.9),
            colors.surfaceContainerHigh.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Study pulse", style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    hasData
                        ? "Productivity over recent sessions"
                        : "No sessions yet — your first activity will appear here.",
                    style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: "Refresh",
                icon: const Icon(Icons.refresh),
                onPressed: _loadStats,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: hasData
                ? _buildTrendCard(colors, textTheme, showFrame: false)
                : _emptySparkline(colors, textTheme),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickAction(
                Icons.add_chart_outlined,
                "New quiz",
                onTap: () => widget.onNavigate(AppSection.quizzes),
              ),
              _quickAction(
                Icons.note_add_outlined,
                "New note",
                onTap: () => widget.onNavigate(AppSection.notes),
              ),
              _quickAction(
                Icons.library_add_outlined,
                "New deck",
                onTap: () => widget.onNavigate(AppSection.flashcards),
              ),
              _quickAction(
                Icons.bookmark_add_outlined,
                "New subject",
                onTap: () => widget.onNavigate(AppSection.notes),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, {VoidCallback? onTap}) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(label, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _emptySparkline(ColorScheme colors, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
      ),
      child: Center(
        child: Text(
          "No activity yet. Your first study session will light up this chart.",
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _tipChip(IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Text(text, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildTrendCard(ColorScheme colors, TextTheme textTheme, {bool showFrame = true}) {
    final maxValRaw = _trendData.isEmpty ? 0.0 : _trendData.reduce((a, b) => a > b ? a : b);
    final maxVal = maxValRaw <= 0 ? 1.0 : maxValRaw;
    final hasAny = _trendData.any((e) => e > 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: showFrame ? colors.surfaceContainerHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: showFrame ? Border.all(color: colors.outline) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: colors.primary),
              const SizedBox(width: 8),
              Text("Productivity (last 7 sessions)", style: textTheme.labelLarge),
              const Spacer(),
              Text(
                "${_trendData.isEmpty ? 0 : _trendData.last.toInt()} pts",
                style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _SparklinePainter(
                data: _trendData,
                color: colors.primary,
                maxY: maxVal,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Older sessions",
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                Text("Newest", style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasAny
                ? "Y-axis: points per session • X-axis: recent sessions (older → newer)"
                : "No activity yet. Your first sessions will plot here.",
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double maxY;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.25),
          color.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    final fillPath = Path();

    if (data.length == 1) {
      final norm = maxY == 0 ? 0 : (data.first / maxY);
      final y = size.height - (norm * size.height * 0.9);
      final x = size.width * 0.5;
      canvas.drawCircle(Offset(x, y), 3, paint..style = PaintingStyle.fill);
      return;
    }

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final norm = maxY == 0 ? 0 : (data[i] / maxY);
      final y = size.height - (norm * size.height * 0.9);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color || oldDelegate.maxY != maxY;
  }
}
