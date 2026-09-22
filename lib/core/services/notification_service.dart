import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings =
          InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(settings);
      _initialized = true;
      debugPrint("NotificationService initialized successfully.");
    } catch (e) {
      debugPrint("NotificationService initialization error: $e");
    }
  }

  /// Schedules daily practice reminder at 7:00 PM (19:00).
  Future<void> scheduleDailyPracticeReminder({bool enabled = true}) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    try {
      if (!enabled) {
        await _notificationsPlugin.cancel(101);
        debugPrint("Daily practice reminder cancelled.");
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_practice_channel',
        'Daily Practice Reminders',
        channelDescription: 'Reminds students to maintain their daily placement practice streak.',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      // Schedule at 7:00 PM (19:00) every day
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        19, // 7 PM
        0,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        101,
        'Keep your streak going 🔥',
        '10 minutes of practice daily makes a huge difference!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint("Scheduled daily reminder for $scheduledDate");
    } catch (e) {
      debugPrint("Schedule reminder error: $e");
    }
  }
}
