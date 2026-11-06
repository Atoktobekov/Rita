import 'package:flutter/material.dart';
import '../controllers/reminder_controller.dart';
import '../pages/reminder_page.dart';
import '../theme/palette.dart';
import 'design_icon.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.controller});
  final ReminderController controller;

  Future<void> selectTime(BuildContext context, String value) async {
    var time = TimeOfDay(
      hour: controller.settings.hour,
      minute: controller.settings.minute,
    );
    if (value == 'custom') {
      final chosen = await showTimePicker(
        context: context,
        initialTime: time,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (chosen == null) return;
      time = chosen;
    } else {
      final parts = value.split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    await controller.update(
      controller.settings.copyWith(hour: time.hour, minute: time.minute),
    );
  }

  Widget timePicker(BuildContext context, String time) =>
      PopupMenuButton<String>(
        tooltip: 'Время напоминания',
        enabled: !controller.busy,
        onSelected: (value) => selectTime(context, value),
        itemBuilder: (_) => [
          for (final option in ['21:00', '21:30', '22:00'])
            PopupMenuItem(value: option, child: Text(option)),
          const PopupMenuItem(value: 'custom', child: Text('Другое время…')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: card,
            border: Border.all(color: inkOpacity(.05)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const RotatedBox(
                quarterTurns: 1,
                child: DesignIcon(DesignSymbol.chevron, size: 12),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final settings = controller.settings;
      final time =
          '${settings.hour.toString().padLeft(2, '0')}:${settings.minute.toString().padLeft(2, '0')}';
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 320;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: sand.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Напоминание',
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ReminderPage(controller: controller),
                          ),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: card,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: DesignIcon(DesignSymbol.bell, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Вечернее напоминание',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            !controller.supported
                                ? 'На Android и iOS'
                                : settings.enabled
                                ? 'Заполнить план на завтра'
                                : 'Выключено',
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: inkOpacity(.55),
                            ),
                          ),
                          if (compact && settings.enabled) ...[
                            const SizedBox(height: 8),
                            timePicker(context, time),
                          ],
                        ],
                      ),
                    ),
                    if (settings.enabled && !compact) ...[
                      const SizedBox(width: 12),
                      timePicker(context, time),
                    ],
                    const SizedBox(width: 12),
                    Semantics(
                      label: 'Вечернее напоминание',
                      toggled: settings.enabled,
                      enabled: controller.supported && !controller.busy,
                      child: GestureDetector(
                        key: const ValueKey('reminder-switch'),
                        onTap: controller.supported && !controller.busy
                            ? () => controller.update(
                                settings.copyWith(enabled: !settings.enabled),
                              )
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 24,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: settings.enabled ? peach : inkOpacity(.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 180),
                            alignment: settings.enabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x1A000000),
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
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    controller.error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}
