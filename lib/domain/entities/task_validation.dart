import '../../core/calendar.dart';
import 'task.dart';

const taskCategories = ['Личное', 'Работа', 'Здоровье', 'Развитие'];

void validateTask(Task task) {
  if (task.id.isEmpty || task.id.length > 200) {
    throw const FormatException('Некорректный идентификатор задачи');
  }
  if (task.title.trim().isEmpty || task.title.trim().length > 200) {
    throw const FormatException(
      'Название задачи должно содержать от 1 до 200 символов',
    );
  }
  final date = DateTime.tryParse(task.day);
  if (date == null ||
      dayKey(date) != task.day ||
      date.year < 1900 ||
      date.year > 2200) {
    throw const FormatException(
      'Дата задачи должна быть между 1900 и 2200 годом',
    );
  }
  if (task.category.trim().isEmpty || task.category.length > 80) {
    throw const FormatException('Некорректная категория задачи');
  }
}

void validateTasks(List<Task> tasks) {
  final ids = <String>{};
  for (final task in tasks) {
    validateTask(task);
    if (!ids.add(task.id)) {
      throw const FormatException('В копии повторяются идентификаторы задач');
    }
  }
}
