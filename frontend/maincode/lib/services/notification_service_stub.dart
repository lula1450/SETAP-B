class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {}
  Future<void> requestPermissions() async {}

  Future<void> scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {}

  Future<void> scheduleWeeklyMonday({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {}

  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {}

  Future<void> scheduleRepeatingAt({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int intervalMinutes,
  }) async {}

  Future<void> cancel(int id) async {}
  Future<void> cancelAll() async {}

  static int feedingId(int petId, String timeStr) {
    final parts = timeStr.split(':');
    final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return petId * 10000 + minutes;
  }

  static int appointmentNotifId(int appointmentId) => 20000000 + appointmentId;
  static int metricsId(int petId) => 30000000 + petId;
  static int adviceId(int petId) => 40000000 + petId;
}
