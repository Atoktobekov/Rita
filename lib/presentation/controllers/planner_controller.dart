import 'package:flutter/foundation.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/manage_tasks.dart';
import '../../domain/usecases/task_statistics.dart';

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
  TaskStatistics get statistics => TaskStatistics(_tasks, today);

  Future<void> initialize() async {
    _tasks = await actions.load();
  }

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

  Future<void> _mutate(Future<void> Function() action) async {
    if (busy) throw StateError('Изменение задач уже выполняется');
    busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> save(Task task) => _mutate(() async {
    final clean = task.copyWith(title: task.title.trim());
    await actions.save(clean);
    _tasks = [..._tasks.where((t) => t.id != clean.id), clean];
  });
  Future<void> delete(Task task) => _mutate(() async {
    await actions.delete(task);
    _tasks = _tasks.where((t) => t.id != task.id).toList();
  });
}
