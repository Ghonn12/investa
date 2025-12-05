import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:get/get.dart';
import 'dart:developer';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<NotificationService> init() async {
    tz.initializeTimeZones();

    // Konfigurasi Notifikasi Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // pastikan ada icon

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await notificationsPlugin.initialize(initializationSettings);
    log('✅ Notification Service Initialized');

    // Jadwalkan notifikasi market langsung saat init
    await scheduleMarketNotifications();

    return this;
  }

  /// Notifikasi sekali langsung tampil
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Notifikasi Instan',
      channelDescription: 'Saluran untuk notifikasi instan.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(id, title, body, platformDetails);
  }

  /// Jadwal notifikasi sekali di waktu tertentu (non-exact)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'schedule_channel',
      'Notifikasi Terjadwal',
      channelDescription: 'Saluran untuk notifikasi sekali di waktu tertentu.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    final tz.TZDateTime tzScheduled =
    tz.TZDateTime.from(scheduledTime, tz.local);

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      platformDetails,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // ✅ aman
    );
  }

  /// Jadwal notifikasi market buka/tutup (non-exact, daily repeat)
  Future<void> scheduleMarketNotifications() async {
    final now = tz.TZDateTime.now(tz.local);

    Future<void> _schedule(
        int id, String title, String body, int hour, int minute) async {
      tz.TZDateTime scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'market_channel',
        'Market Notifications',
        channelDescription: 'Notifikasi buka/tutup market.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const platformDetails = NotificationDetails(android: androidDetails);

      await notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // ✅ repeat harian
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // ✅ aman
      );
      log("📌 Market Notification set for $hour:$minute");
    }

    // Market buka jam 09:00
    await _schedule(201, "📈 Market Open", "Pasar saham sesi pagi sudah dibuka!", 9, 0);

    // Market tutup jam 12:00
    await _schedule(202, "⏳ Market Close", "Pasar saham sesi pagi ditutup.", 12, 0);

    // Market buka jam 13:30
    await _schedule(203, "📈 Market Reopen", "Pasar saham sesi siang sudah dibuka!", 13, 30);

    // Market tutup jam 16:00
    await _schedule(204, "⏳ Market Close", "Pasar saham sesi siang ditutup.", 16, 0);
  }

  /// Batalkan notifikasi tertentu
  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
    log("❌ Notification $id cancelled");
  }

  /// Batalkan semua notifikasi
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
    log("❌ All notifications cancelled");
  }
}
