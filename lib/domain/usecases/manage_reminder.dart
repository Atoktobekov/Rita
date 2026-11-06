import '../entities/reminder_settings.dart';
import '../repositories/reminder_repository.dart';

class NotificationPermissionDenied implements Exception {}

class ManageReminder {
  const ManageReminder(this.repository, this.scheduler);
  final ReminderRepository repository;
  final ReminderScheduler scheduler;
  bool get supported => scheduler.supported;
  Future<ReminderSettings> load() => repository.load();

  Future<void> restore(ReminderSettings settings) async {
    if (!supported) return;
    if (settings.enabled) {
      await scheduler.schedule(settings);
    } else {
      await scheduler.cancel();
    }
  }

  Future<void> update(ReminderSettings previous, ReminderSettings next) async {
    if (!supported) {
      throw UnsupportedError('Уведомления доступны на Android и iOS');
    }
    if (next.enabled && !await scheduler.requestPermission()) {
      throw NotificationPermissionDenied();
    }
    // Scheduling and storage form one user action. Restore the previous schedule
    // if either operation fails, leaving the visible settings unchanged.
    try {
      await restore(next);
      await repository.save(next);
    } catch (_) {
      try {
        await restore(previous);
      } catch (_) {
        /* Preserve original error. */
      }
      rethrow;
    }
  }
}
