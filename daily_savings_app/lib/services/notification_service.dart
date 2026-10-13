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
  static const int delayedTestNotificationId = 998;
  // Sử dụng channel ID v2 mới để đảm bảo Android tạo kênh với Importance.max (tránh trường hợp kênh cũ bị cache ở mức thấp)
  static const String reminderChannelId = 'daily_savings_reminder_channel_v2';
  static const String reminderChannelName = 'Nhắc Nhở Tiết Kiệm Hàng Ngày (20:00)';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      // 1. Khởi tạo múi giờ Việt Nam (Asia/Ho_Chi_Minh)
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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

      // 2. Chủ động đăng ký Notification Channel mức Importance.max với hệ điều hành Android
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          reminderChannelId,
          reminderChannelName,
          description:
              'Kênh phát thông báo nhắc nhở nạp tiền tiết kiệm vào 20:00 mỗi tối',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Tự động kiểm tra và xin quyền thông báo ngay khi vào App
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await init();
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? alreadyEnabled =
            await androidPlugin.areNotificationsEnabled();
        if (alreadyEnabled == true) {
          return true;
        }
        final bool? requested =
            await androidPlugin.requestNotificationsPermission();
        return requested ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  /// Mở màn hình cấp quyền Báo thức chính xác của hệ điều hành (nếu cần)
  Future<void> openExactAlarmSettings() async {
    if (kIsWeb) return;
    await init();
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (_) {}
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

  AndroidNotificationDetails _buildAndroidDetails() {
    return const AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      channelDescription:
          'Kênh phát thông báo nhắc nhở nạp tiền tiết kiệm vào 20:00 mỗi tối',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
  }

  /// Đồng bộ lịch nhắc nhở 20:00 với trạng thái đã nạp tiền hay chưa.
  /// Trả về chuỗi mô tả thời điểm báo thức tiếp theo để hiển thị rõ trên UI.
  Future<String> syncDailyReminderWithSavedStatus({
    required bool hasSavedToday,
    int hour = 20,
    int minute = 0,
    String title = '🐖 Sổ Tiết Kiệm Daily - Nhắc Nhở 20:00',
    String body =
        'Hôm nay bạn chưa chốt sổ tiết kiệm! Hãy mở app để tích lũy ngay nhé! ✨',
  }) async {
    if (kIsWeb) return 'Web mode';
    await init();

    // Đảm bảo quyền thông báo đã được cấp trước khi đặt lịch
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        if (enabled == false) {
          await androidPlugin.requestNotificationsPermission();
        }
      }
    } catch (_) {}

    // Hủy thông báo cũ để tránh trùng lặp
    await cancelDailyReminder();

    // Tính toán thời điểm 20:00 theo đúng giờ hệ thống của điện thoại
    final DateTime localNow = DateTime.now();
    DateTime targetLocal = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      hour,
      minute,
    );

    bool isForTomorrow = false;
    if (hasSavedToday) {
      targetLocal = targetLocal.add(const Duration(days: 1));
      isForTomorrow = true;
    } else if (targetLocal.isBefore(localNow)) {
      targetLocal = targetLocal.add(const Duration(days: 1));
      isForTomorrow = true;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      targetLocal.year,
      targetLocal.month,
      targetLocal.day,
      targetLocal.hour,
      targetLocal.minute,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: _buildAndroidDetails(),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Ưu tiên số 1: AndroidScheduleMode.alarmClock (Tương đương đồng hồ báo thức Android, không bao giờ bị Doze Mode hay tiết kiệm pin chặn)
    try {
      await _notificationsPlugin.zonedSchedule(
        dailyReminderId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
          'Scheduled ALARM_CLOCK reminder at $scheduledDate (tomorrow=$isForTomorrow)');
    } catch (e) {
      debugPrint('AlarmClock mode failed ($e), trying exactAllowWhileIdle...');
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
        debugPrint('Scheduled exactAllowWhileIdle reminder at $scheduledDate');
      } catch (e2) {
        debugPrint(
            'exactAllowWhileIdle failed ($e2), falling back to inexactAllowWhileIdle...');
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
        } catch (err) {
          debugPrint('Failed to schedule reminder: $err');
        }
      }
    }

    final dayLabel = isForTomorrow
        ? '20:00 Tối Mai (${targetLocal.day.toString().padLeft(2, '0')}/${targetLocal.month.toString().padLeft(2, '0')})'
        : '20:00 Tối Nay (${targetLocal.day.toString().padLeft(2, '0')}/${targetLocal.month.toString().padLeft(2, '0')})';
    return dayLabel;
  }

  /// Kiểm tra xem thông báo 20:00 có đang nằm trong hàng đợi chờ phát của Android hay không
  Future<bool> isDailyReminderPending() async {
    if (kIsWeb) return false;
    await init();
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      return pending.any((p) => p.id == dailyReminderId);
    } catch (_) {
      return false;
    }
  }

  /// Đặt thử một báo thức ngầm nổ sau [seconds] giây (để kiểm tra thực tế khi tắt màn hình / thoát app)
  Future<void> scheduleDelayedTestNotification({int seconds = 10}) async {
    if (kIsWeb) return;
    await init();

    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    final NotificationDetails notificationDetails = NotificationDetails(
      android: _buildAndroidDetails(),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        delayedTestNotificationId,
        '⏰ Kiểm Tra Báo Thức Ngầm Thành Công!',
        'Chuông hẹn giờ 20:00 hoạt động hoàn hảo ngay cả khi bạn đã đóng ứng dụng! 🎉',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          delayedTestNotificationId,
          '⏰ Kiểm Tra Báo Thức Ngầm Thành Công!',
          'Chuông hẹn giờ 20:00 hoạt động hoàn hảo ngay cả khi bạn đã đóng ứng dụng! 🎉',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        try {
          await _notificationsPlugin.zonedSchedule(
            delayedTestNotificationId,
            '⏰ Kiểm Tra Báo Thức Ngầm Thành Công!',
            'Chuông hẹn giờ 20:00 hoạt động hoàn hảo ngay cả khi bạn đã đóng ứng dụng! 🎉',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (err) {
          debugPrint('Delayed test notification failed: $err');
        }
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

    final NotificationDetails notificationDetails = NotificationDetails(
      android: _buildAndroidDetails(),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
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

