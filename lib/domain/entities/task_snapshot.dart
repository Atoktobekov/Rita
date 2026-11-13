import 'task.dart';

class TaskSnapshot {
  TaskSnapshot(
    Iterable<Task> tasks, {
    this.damagedCount = 0,
    this.canRestore = false,
  }) : tasks = List.unmodifiable(tasks);
  final List<Task> tasks;
  final int damagedCount;
  final bool canRestore;
}
