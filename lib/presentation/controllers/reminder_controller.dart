import 'package:flutter/foundation.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/usecases/manage_reminder.dart';

class ReminderController extends ChangeNotifier {
  ReminderController(this.actions);
  final ManageReminder actions;
  ReminderSettings settings = const ReminderSettings();
  bool busy = false;
  String? error;
  bool get supported => actions.supported;

  Future<void> initialize() async {
    try {
      settings = await actions.load();
    } catch (_) {
      error = 'Не удалось прочитать настройки напоминания.';
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (busy) return;
    busy = true;
    try {
      await actions.restore(settings);
      error = null;
    } catch (_) {
      error =
          'Не удалось запланировать напоминание. Попробуйте включить его снова.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> update(ReminderSettings next) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await actions.update(settings, next);
      settings = next;
      error = null;
    } on NotificationPermissionDenied {
      error =
          'Разрешите уведомления в настройках телефона, затем включите напоминание снова.';
    } catch (_) {
      error = 'Не удалось сохранить напоминание. Попробуйте ещё раз.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
