import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/reminder_controller.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../widgets/reference_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.appearance,
    required this.reminder,
  });

  final ThemeController appearance;
  final ReminderController reminder;

  Future<void> change(
    BuildContext context,
    Future<void> Function() action,
    String description,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(
              'Не удалось сохранить $description. Попробуйте ещё раз.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([appearance, reminder]),
    builder: (context, _) {
      final c = AppPalette.of(context);
      final settings = reminder.settings;
      final available = reminder.supported && !reminder.busy;
      final time = TimeOfDay(hour: settings.hour, minute: settings.minute);
      return DesignSheet(
        title: 'Как вам удобно',
        children: [
          setting(
            c,
            icon: DesignSymbol.moon,
            label: 'Тёмная тема',
            value: c.dark,
            switchKey: const ValueKey('dark-switch'),
            onChanged: appearance.busy
                ? null
                : (value) => change(
                    context,
                    () => appearance.update(
                      value ? ThemeMode.dark : ThemeMode.light,
                    ),
                    'тему',
                  ),
          ),
          setting(
            c,
            icon: DesignSymbol.bell,
            label: 'Вечернее напоминание',
            value: settings.enabled,
            switchKey: const ValueKey('reminder-switch'),
            onChanged: available
                ? (value) => reminder.update(settings.copyWith(enabled: value))
                : null,
          ),
          if (settings.enabled)
            InkWell(
              onTap: available
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
                        await reminder.update(
                          reminder.settings.copyWith(
                            hour: picked.hour,
                            minute: picked.minute,
                          ),
                        );
                      }
                    }
                  : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 65),
                child: Row(
                  children: [
                    Expanded(child: Text('Время', style: designText(12))),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.cream,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: designText(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (reminder.error != null || !reminder.supported)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  reminder.error ?? 'Уведомления доступны на Android и iOS.',
                  style: designText(
                    12,
                    height: 1.8,
                    color: reminder.error == null
                        ? c.muted
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          SheetAction(
            icon: DesignSymbol.sun,
            label: 'Дизайн приложения',
            trailing: DesignIcon(
              DesignSymbol.chevron,
              size: 17,
              color: c.muted,
            ),
            onTap: () => showDesignSheet<void>(
              context,
              builder: (_) => ListenableBuilder(
                listenable: appearance,
                builder: (context, _) => DesignSheet(
                  title: 'Дизайн приложения',
                  children: [
                    for (final design in AppDesign.values)
                      ListTile(
                        key: ValueKey('design-${design.name}'),
                        title: Text(design.title),
                        subtitle: Text(design.description),
                        selected: appearance.design == design,
                        trailing: appearance.design == design
                            ? const DesignIcon(DesignSymbol.check, size: 19)
                            : null,
                        enabled: !appearance.busy,
                        onTap: () => change(
                          context,
                          () => appearance.updateDesign(design),
                          'дизайн',
                        ),
                      ),
                    const Divider(),
                    ListTile(
                      key: const ValueKey('theme-system'),
                      title: const Text('Следовать режиму системы'),
                      selected: appearance.mode == ThemeMode.system,
                      trailing: appearance.mode == ThemeMode.system
                          ? const DesignIcon(DesignSymbol.check, size: 19)
                          : null,
                      enabled: !appearance.busy,
                      onTap: () => change(
                        context,
                        () => appearance.update(ThemeMode.system),
                        'тему',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget setting(
    AppPalette c, {
    required DesignSymbol icon,
    required String label,
    required bool value,
    required Key switchKey,
    required ValueChanged<bool>? onChanged,
  }) => Semantics(
    toggled: value,
    label: label,
    enabled: onChanged != null,
    onTap: onChanged == null ? null : () => onChanged(!value),
    excludeSemantics: true,
    child: InkWell(
      key: switchKey,
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 73),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            DesignIcon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: designText(12))),
            const SizedBox(width: 10),
            SizedBox(
              width: 46,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 26,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: value ? c.accent : c.line,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
