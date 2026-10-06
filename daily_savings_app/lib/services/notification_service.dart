import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static NotificationService? _instance;
  factory NotificationService() => _instance ??= NotificationService._internal();
  NotificationService._internal();

  static const int dailyReminderId = 888;
  static const int testNotificationId = 999;
  static const String reminderChannelId = 'daily_savings_reminder_channel';
  static const String reminderChannelName = 'Nhắc Nhở Tiết Kiệm Hàng Ngày';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      // Initialize Timezones
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {
        // Fallback to local default if Asia/Ho_Chi_Minh is missing
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await init();
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final notifGranted = await androidPlugin.requestNotificationsPermission();
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (_) {}
        return notifGranted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  Future<bool> canScheduleExact() async {
    if (kIsWeb) return false;
    await init();
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final can = await androidPlugin.canScheduleExactNotifications();
        return can ?? true;
      }
    } catch (_) {}
    return true;
  }

  /// Đồng bộ lịch nhắc nhở 20:00 với trạng thái đã nạp tiền hay chưa
  Future<void> syncDailyReminderWithSavedStatus({
    required bool hasSavedToday,
    int hour = 20,
    int minute = 0,
    String title = '🐖 Sổ Tiết Kiệm Daily - Nhắc Nhở Tối',
    String body = 'Hôm nay bạn chưa chốt sổ tiết kiệm! Hãy mở app để tích lũy ngay nhé! ✨',
  }) async {
    if (kIsWeb) return;
    await init();

    // Hủy thông báo cũ để tránh duplicate
    await cancelDailyReminder();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Nếu hôm nay đã nạp tiền rồi -> Bỏ qua tối nay, hẹn tối mai
    if (hasSavedToday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('Today already saved! Rescheduled 20:00 reminder to tomorrow: $scheduledDate');
    } else {
      // Nếu chưa nạp tiền, nhưng hiện tại đã qua 20:00 hôm nay -> Hẹn tối mai
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('Past 20:00 today. Scheduled reminder to tomorrow: $scheduledDate');
      } else {
        debugPrint('Scheduled reminder for TONIGHT at $hour:$minute ($scheduledDate)');
      }
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      channelDescription: 'Kênh phát thông báo nhắc nhở nạp tiền tiết kiệm vào buổi tối hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        dailyReminderId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Successfully scheduled exact reminder at $hour:$minute');
    } catch (e) {
      debugPrint('Exact alarm scheduling failed ($e), falling back to inexact...');
      try {
        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('Successfully scheduled inexact reminder at $hour:$minute');
      } catch (err) {
        debugPrint('Failed to schedule reminder: $err');
      }
    }
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(dailyReminderId);
    } catch (_) {}
  }

  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      channelDescription: 'Kênh phát thông báo nhắc nhở nạp tiền tiết kiệm vào buổi tối hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      testNotificationId,
      '🔔 Thử Nghiệm Thông Báo Tối!',
      'Hôm nay bạn đã chốt sổ tiết kiệm 150.000 đ chưa? Hãy mở ứng dụng để tích lũy ngay!',
      notificationDetails,
    );
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancelAll();
  }
}
