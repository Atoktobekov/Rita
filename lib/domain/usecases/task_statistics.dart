import '../../core/calendar.dart';
import '../entities/task.dart';

class DayProgress {
  const DayProgress(this.day, this.total, this.completed);

  final DateTime day;
  final int total;
  final int completed;

  double get ratio => total == 0 ? 0 : completed / total;
  bool get halfComplete => total > 0 && completed * 2 >= total;
  bool get perfect => total > 0 && completed == total;
}

class TaskStatistics {
  TaskStatistics(List<Task> tasks, DateTime today) {
    final eligible = tasks.where((t) => t.day.compareTo(dayKey(today)) <= 0);
    final byDay = <String, List<Task>>{};
    for (final task in eligible) {
      byDay.putIfAbsent(task.day, () => []).add(task);
    }
    final days = [
      for (final entry in byDay.entries)
        DayProgress(
          DateTime.parse(entry.key),
          entry.value.length,
          entry.value.where((t) => t.done).length,
        ),
    ]..sort((a, b) => a.day.compareTo(b.day));
    final progress = {for (final day in days) dayKey(day.day): day};
    DayProgress at(DateTime day) =>
        progress[dayKey(day)] ?? DayProgress(day, 0, 0);

    total = days.fold(0, (sum, day) => sum + day.total);
    completed = days.fold(0, (sum, day) => sum + day.completed);
    perfectDays = days.where((day) => day.perfect).length;
    halfCompleteDays = days.where((day) => day.halfComplete).length;
    week = List.generate(
      7,
      (i) => at(DateTime(today.year, today.month, today.day - 6 + i)),
    );

    // A still-unfinished today does not erase the current streak through yesterday.
    var cursor = dateOnly(today);
    if (!at(cursor).halfComplete) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var current = 0;
    while (at(cursor).halfComplete) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    streak = current;

    // Awards recognize a qualifying series anywhere in the retained history.
    var halfRun = 0;
    var perfectRun = 0;
    var bestHalf = 0;
    var bestPerfect = 0;
    DateTime? previous;
    for (final day in days) {
      if (previous == null || nextDay(previous) != day.day) {
        halfRun = 0;
        perfectRun = 0;
      }
      halfRun = day.halfComplete ? halfRun + 1 : 0;
      perfectRun = day.perfect ? perfectRun + 1 : 0;
      if (halfRun > bestHalf) bestHalf = halfRun;
      if (perfectRun > bestPerfect) bestPerfect = perfectRun;
      previous = day.day;
    }
    longestHalfStreak = bestHalf;
    longestPerfectStreak = bestPerfect;

    // Only finished calendar days count for inactivity. Never invent history
    // before the first recorded task. UTC ordinals avoid daylight-saving gaps.
    int ordinal(DateTime day) =>
        DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    var bestEmpty = 0;
    if (days.isNotEmpty) {
      final end = ordinal(today) - 1;
      var start = ordinal(days.first.day);
      for (final day in days.where((d) => d.completed > 0)) {
        final index = ordinal(day.day);
        if (index > end) break;
        if (index - start > bestEmpty) bestEmpty = index - start;
        start = index + 1;
      }
      if (end - start + 1 > bestEmpty) bestEmpty = end - start + 1;
    }
    longestInactiveStreak = bestEmpty;
    secretUnlocked = eligible.any((t) => t.done && _secretTitle(t.title));
  }

  late final int total;
  late final int completed;
  late final int perfectDays;
  late final int halfCompleteDays;
  late final List<DayProgress> week;
  late final int streak;
  late final int longestHalfStreak;
  late final int longestPerfectStreak;
  late final int longestInactiveStreak;
  late final bool secretUnlocked;

  int get percent => total == 0 ? 0 : (completed / total * 100).round();

  // Match whole Russian words with common inflections/prefixes, not arbitrary
  // substrings such as "командировка" or "подрочник".
  static final _words = RegExp(r'[а-яё]+');
  static final _secretWord = RegExp(
    r'^(?:(?:по|на|пере|от|за|вы|с)?дроч(?:ить|иться|ил[аи]?|или|ит|ат|у|ишь|им|ите|ишься|ится|атся|усь|а|ка|ки|ку|кой|ке|ек)'
    r'|мастурб(?:аци[а-я]*|ир[а-я]*)|онан(?:изм[а-я]*|ир[а-я]*))$',
  );
  static bool _secretTitle(String title) => _words
      .allMatches(title.toLowerCase().replaceAll('ё', 'е'))
      .any((word) => _secretWord.hasMatch(word.group(0)!));

  List<TaskAward> get awards => [
    TaskAward('Первоход', 'Первая выполненная задача', '1', completed >= 1),
    TaskAward('Червонец', '10 выполненных задач', '10', completed >= 10),
    TaskAward(
      'Ты у меня третий',
      'Три дня подряд от 50%',
      '3д',
      longestHalfStreak >= 3,
    ),
    TaskAward('Эйс', 'Первый день со 100%', '100', perfectDays >= 1),
    TaskAward(
      'Жигули',
      '7 дней с выполнением от 50%',
      '7д',
      halfCompleteDays >= 7,
    ),
    TaskAward('Пять по десять', '50 выполненных задач', '50', completed >= 50),
    TaskAward('Четвертак', '25 выполненных задач', '25', completed >= 25),
    TaskAward('Трудоголик', '100 выполненных задач', '100', completed >= 100),
    TaskAward('Бонаква', '250 выполненных задач', '250', completed >= 250),
    TaskAward(
      'Бешке бир',
      '5 дней подряд со 100%',
      '5д',
      longestPerfectStreak >= 5,
    ),
    TaskAward(
      'Эпштейн',
      '14 дней с выполнением от 50%',
      '14д',
      halfCompleteDays >= 14,
    ),
    TaskAward(
      'NNN',
      '30 завершённых дней подряд без выполненных задач',
      '30д',
      longestInactiveStreak >= 30,
    ),
    TaskAward(
      'Тайная вечеря',
      '13 дней подряд со 100%',
      '13д',
      longestPerfectStreak >= 13,
    ),
    if (secretUnlocked)
      const TaskAward(
        'Дрочер',
        'Создать и выполнить задачу о мастурбации',
        '✓',
        true,
      ),
  ];
}

class TaskAward {
  const TaskAward(this.title, this.description, this.glyph, this.unlocked);

  final String title;
  final String description;
  final String glyph;
  final bool unlocked;
}
