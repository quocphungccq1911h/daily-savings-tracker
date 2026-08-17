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

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

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
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Lên lịch thông báo hàng ngày lúc 20:00 (8:00 Tối)
  Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
    String title = '🐖 Sổ Tiết Kiệm Daily - Nhắc Nhở Tối',
    String body = 'Hôm nay bạn đã hoàn thành mục tiêu tiết kiệm 150.000 đ chưa? Hãy chốt sổ ngay nhé! ✨',
  }) async {
    await init();
    await cancelAll(); // Hủy các lịch cũ để tránh trùng lặp

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_savings_reminder_channel',
      'Nhắc Nhở Tiết Kiệm Hàng Ngày',
      channelDescription: 'Kênh phát thông báo nhắc nhở nạp tiền tiết kiệm vào buổi tối hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      888, // Unique ID cho Lịch Nhắc Nhở Hàng Ngày
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp lại cùng giờ mỗi ngày
    );

    debugPrint('Successfully scheduled daily reminder for $hour:$minute');
  }

  /// Phát thông báo thử nghiệm ngay lập tức để kiểm tra
  Future<void> showTestNotification() async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_savings_reminder_channel',
      'Nhắc Nhở Tiết Kiệm Hàng Ngày',
      channelDescription: 'Kênh phát thông báo nhắc nhở nạp tiền tiết kiệm vào buổi tối hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      999,
      '🔔 Thử Nghiệm Thông Báo Tối!',
      'Hôm nay bạn đã chốt sổ tiết kiệm 150.000 đ chưa? Hãy mở ứng dụng để tích lũy ngay!',
      notificationDetails,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
