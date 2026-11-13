import '../entities/task.dart';
import '../entities/task_snapshot.dart';

abstract interface class TaskRepository {
  Future<TaskSnapshot> load();
  Future<void> save(Task task);
  Future<void> delete(String id);
  Future<void> replaceAll(List<Task> tasks, {bool createBackup = false});
  Future<TaskSnapshot> restoreBackup();
}
