import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/repositories/hive_reminder_repository.dart';
import 'data/repositories/hive_task_repository.dart';
import 'data/services/local_reminder_scheduler.dart';
import 'domain/usecases/manage_reminder.dart';
import 'domain/usecases/manage_tasks.dart';
import 'presentation/controllers/planner_controller.dart';
import 'presentation/controllers/reminder_controller.dart';

import 'presentation/controllers/theme_controller.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    final tasks = await Hive.openBox<dynamic>('tasks_v2');
    final legacyTasks = tasks.containsKey('state')
        ? null
        : await Hive.openBox<dynamic>('tasks_v1');
    final settings = await Hive.openBox<dynamic>('settings_v1');
    final planner = PlannerController(
      ManageTasks(HiveTaskRepository(tasks, legacyBox: legacyTasks)),
    );
    final reminder = ReminderController(
      ManageReminder(
        HiveReminderRepository(settings),
        LocalReminderScheduler(),
      ),
    );
    await planner.initialize();
    await reminder.initialize();
    final savedTheme = settings.get('theme_mode');
    final appearance = ThemeController(
      mode: ThemeMode.values.firstWhere(
        (mode) => mode.name == savedTheme,
        orElse: () => ThemeMode.system,
      ),
      save: (mode) => settings.put('theme_mode', mode.name),
    );
    runApp(
      DailyApp(planner: planner, reminder: reminder, appearance: appearance),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text('Не удалось открыть ваши задачи'),
                  const SizedBox(height: 8),
                  const Text(
                    'Проверьте доступное место и повторите попытку. Данные не удалены.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: main, child: const Text('Повторить')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
