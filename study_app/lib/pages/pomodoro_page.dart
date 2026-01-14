import 'package:flutter/material.dart';
import '../services/pomodoro_service.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  @override
  void initState() {
    super.initState();
    pomodoroService.loadSettings();
    pomodoroService.addListener(_onPomodoroUpdate);
  }

  @override
  void dispose() {
    pomodoroService.removeListener(_onPomodoroUpdate);
    super.dispose();
  }

  void _onPomodoroUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase indicator
              _buildPhaseIndicator(colors, textTheme),
              const SizedBox(height: 32),

              // Circular timer display
              _buildTimerCircle(colors, textTheme),
              const SizedBox(height: 48),

              // Control buttons
              _buildControlButtons(colors),
              const SizedBox(height: 32),

              // Session counter
              _buildSessionCounter(colors, textTheme),
              const SizedBox(height: 24),

              // Statistics
              _buildStatistics(colors, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(ColorScheme colors, TextTheme textTheme) {
    final phase = pomodoroService.currentPhase;
    final phaseInfo = _getPhaseInfo(phase, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: phaseInfo.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: phaseInfo.color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(phaseInfo.icon, color: phaseInfo.color, size: 24),
          const SizedBox(width: 8),
          Text(
            phaseInfo.label,
            style: textTheme.titleLarge?.copyWith(
              color: phaseInfo.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(ColorScheme colors, TextTheme textTheme) {
    final phase = pomodoroService.currentPhase;
    final phaseInfo = _getPhaseInfo(phase, colors);
    final progress = pomodoroService.progress;

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                colors.surfaceContainerHigh,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: 1 - progress,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(phaseInfo.color),
            ),
          ),
          // Time text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pomodoroService.remainingTime,
                style: textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 56,
                  color: colors.onSurface,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pomodoroService.isRunning ? 'Running' : 'Paused',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        OutlinedButton.icon(
          onPressed: pomodoroService.reset,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        const SizedBox(width: 16),

        // Start/Pause button
        FilledButton.icon(
          onPressed: pomodoroService.isRunning
              ? pomodoroService.pause
              : pomodoroService.start,
          icon: Icon(pomodoroService.isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(pomodoroService.isRunning ? 'Pause' : 'Start'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            minimumSize: const Size(140, 52),
          ),
        ),
        const SizedBox(width: 16),

        // Skip button
        OutlinedButton.icon(
          onPressed: pomodoroService.skip,
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCounter(ColorScheme colors, TextTheme textTheme) {
    final sessions = pomodoroService.completedSessions;
    final sessionsInCycle = sessions % PomodoroService.sessionsBeforeLongBreak;

    return Column(
      children: [
        Text(
          'Session ${sessions + 1}',
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            PomodoroService.sessionsBeforeLongBreak,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < sessionsInCycle
                      ? colors.primary
                      : colors.surfaceContainerHighest,
                  border: Border.all(
                    color: colors.outline,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Text(
            'Statistics',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(
                'Total Sessions',
                pomodoroService.totalSessions.toString(),
                Icons.check_circle_outline,
                colors,
                textTheme,
              ),
              Container(width: 1, height: 40, color: colors.outline),
              _statItem(
                'Total Work Time',
                '${pomodoroService.totalWorkMinutes} min',
                Icons.timer_outlined,
                colors,
                textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String label,
    String value,
    IconData icon,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    int workDuration = pomodoroService.workDuration;
    int shortBreak = pomodoroService.shortBreakDuration;
    int longBreak = pomodoroService.longBreakDuration;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pomodoro Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Work Duration', style: textTheme.titleSmall),
              Slider(
                value: workDuration.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '$workDuration min',
                onChanged: (value) {
                  setDialogState(() => workDuration = value.round());
                },
              ),
              const SizedBox(height: 16),
              Text('Short Break', style: textTheme.titleSmall),
              Slider(
                value: shortBreak.toDouble(),
                min: 1,
                max: 15,
                divisions: 14,
                label: '$shortBreak min',
                onChanged: (value) {
                  setDialogState(() => shortBreak = value.round());
                },
              ),
              const SizedBox(height: 16),
              Text('Long Break', style: textTheme.titleSmall),
              Slider(
                value: longBreak.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '$longBreak min',
                onChanged: (value) {
                  setDialogState(() => longBreak = value.round());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                pomodoroService.workDuration = workDuration;
                pomodoroService.shortBreakDuration = shortBreak;
                pomodoroService.longBreakDuration = longBreak;
                pomodoroService.saveSettings();
                pomodoroService.reset();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  _PhaseInfo _getPhaseInfo(PomodoroPhase phase, ColorScheme colors) {
    switch (phase) {
      case PomodoroPhase.work:
        return _PhaseInfo(
          label: 'Focus Time',
          icon: Icons.work_outline,
          color: colors.primary,
        );
      case PomodoroPhase.shortBreak:
        return _PhaseInfo(
          label: 'Short Break',
          icon: Icons.coffee_outlined,
          color: Colors.green,
        );
      case PomodoroPhase.longBreak:
        return _PhaseInfo(
          label: 'Long Break',
          icon: Icons.self_improvement,
          color: Colors.blue,
        );
    }
  }
}

class _PhaseInfo {
  final String label;
  final IconData icon;
  final Color color;

  _PhaseInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}
