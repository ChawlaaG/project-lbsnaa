import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint("Notification tapped: ${response.payload}");
      },
    );
    
    // FCM: request permission and listen to foreground messages
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'cadre_fcm_channel', 'CADRE Updates',
              importance: Importance.high, priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<bool?> requestPermissions() async {
    return await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyBriefing() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'DAILY BRIEFING',
      body: 'Time to practice. Maintain your streak today.',
      scheduledDate: _nextInstanceOfSixAM(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_briefing_channel',
          'Daily Briefing',
          channelDescription: 'Daily reminders for UPSC aspirants',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  tz.TZDateTime _nextInstanceOfSixAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 6);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Phase 2: Drill Sergeant - Streak Protection (Evening Check)
  Future<void> scheduleStreakProtection() async {
    // Schedule for 8 PM
     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20); // 8 PM
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1,
      title: '⚠️ STREAK AT RISK',
      body: 'Don\'t let your streak break! Complete a quiz today.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'retention_channel',
          'Retention Alerts',
          channelDescription: 'Critical alerts for streak maintenance',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Schedule AWOL inactivity nudge after 24h of no activity.
  Future<void> scheduleInactivityNudge({String userName = 'OFFICER'}) async {
    await cancelInactivityNudge(); // Cancel any existing nudge
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 2,
      title: '⚠ CADET ${userName.toUpperCase()} — COME BACK',
      body: 'You haven\'t practiced today. One more day until your streak breaks.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'retention_channel',
          'Retention Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel the pending inactivity nudge (call on app open).
  Future<void> cancelInactivityNudge() async {
    await flutterLocalNotificationsPlugin.cancel(id: 2);
  }

  Future<void> cancelRetentionNotifications() async {
    await flutterLocalNotificationsPlugin.cancel(id: 1); // Cancel Streak Nudge
    await flutterLocalNotificationsPlugin.cancel(id: 2); // Cancel AWOL Alert
    debugPrint("Retention alarms disabled.");
  }
}
