import '../entities/reminder_settings.dart';

abstract interface class ReminderRepository {
  Future<ReminderSettings> load();
  Future<void> save(ReminderSettings settings);
}

abstract interface class ReminderScheduler {
  bool get supported;
  Future<bool> requestPermission();
  Future<void> schedule(ReminderSettings settings);
  Future<void> cancel();
}
