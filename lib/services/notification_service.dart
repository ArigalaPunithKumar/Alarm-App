import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';
import '../services/storage_service.dart';
import '../main.dart';
import '../screens/alarm_ringing_screen.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  debugPrint('Notification tapped in background: ${notificationResponse.payload}');
  if (notificationResponse.payload != null) {
    if (notificationResponse.actionId == 'stop_id') {
      final ns = NotificationService();
      await ns.cancelAlarm(notificationResponse.payload!);
    } else if (notificationResponse.actionId == 'snooze_id') {
      final ns = NotificationService();
      await ns.cancelAlarm(notificationResponse.payload!);
      // Snooze logic in background is complex due to timezone initialization limits in isolated context.
      // Basic stop is applied.
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped in foreground: ${response.payload}');
        if (response.payload != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => AlarmRingingScreen(payload: response.payload!),
            ),
          );
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    try {
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
    _initialized = true;
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    
    // Ensure we use the device's exact local timezone, avoiding any offset issues.
    final now = DateTime.now();
    if (alarm.scheduledDateTime.isBefore(now)) {
      debugPrint('Alarm is in the past, not scheduling');
      return;
    }
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(alarm.scheduledDateTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel_v5', // Changed channel to wipe bad sound configs
      'Alarm Notifications',
      channelDescription: 'Plays sound and shows notification for scheduled alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT loops sound infinitely
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      ticker: 'Alarm ringing!',
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('stop_id', 'Stop Alarm', showsUserInterface: true),
        const AndroidNotificationAction('snooze_id', 'Snooze (10m)', showsUserInterface: true),
      ],
    );
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    try {
      // Main Alarm
      await plugin.zonedSchedule(
        alarm.id.hashCode.abs(),
        '⏰ ${alarm.reason}',
        'Alarm for ${alarm.time} on ${alarm.date}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: alarm.id,
      );
      
      // Pre-Alarm
      final storage = StorageService();
      final preMins = await storage.getPreAlarmMins();
      if (preMins > 0) {
        final preAlarmDate = scheduledDate.subtract(Duration(minutes: preMins));
        if (preAlarmDate.isAfter(tz.TZDateTime.now(tz.local))) {
          final preDetails = const NotificationDetails(
            android: AndroidNotificationDetails(
              'pre_alarm_channel_v2',
              'Upcoming Alarms',
              channelDescription: 'Gentle notification before the actual alarm rings',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              playSound: false,
              enableVibration: false,
            ),
          );
          await plugin.zonedSchedule(
            alarm.id.hashCode.abs() + 100000,
            'Upcoming Alarm in $preMins mins',
            alarm.reason,
            preAlarmDate,
            preDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
      
      debugPrint('Alarm scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('Schedule alarm error: $e');
    }
  }

  Future<void> testNotification() async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel_v5', // MUST exactly match scheduleAlarm channel
      'Alarm Notifications',
      channelDescription: 'Test notification for alarm sound',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT loops sound infinitely
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('stop_id', 'Stop Alarm', showsUserInterface: true),
      ],
    );
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await plugin.show(
      0, // ID 0 for test
      '⏰ Test Alarm Ringing',
      'This is exactly how your scheduled alarm will ring!',
      notificationDetails,
      payload: 'test_payload', // Allows stopping it from the action button
    );
  }

  Future<void> cancelAlarm(String id) async {
    if (kIsWeb) return;
    // Catch 'test_payload' to stop the test notification using ID 0
    if (id == 'test_payload') {
      await plugin.cancel(0);
      return;
    }
    await plugin.cancel(id.hashCode.abs());
  }
}
