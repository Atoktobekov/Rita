class Task {
  const Task({
    required this.id,
    required this.title,
    required this.day,
    this.category = 'Личное',
    this.done = false,
  });

  final String id;
  final String title;
  final String day;
  final String category;
  final bool done;

  Task copyWith({String? title, String? day, String? category, bool? done}) =>
      Task(
        id: id,
        title: title ?? this.title,
        day: day ?? this.day,
        category: category ?? this.category,
        done: done ?? this.done,
      );
}
