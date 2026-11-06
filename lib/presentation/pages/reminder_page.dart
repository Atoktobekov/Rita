import 'package:flutter/material.dart';
import '../controllers/reminder_controller.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key, required this.controller});
  final ReminderController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Напоминание')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.settings;
        final time = TimeOfDay(hour: settings.hour, minute: settings.minute);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.notifications_none_rounded, size: 52),
            const SizedBox(height: 20),
            Text(
              'Пара минут для себя',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Вечером подведите итоги дня и составьте план на завтра. Рекомендуем время с 21:00 до 22:00.',
            ),
            const SizedBox(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Напоминать каждый день'),
              subtitle: Text(
                controller.supported
                    ? 'Разрешение потребуется при включении'
                    : 'Доступно на Android и iOS',
              ),
              value: settings.enabled,
              onChanged: controller.supported && !controller.busy
                  ? (enabled) =>
                        controller.update(settings.copyWith(enabled: enabled))
                  : null,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Время напоминания'),
              subtitle: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: controller.supported && !controller.busy,
              onTap: controller.supported && !controller.busy
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                        builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        await controller.update(
                          controller.settings.copyWith(
                            hour: picked.hour,
                            minute: picked.minute,
                          ),
                        );
                      }
                    }
                  : null,
            ),
            if (controller.busy) const LinearProgressIndicator(),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'По местному времени телефона. На Android напоминание может прийти немного позже из-за режима энергосбережения.',
            ),
          ],
        );
      },
    ),
  );
}
