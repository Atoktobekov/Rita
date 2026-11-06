import 'package:daily_todo/domain/entities/task.dart';
import 'package:daily_todo/domain/entities/reminder_settings.dart';
import 'package:daily_todo/domain/repositories/task_repository.dart';
import 'package:daily_todo/domain/repositories/reminder_repository.dart';

class MemoryTaskRepository implements TaskRepository {
  final List<Task> tasks = [];
  bool fail = false;
  @override
  Future<List<Task>> load() async => List.of(tasks);
  @override
  Future<void> save(Task task) async {
    if (fail) throw StateError('write failed');
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
  }

  @override
  Future<void> delete(String id) async {
    if (fail) throw StateError('delete failed');
    tasks.removeWhere((t) => t.id == id);
  }
}

class MemoryReminderRepository implements ReminderRepository {
  ReminderSettings settings = const ReminderSettings();
  bool fail = false;
  @override
  Future<ReminderSettings> load() async => settings;
  @override
  Future<void> save(ReminderSettings value) async {
    if (fail) throw StateError('settings write failed');
    settings = value;
  }
}

class FakeScheduler implements ReminderScheduler {
  @override
  bool supported = true;
  bool granted = true;
  bool fail = false;
  int requests = 0;
  ReminderSettings? scheduled;
  @override
  Future<bool> requestPermission() async {
    requests++;
    return granted;
  }

  @override
  Future<void> schedule(ReminderSettings settings) async {
    if (fail) throw StateError('schedule failed');
    scheduled = settings;
  }

  @override
  Future<void> cancel() async {
    scheduled = null;
  }
}
