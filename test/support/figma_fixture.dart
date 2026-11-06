import 'package:daily_todo/domain/entities/task.dart';

// The export's sample content is used only for visual comparisons, never seeded
// into the user's local database.
List<Task> figmaFixture() {
  final days = <String, List<(String, bool)>>{
    '2025-01-15': [
      ('Зарядка 15 минут', true),
      ('Сделать экран статистики', false),
      ('Прочитать 20 страниц', false),
      ('Выпить 2 л воды', true),
    ],
    '2025-01-14': [
      ('Зарядка 15 минут', true),
      ('Прочитать 20 страниц', true),
      ('Выучить урок по Dart', true),
      ('Позвонить родителям', false),
    ],
    '2025-01-13': [
      ('Пробежка', true),
      ('Разобрать почту', true),
      ('Закончить экран профиля', true),
    ],
    '2025-01-12': [
      ('Медитация', true),
      ('Приготовить ужин', false),
      ('Виджет списка задач', true),
      ('Растяжка', false),
      ('Выпить 2 л воды', true),
    ],
    '2025-01-11': [
      ('Прогулка', false),
      ('Тема про состояние во Flutter', true),
    ],
    '2025-01-10': [
      ('Hive: хранение данных', true),
      ('Зарядка', true),
      ('Чтение', true),
      ('Уборка', true),
    ],
  };
  return [
    for (final entry in days.entries)
      for (final (i, item) in entry.value.indexed)
        Task(
          id: '${entry.key}-$i',
          title: item.$1,
          done: item.$2,
          day: entry.key,
        ),
  ];
}
