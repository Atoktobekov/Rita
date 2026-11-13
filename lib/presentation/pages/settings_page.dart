import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/reminder_controller.dart';
import 'reminder_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.appearance,
    required this.reminder,
  });

  final ThemeController appearance;
  final ReminderController reminder;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Настройки')),
    body: ListenableBuilder(
      listenable: appearance,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Тема оформления',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final (mode, label, icon) in [
            (ThemeMode.light, 'Светлая', Icons.light_mode_outlined),
            (ThemeMode.dark, 'Тёмная', Icons.dark_mode_outlined),
            (ThemeMode.system, 'Системная', Icons.brightness_auto_outlined),
          ])
            ListTile(
              key: ValueKey('theme-${mode.name}'),
              leading: Icon(icon),
              title: Text(label),
              selected: appearance.mode == mode,
              trailing: appearance.mode == mode
                  ? const Icon(Icons.check)
                  : null,
              enabled: !appearance.busy,
              onTap: () async {
                try {
                  await appearance.update(mode);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Не удалось сохранить тему. Попробуйте ещё раз.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Вечернее напоминание'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ReminderPage(controller: reminder),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
