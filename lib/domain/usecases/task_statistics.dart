import '../../core/calendar.dart';
import '../entities/task.dart';

class DayProgress {
  const DayProgress(this.day, this.total, this.completed);
  final DateTime day;
  final int total;
  final int completed;
  double get ratio => total == 0 ? 0 : completed / total;
}

class TaskStatistics {
  TaskStatistics(List<Task> tasks, DateTime today) {
    final eligible = tasks
        .where((t) => t.day.compareTo(dayKey(today)) <= 0)
        .toList();
    total = eligible.length;
    completed = eligible.where((t) => t.done).length;
    final days = eligible.map((t) => t.day).toSet();
    perfectDays = days
        .where(
          (day) => eligible.where((t) => t.day == day).every((t) => t.done),
        )
        .length;
    week = List.generate(7, (i) {
      final day = DateTime(today.year, today.month, today.day - 6 + i);
      final entries = eligible.where((t) => t.day == dayKey(day)).toList();
      return DayProgress(
        day,
        entries.length,
        entries.where((t) => t.done).length,
      );
    });
    // Today's unfinished plan does not erase a streak earned through yesterday.
    var cursor = dateOnly(today);
    bool qualifies(DateTime day) {
      final entries = eligible.where((t) => t.day == dayKey(day)).toList();
      return entries.isNotEmpty &&
          entries.where((t) => t.done).length * 2 >= entries.length;
    }

    if (!qualifies(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var consecutive = 0;
    while (qualifies(cursor)) {
      consecutive++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    streak = consecutive;
  }

  late final int total;
  late final int completed;
  late final int perfectDays;
  late final List<DayProgress> week;
  late final int streak;
  int get percent => total == 0 ? 0 : (completed / total * 100).round();
  List<bool> get achievements => [
    completed >= 1,
    completed >= 10,
    perfectDays > 0,
    completed >= 50,
  ];
  List<TaskAward> get awards => [
    TaskAward('Первый шаг', 'Выполни первую задачу', '1', completed >= 1),
    TaskAward('Десятка', '10 выполненных задач', '10', completed >= 10),
    TaskAward('Идеальный день', '100% за один день', '100', perfectDays > 0),
    TaskAward('Серия 3 дня', 'Три дня подряд от 50%', '3д', streak >= 3),
    TaskAward('Неделя силы', 'Серия 7 дней', '7д', streak >= 7),
    TaskAward('Полсотни', '50 выполненных задач', '50', completed >= 50),
  ];
}

class TaskAward {
  const TaskAward(this.title, this.description, this.glyph, this.unlocked);
  final String title;
  final String description;
  final String glyph;
  final bool unlocked;
}
