import '../entities/task.dart';
import '../entities/task_snapshot.dart';
import '../entities/task_validation.dart';
import '../repositories/task_repository.dart';

class ManageTasks {
  const ManageTasks(this.repository);
  final TaskRepository repository;

  Future<TaskSnapshot> load() => repository.load();

  Future<void> save(Task task) {
    try {
      validateTask(task);
    } on FormatException catch (error) {
      throw ArgumentError(error.message);
    }
    return repository.save(task.copyWith(title: task.title.trim()));
  }

  Future<void> delete(Task task) => repository.delete(task.id);

  Future<void> replaceAll(List<Task> tasks, {bool createBackup = false}) {
    validateTasks(tasks);
    return repository.replaceAll(tasks, createBackup: createBackup);
  }

  Future<TaskSnapshot> restoreBackup() => repository.restoreBackup();
}
