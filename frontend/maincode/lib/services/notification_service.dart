// This service manages all local notifications for the app, including scheduling, permissions, and cancellation. 
//It uses flutter_local_notifications for cross-platform support and timezone package to handle timezones correctly. 

//The service provides methods to schedule daily reminders, weekly reminders, one-time notifications, and repeating notifications at specific times.
 
//It also includes utility methods to generate unique notification IDs based on pet IDs and appointment IDs.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelDaily = AndroidNotificationDetails(
    'petsync_daily',
    'Daily Reminders',
    channelDescription: 'Feeding and metric logging reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _channelAppt = AndroidNotificationDetails(
    'petsync_appointments',
    'Appointment Reminders',
    channelDescription: 'Upcoming vet appointment reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Initialises the notification plugin with platform settings and sets the local timezone.
  /// No-op on web. Safe to call multiple times (guarded by _initialized flag).
  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async { // Call this on app startup to ensure permissions are requested early
    if (kIsWeb) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a notification to fire every day at the given [hour]:[minute].
  /// If the time has already passed today, the first firing is tomorrow.
  Future<void> scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: _channelDaily, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules a notification to fire every Monday at the given [hour]:[minute].
  Future<void> scheduleWeeklyMonday({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != DateTime.monday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: _channelDaily, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Schedules a one-time notification at the exact [dateTime]. Silently skips if the time is in the past.
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (kIsWeb) return;
    final tzDateTime = tz.TZDateTime.from(dateTime, tz.local);
    if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(android: _channelAppt, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules a notification that repeats daily at [hour]:[minute].
  /// [intervalMinutes] is accepted for API consistency but the underlying schedule uses daily repeat.
  Future<void> scheduleRepeatingAt({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int intervalMinutes,
  }) async {
    if (kIsWeb) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: _channelDaily, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async { if (!kIsWeb) await _plugin.cancel(id); }
  Future<void> cancelAll() async { if (!kIsWeb) await _plugin.cancelAll(); }

  /// Generates a stable notification ID for a feeding-end event from a string event key.
  static int feedingEndId(String eventBaseId) => 50000000 + eventBaseId.hashCode.abs() % 1000000;

  /// Generates a stable daily-feeding notification ID from pet ID and time string (e.g. "08:30").
  static int feedingId(int petId, String timeStr) {
    final parts = timeStr.split(':');
    final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return petId * 10000 + minutes;
  }

  /// Generates a stable notification ID for an appointment reminder.
  static int appointmentNotifId(int appointmentId) => 20000000 + appointmentId;

  /// Generates a stable notification ID for a metrics logging reminder.
  static int metricsId(int petId) => 30000000 + petId;

  /// Generates a stable notification ID for a daily advice/tip notification.
  static int adviceId(int petId) => 40000000 + petId;
}
