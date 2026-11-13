import '../../domain/entities/task.dart';
import '../../domain/entities/task_validation.dart';

class TaskRecord {
  static Task decode(dynamic value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['title'] is! String ||
        value['day'] is! String ||
        (value['category'] != null && value['category'] is! String) ||
        (value['done'] != null && value['done'] is! bool)) {
      throw const FormatException('Некорректная запись задачи');
    }
    final task = Task(
      id: value['id'] as String,
      title: value['title'] as String,
      day: value['day'] as String,
      category: value['category'] as String? ?? 'Личное',
      done: value['done'] as bool? ?? false,
    );
    validateTask(task);
    return task;
  }

  static Map<String, dynamic> encode(Task task) => {
    'id': task.id,
    'title': task.title,
    'day': task.day,
    'category': task.category,
    'done': task.done,
  };
}
