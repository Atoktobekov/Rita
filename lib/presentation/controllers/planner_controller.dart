import 'package:flutter/foundation.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_snapshot.dart';
import '../../domain/usecases/manage_tasks.dart';
import '../../domain/usecases/task_statistics.dart';

class TaskCopy {
  TaskCopy(Iterable<Task> tasks) : tasks = List.unmodifiable(tasks);
  final List<Task> tasks;
}

class PlannerController extends ChangeNotifier {
  PlannerController(this.actions, {this.clock = DateTime.now}) {
    today = dateOnly(clock());
    selected = today;
  }
  final ManageTasks actions;
  final DateTime Function() clock;
  List<Task> _tasks = [];
  late DateTime today;
  late DateTime selected;
  bool busy = false;
  int damagedCount = 0;
  bool canRestore = false;
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get selectedTasks =>
      _tasks.where((t) => t.day == dayKey(selected)).toList();
  List<String> get pastDays =>
      _tasks
          .map((t) => t.day)
          .where((day) => day.compareTo(dayKey(today)) < 0)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  List<String> get futureDays =>
      _tasks
          .map((t) => t.day)
          .where((day) => day.compareTo(dayKey(today)) > 0)
          .toSet()
          .toList()
        ..sort();
  TaskStatistics get statistics => TaskStatistics(_tasks, today);

  void _accept(TaskSnapshot snapshot) {
    _tasks = snapshot.tasks;
    damagedCount = snapshot.damagedCount;
    canRestore = snapshot.canRestore;
  }

  Future<void> initialize() async => _accept(await actions.load());

  void select(DateTime day) {
    selected = dateOnly(day);
    notifyListeners();
  }

  void refreshDate() {
    final now = dateOnly(clock());
    if (now == today) return;
    if (selected == today) selected = now;
    today = now;
    notifyListeners();
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    if (busy) throw StateError('Изменение задач уже выполняется');
    busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> save(Task task) => _mutate(() async {
    final clean = task.copyWith(title: task.title.trim());
    await actions.save(clean);
    final exists = _tasks.any((t) => t.id == clean.id);
    _tasks = [
      for (final current in _tasks) current.id == clean.id ? clean : current,
      if (!exists) clean,
    ];
  });

  Future<void> delete(Task task) => _mutate(() async {
    await actions.delete(task);
    _tasks = _tasks.where((t) => t.id != task.id).toList();
  });

  Future<void> importTasks(List<Task> tasks) => _mutate(() async {
    final next = List<Task>.of(tasks);
    await actions.replaceAll(next, createBackup: true);
    _tasks = next;
    canRestore = true;
  });

  Future<void> restoreBackup() => _mutate(() async {
    _accept(await actions.restoreBackup());
  });

  Future<void> copyToToday(Task task) async {
    final destination = dayKey(clock());
    if (task.day.compareTo(destination) >= 0) {
      throw StateError('Выберите задачу прошедшего дня');
    }
    await _copyTasks([task], destination);
  }

  Future<TaskCopy> copyUnfinishedToTomorrow() async {
    if (selected.isAfter(today)) {
      throw StateError('Выберите сегодняшний или прошедший день');
    }
    return _copyTasks(
      selectedTasks.where((task) => !task.done),
      dayKey(nextDay(today)),
    );
  }

  Future<TaskCopy> _copyTasks(Iterable<Task> tasks, String destination) =>
      _mutate(() async {
        final ids = _tasks.map((t) => t.id).toSet();
        var serial = DateTime.now().microsecondsSinceEpoch;
        final copies = <Task>[];
        for (final task in tasks) {
          String id;
          do {
            id = 'copy-${serial++}';
          } while (!ids.add(id));
          copies.add(
            Task(
              id: id,
              title: task.title,
              day: destination,
              category: task.category,
            ),
          );
        }
        if (copies.isNotEmpty) {
          final next = [..._tasks, ...copies];
          await actions.replaceAll(next);
          _tasks = next;
        }
        return TaskCopy(copies);
      });

  Future<void> undoCopy(TaskCopy copy) => _mutate(() async {
    final byId = {for (final task in _tasks) task.id: task};
    for (final original in copy.tasks) {
      final current = byId[original.id];
      if (current == null ||
          current.day != original.day ||
          current.title != original.title ||
          current.category != original.category ||
          current.done != original.done) {
        throw StateError('Скопированные задачи уже изменились');
      }
    }
    final ids = copy.tasks.map((t) => t.id).toSet();
    final next = _tasks.where((t) => !ids.contains(t.id)).toList();
    await actions.replaceAll(next);
    _tasks = next;
  });
}
