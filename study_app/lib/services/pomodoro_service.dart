import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Service for managing Pomodoro timer sessions
///
/// Implements the Pomodoro Technique: 25-minute focus sessions followed by
/// short breaks (5 min), with a longer break (15 min) after 4 sessions.
class PomodoroService extends ChangeNotifier {
  static final PomodoroService instance = PomodoroService._();
  PomodoroService._();

  // Default durations (in minutes)
  static const int defaultWorkDuration = 25;
  static const int defaultShortBreakDuration = 5;
  static const int defaultLongBreakDuration = 15;
  static const int sessionsBeforeLongBreak = 4;

  // Current settings
  int workDuration = defaultWorkDuration;
  int shortBreakDuration = defaultShortBreakDuration;
  int longBreakDuration = defaultLongBreakDuration;

  // Session state
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  int _remainingSeconds = defaultWorkDuration * 60;
  int _completedSessions = 0;
  bool _isRunning = false;
  Timer? _timer;

  // Statistics
  int _totalWorkMinutes = 0;
  int _totalSessions = 0;

  PomodoroPhase get currentPhase => _currentPhase;
  int get remainingSeconds => _remainingSeconds;
  int get completedSessions => _completedSessions;
  bool get isRunning => _isRunning;
  int get totalWorkMinutes => _totalWorkMinutes;
  int get totalSessions => _totalSessions;

  String get remainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    final totalSeconds = _currentPhase == PomodoroPhase.work
        ? workDuration * 60
        : (_completedSessions % sessionsBeforeLongBreak == 0 && _completedSessions > 0)
            ? longBreakDuration * 60
            : shortBreakDuration * 60;
    return (_remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    workDuration = prefs.getInt('pomodoro_work_duration') ?? defaultWorkDuration;
    shortBreakDuration = prefs.getInt('pomodoro_short_break') ?? defaultShortBreakDuration;
    longBreakDuration = prefs.getInt('pomodoro_long_break') ?? defaultLongBreakDuration;
    _totalWorkMinutes = prefs.getInt('pomodoro_total_work_minutes') ?? 0;
    _totalSessions = prefs.getInt('pomodoro_total_sessions') ?? 0;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_work_duration', workDuration);
    await prefs.setInt('pomodoro_short_break', shortBreakDuration);
    await prefs.setInt('pomodoro_long_break', longBreakDuration);
  }

  Future<void> _saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_total_work_minutes', _totalWorkMinutes);
    await prefs.setInt('pomodoro_total_sessions', _totalSessions);
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void reset() {
    pause();
    _currentPhase = PomodoroPhase.work;
    _remainingSeconds = workDuration * 60;
    _completedSessions = 0;
    notifyListeners();
  }

  void skip() {
    pause();
    _completePhase();
  }

  void _tick(Timer timer) {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _completePhase();
    }
  }

  void _completePhase() {
    if (_currentPhase == PomodoroPhase.work) {
      // Work session completed
      _completedSessions++;
      _totalSessions++;
      _totalWorkMinutes += workDuration;
      _saveStatistics();

      // Determine next break type
      if (_completedSessions % sessionsBeforeLongBreak == 0) {
        _currentPhase = PomodoroPhase.longBreak;
        _remainingSeconds = longBreakDuration * 60;

        // Notify user it's time for a long break
        NotificationService.instance.showPomodoroNotification(
          title: 'Work Session Complete!',
          body: 'Great job! Time for a $longBreakDuration-minute long break.',
        );
      } else {
        _currentPhase = PomodoroPhase.shortBreak;
        _remainingSeconds = shortBreakDuration * 60;

        // Notify user it's time for a short break
        NotificationService.instance.showPomodoroNotification(
          title: 'Work Session Complete!',
          body: 'Well done! Take a $shortBreakDuration-minute break.',
        );
      }
    } else {
      // Break completed, start new work session
      _currentPhase = PomodoroPhase.work;
      _remainingSeconds = workDuration * 60;

      // Notify user it's time to get back to work
      NotificationService.instance.showPomodoroNotification(
        title: 'Break Complete!',
        body: 'Ready to focus? Start your next $workDuration-minute work session.',
      );
    }

    // Auto-pause after phase completion (user can manually start next phase)
    pause();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

enum PomodoroPhase {
  work,
  shortBreak,
  longBreak,
}

final pomodoroService = PomodoroService.instance;
