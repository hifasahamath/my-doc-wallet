import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/data/models/document.dart';

/// Schedules local notifications for document expiry reminders.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Schedule expiry reminders for a document.
  Future<void> scheduleExpiryReminders(Document doc) async {
    if (doc.expiryDate == null) return;
    await cancelReminders(doc.id);

    final daysUntil = doc.expiryDate!.difference(DateTime.now()).inDays;
    final reminders = <int>[
      AppConstants.expiryWarning30,
      AppConstants.expiryWarning7,
      AppConstants.expiryWarning1,
    ];

    for (final daysBefore in reminders) {
      if (daysUntil > daysBefore) {
        final scheduleDate =
            doc.expiryDate!.subtract(Duration(days: daysBefore));
        final scheduledAt = tz.TZDateTime.from(
          DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day, 9),
          tz.local,
        );

        if (scheduledAt.isAfter(tz.TZDateTime.now(tz.local))) {
          final notifId = _notificationId(doc.id, daysBefore);
          await _plugin.zonedSchedule(
            id: notifId,
            title: 'Document Expiring Soon',
            body: '${doc.name} expires in $daysBefore day${daysBefore == 1 ? '' : 's'}',
            scheduledDate: scheduledAt,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                AppConstants.notificationChannelId,
                AppConstants.notificationChannelName,
                channelDescription: AppConstants.notificationChannelDesc,
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: doc.id,
          );
        }
      }
    }
  }

  /// Cancel all reminders for a document.
  Future<void> cancelReminders(String documentId) async {
    for (final days in [30, 7, 1]) {
      await _plugin.cancel(id: _notificationId(documentId, days));
    }
  }

  int _notificationId(String documentId, int daysBefore) {
    return (documentId.hashCode + daysBefore).abs() % 2147483647;
  }
}
