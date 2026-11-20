import 'package:daily_todo/domain/entities/task.dart';

// Same sample dates and tasks as the Figma export. Used only for comparison.
List<Task> figmaFixture() {
  const titles = [
    'Прочитать 20 страниц',
    'Сделать тренировку',
    'Записаться к врачу',
    'Закончить проект',
    'Купить продукты',
  ];
  const history = [
    (17, 4, 5),
    (16, 5, 5),
    (15, 3, 4),
    (14, 2, 4),
    (13, 3, 5),
    (12, 4, 4),
  ];
  return [
    for (final (i, title) in titles.indexed)
      Task(id: '18-$i', title: title, done: i >= 3, day: '2026-06-18'),
    for (final (date, done, total) in history)
      for (var i = 0; i < total; i++)
        Task(
          id: '$date-$i',
          title: titles[i],
          done: i < done,
          day: '2026-06-$date',
        ),
  ];
}
