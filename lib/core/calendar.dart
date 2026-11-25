DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime nextDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

int calendarDayNumber(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
