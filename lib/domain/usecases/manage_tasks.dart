import '../../core/calendar.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class ManageTasks {
  const ManageTasks(this.repository);
  final TaskRepository repository;

  Future<List<Task>> load() => repository.load();

  Future<void> save(Task task) {
    if (task.title.trim().isEmpty || task.title.trim().length > 200) {
      throw ArgumentError(
        'Название задачи должно содержать от 1 до 200 символов',
      );
    }
    final date = DateTime.tryParse(task.day);
    if (date == null || dayKey(date) != task.day) {
      throw ArgumentError('Некорректная дата задачи');
    }
    return repository.save(task.copyWith(title: task.title.trim()));
  }

  Future<void> delete(Task task) => repository.delete(task.id);
}
