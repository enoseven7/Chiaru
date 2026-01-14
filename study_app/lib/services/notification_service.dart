import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// Handles local notification scheduling for task reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(_resolveLocalLocation());

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(defaultActionName: 'Study app notification');

    final initSettings = const InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) return;
    if (!task.reminderEnabled || task.dueAt == null) return;

    final scheduledTime = task.dueAt!.subtract(Duration(minutes: task.reminderMinutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'study_tasks',
      'Study Tasks',
      channelDescription: 'Reminders for due study tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      task.id,
      task.title,
      _buildBody(task),
      tzTime,
      const NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '${task.id}',
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (!_initialized) return;
    await _plugin.cancel(taskId);
  }

  /// Show an immediate notification for Pomodoro timer events
  Future<void> showPomodoroNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'pomodoro',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro timer sessions',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const linuxDetails = LinuxNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    await _plugin.show(
      999, // Using a fixed ID for Pomodoro notifications
      title,
      body,
      details,
    );
  }

  String _buildBody(Task task) {
    final dueLabel = task.dueAt != null ? _formatDue(task.dueAt!) : 'No due date';
    return 'Due $dueLabel • Priority: ${task.priority.name}';
  }

  String _formatDue(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day} $hour:$minute $amPm';
  }

  tz.Location _resolveLocalLocation() {
    try {
      return tz.getLocation(DateTime.now().timeZoneName);
    } catch (_) {
      return tz.local;
    }
  }
}
