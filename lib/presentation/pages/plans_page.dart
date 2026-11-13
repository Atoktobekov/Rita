import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/planner_controller.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key, required this.planner});
  final PlannerController planner;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: planner,
    builder: (context, _) {
      final days = planner.futureDays;
      return Scaffold(
        appBar: AppBar(title: const Text('Будущие планы')),
        body: days.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Будущих задач пока нет. Выберите дату на главном экране и добавьте план.',
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: days.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final tasks = planner.tasks
                      .where((task) => task.day == day)
                      .toList();
                  return ListTile(
                    title: Text(
                      DateFormat(
                        'd MMMM yyyy',
                        'ru',
                      ).format(DateTime.parse(day)),
                    ),
                    subtitle: Text(
                      'Задач: ${tasks.length}; осталось: ${tasks.where((task) => !task.done).length}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, DateTime.parse(day)),
                  );
                },
              ),
      );
    },
  );
}
