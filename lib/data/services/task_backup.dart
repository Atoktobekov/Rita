import 'dart:convert';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_validation.dart';
import '../models/task_record.dart';

class TaskBackup {
  TaskBackup(List<Task> tasks, this.createdAt)
    : tasks = List.unmodifiable(tasks);
  static const maxBytes = 10 * 1024 * 1024;
  static const maxTasks = 20000;
  final List<Task> tasks;
  final DateTime createdAt;

  static TaskBackup decode(List<int> bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Файл больше 10 МБ');
    }
    final dynamic data = jsonDecode(utf8.decode(bytes));
    if (data is! Map ||
        data['format'] != 'daily-todo-tasks' ||
        data['version'] != 1 ||
        data['tasks'] is! List ||
        data['createdAt'] is! String) {
      throw const FormatException('Это не поддерживаемая копия задач Rita');
    }
    final createdAt = DateTime.tryParse(data['createdAt'] as String);
    if (createdAt == null) {
      throw const FormatException('Некорректная дата копии');
    }
    final records = data['tasks'] as List;
    if (records.length > maxTasks) {
      throw const FormatException('В копии больше 20 000 задач');
    }
    final tasks = records.map(TaskRecord.decode).toList();
    validateTasks(tasks);
    return TaskBackup(tasks, createdAt);
  }

  static List<int> encode(List<Task> tasks, DateTime now) {
    validateTasks(tasks);
    if (tasks.length > maxTasks) {
      throw const FormatException('В копии больше 20 000 задач');
    }
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'format': 'daily-todo-tasks',
        'version': 1,
        'createdAt': now.toUtc().toIso8601String(),
        'tasks': tasks.map(TaskRecord.encode).toList(),
      }),
    );
    if (bytes.length > maxBytes) {
      throw const FormatException('Копия больше 10 МБ');
    }
    return bytes;
  }
}
