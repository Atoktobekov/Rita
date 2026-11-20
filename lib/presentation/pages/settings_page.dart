import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/reminder_controller.dart';
import 'reminder_page.dart';
import '../theme/palette.dart';

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
          Text(
            'Дизайн приложения',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final design in AppDesign.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Builder(
                builder: (context) {
                  final preview = AppPalette(
                    Theme.of(context).brightness == Brightness.dark,
                    design: design,
                  );
                  return Semantics(
                    selected: appearance.design == design,
                    child: Material(
                      color: AppPalette.of(context).card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(preview.radius),
                        side: BorderSide(
                          color: appearance.design == design
                              ? AppPalette.of(context).strong
                              : AppPalette.of(context).line,
                          width: appearance.design == design ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        key: ValueKey('design-${design.name}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 56,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: preview.paper,
                            border: Border.all(color: preview.line),
                            borderRadius: BorderRadius.circular(
                              preview.radius / 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(height: 6, color: preview.accent),
                              const SizedBox(height: 5),
                              Container(height: 7, decoration: preview.panel()),
                              const SizedBox(height: 4),
                              Container(
                                height: 7,
                                decoration: preview.panel(color: preview.cream),
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          design.title,
                          style: preview.heading.copyWith(
                            fontSize: 20,
                            color: AppPalette.of(context).ink,
                          ),
                        ),
                        subtitle: Text(design.description),
                        trailing: appearance.design == design
                            ? const Icon(Icons.check_circle)
                            : null,
                        enabled: !appearance.busy,
                        onTap: () async {
                          try {
                            await appearance.updateDesign(design);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Не удалось сохранить дизайн. Попробуйте ещё раз.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
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
