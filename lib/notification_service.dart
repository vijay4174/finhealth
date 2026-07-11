import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );
  }

  static Future<bool> requestPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin
        ?.requestNotificationsPermission();

    return granted ?? false;
  }

  static Future<void> scheduleEmiReminder({
    required int notificationId,
    required String loanName,
    required double emiAmount,
    required DateTime dueDate,
  }) async {
    await cancelEmiReminders(
      notificationId,
    );

    final now = tz.TZDateTime.now(
      tz.local,
    );

    final dueDateTime = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    );

    final threeDaysBefore =
        dueDateTime.subtract(
      const Duration(days: 3),
    );

    if (threeDaysBefore.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: notificationId,
        title: 'EMI Due in 3 Days',
        body:
            '$loanName EMI ₹${emiAmount.toStringAsFixed(0)} is due on ${_formatDate(dueDate)}.',
        scheduledDate: threeDaysBefore,
        notificationDetails:
            _notificationDetails(),
        androidScheduleMode:
            AndroidScheduleMode
                .inexactAllowWhileIdle,
      );
    }

    if (dueDateTime.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: notificationId + 1,
        title: 'EMI Due Today',
        body:
            '$loanName EMI ₹${emiAmount.toStringAsFixed(0)} is due today.',
        scheduledDate: dueDateTime,
        notificationDetails:
            _notificationDetails(),
        androidScheduleMode:
            AndroidScheduleMode
                .inexactAllowWhileIdle,
      );
    }

    final overdueDate =
        dueDateTime.add(
      const Duration(days: 1),
    );

    if (overdueDate.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: notificationId + 2,
        title: 'EMI Payment Overdue',
        body:
            '$loanName EMI may be overdue. Check your payment status.',
        scheduledDate: overdueDate,
        notificationDetails:
            _notificationDetails(),
        androidScheduleMode:
            AndroidScheduleMode
                .inexactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancelEmiReminders(
    int notificationId,
  ) async {
    await _notifications.cancel(
      id: notificationId,
    );

    await _notifications.cancel(
      id: notificationId + 1,
    );

    await _notifications.cancel(
      id: notificationId + 2,
    );
  }

  static NotificationDetails
      _notificationDetails() {
    const androidDetails =
        AndroidNotificationDetails(
      'emi_reminders',
      'EMI Reminders',
      channelDescription:
          'Notifications for upcoming and overdue EMI payments',
      importance: Importance.high,
      priority: Priority.high,
    );

    return const NotificationDetails(
      android: androidDetails,
    );
  }

  static String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}