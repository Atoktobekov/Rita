import '../../domain/entities/task.dart';

class TaskRecord {
  static Task decode(dynamic value) {
    final map = Map<String, dynamic>.from(value as Map);
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      day: map['day'] as String,
      category: map['category'] as String? ?? 'Личное',
      done: map['done'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> encode(Task task) => {
    'id': task.id,
    'title': task.title,
    'day': task.day,
    'category': task.category,
    'done': task.done,
  };
}
