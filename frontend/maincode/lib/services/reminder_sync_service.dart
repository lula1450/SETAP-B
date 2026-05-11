import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maincode/services/auth_service.dart';
import 'package:maincode/services/notification_service.dart';

class ReminderSyncService {
  static String get _baseUrl =>
      kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

  /// Fetches all pending reminders for [ownerId], schedules local notifications
  /// for each, then marks them as sent in the backend.
  Future<void> syncReminders(int ownerId) async {
    if (kIsWeb) return;
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/schedule/reminders/pending/$ownerId'),
        headers: headers,
      );
      if (response.statusCode != 200) return;

      final reminders = jsonDecode(response.body) as List<dynamic>;
      final svc = NotificationService();

      for (final r in reminders) {
        final reminderId = r['reminder_id'] as int;
        final type = r['type'] as String;
        final title = r['title'] as String;
        final body = r['body'] as String;
        final petId = r['pet_id'] as int;

        if (type == 'appointment') {
          final dt = DateTime.tryParse(r['reminder_datetime'] as String);
          if (dt != null && dt.isAfter(DateTime.now())) {
            await svc.scheduleOnce(
              id: NotificationService.appointmentNotifId(reminderId),
              title: title,
              body: body,
              dateTime: dt,
            );
          }
        } else if (type == 'feeding') {
          final hour = r['feeding_hour'] as int;
          final minute = r['feeding_minute'] as int;
          await svc.scheduleDailyAt(
            id: NotificationService.feedingId(petId, '$hour:$minute'),
            title: title,
            body: body,
            hour: hour,
            minute: minute,
          );
        }

        await http.patch(
          Uri.parse('$_baseUrl/schedule/reminders/$reminderId/status'),
          headers: await AuthService.authHeaders(),
          body: jsonEncode({'status': 'sent'}),
        );
      }
    } catch (e) {
      debugPrint('ReminderSyncService: $e');
    }
  }
}
